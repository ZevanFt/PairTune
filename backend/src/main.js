const path = require('path');
const fs = require('fs');
const crypto = require('crypto');
const express = require('express');
const cors = require('cors');
const Database = require('better-sqlite3');
const { createSmsProvider } = require('./sms_provider');
const { createEmailProvider } = require('./email_provider');
const { runMigrations } = require('./db_migrate');
const { APP_CONFIG } = require('./config/app_config');

function loadEnvFile() {
  const envPath = path.join(__dirname, '..', '.env.local');
  if (!fs.existsSync(envPath)) return;
  const raw = fs.readFileSync(envPath, 'utf8');
  raw.split('\n').forEach((line) => {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) return;
    const idx = trimmed.indexOf('=');
    if (idx <= 0) return;
    const key = trimmed.slice(0, idx).trim();
    const value = trimmed.slice(idx + 1).trim();
    if (!key || process.env[key] !== undefined) return;
    process.env[key] = value;
  });
}

loadEnvFile();

const app = express();
const port = process.env.PORT || 8110;
const dbPath = process.env.DB_PATH || path.join(__dirname, '..', 'data', 'priority_first.db');
console.log(JSON.stringify({ type: 'db_path', db_path: dbPath, ts: new Date().toISOString() }));
const db = new Database(dbPath);
const smsProvider = createSmsProvider();
const emailProvider = createEmailProvider();

db.pragma('journal_mode = WAL');

const OWNER_ME = 'me';
const OWNER_PARTNER = 'partner';

function validateOwner(owner) {
  return owner === OWNER_ME || owner === OWNER_PARTNER;
}

function toBoolInt(value, fallback = 0) {
  if (value === undefined || value === null) return fallback ? 1 : 0;
  if (typeof value === 'boolean') return value ? 1 : 0;
  if (value === 1 || value === '1' || value === 'true') return 1;
  if (value === 0 || value === '0' || value === 'false') return 0;
  return fallback ? 1 : 0;
}

function hashPassword(raw) {
  return crypto.createHash('sha256').update(String(raw || '')).digest('hex');
}

function createSessionToken() {
  return crypto.randomBytes(24).toString('hex');
}

function isPhone(value) {
  return /^1\d{10}$/.test(String(value || '').trim());
}

function normalizeEmail(value) {
  return String(value || '').trim().toLowerCase();
}

function isEmail(value) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(normalizeEmail(value));
}

function normalizeAccount(value) {
  return String(value || '').trim().toLowerCase();
}

function isAccount(value) {
  return /^[a-z0-9_]{4,20}$/.test(normalizeAccount(value));
}

function normalizeInviteCode(value) {
  return String(value || '').trim().toUpperCase();
}

function isStrongPassword(value) {
  return String(value || '').trim().length >= 6;
}

function isValidCode(value) {
  return /^\d{6}$/.test(String(value || '').trim());
}

function normalizeAuthPurpose(value) {
  const raw = String(value || 'login').trim();
  return raw === 'register' ? 'register' : 'login';
}

function createPhoneCode() {
  return String(crypto.randomInt(0, 1000000)).padStart(6, '0');
}

function createInviteCode(length = 8) {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let result = '';
  for (let i = 0; i < length; i += 1) {
    result += chars[crypto.randomInt(0, chars.length)];
  }
  return result;
}

function shouldExposeDebugCode() {
  if (String(process.env.AUTH_DEBUG_CODE || '').trim() === '1') return true;
  return String(process.env.NODE_ENV || '').trim() !== 'production';
}

function nowIso() {
  return new Date().toISOString();
}

function logEvent(type, detail = {}) {
  console.log(JSON.stringify({ type, ...detail, ts: nowIso() }));
}

runMigrations({
  db,
  migrationsDir: path.join(__dirname, '..', 'migrations'),
  logger: (event, detail) => logEvent(event, detail),
});

function isInviteUsable(invite) {
  if (!invite) return { ok: false, reason: '邀请码不存在' };
  if (invite.status !== 'active') return { ok: false, reason: '邀请码不可用' };
  if (invite.expires_at && new Date(invite.expires_at).getTime() < Date.now()) {
    return { ok: false, reason: '邀请码已过期' };
  }
  if (Number(invite.used_count) >= Number(invite.usage_limit)) {
    return { ok: false, reason: '邀请码已用尽' };
  }
  return { ok: true, reason: null };
}

function parseRangeDays(value) {
  const raw = String(value || '').trim().toLowerCase();
  if (raw === '30d') return 30;
  if (raw === '90d') return 90;
  return 7;
}

function startOfDay(date) {
  const d = new Date(date);
  d.setHours(0, 0, 0, 0);
  return d;
}

function formatDateKey(date) {
  return date.toISOString().slice(0, 10);
}

function buildDateSeries(days) {
  const today = startOfDay(new Date());
  const series = [];
  for (let i = days - 1; i >= 0; i -= 1) {
    const d = new Date(today);
    d.setDate(today.getDate() - i);
    series.push(formatDateKey(d));
  }
  return series;
}

function rangeStartIso(days) {
  const today = startOfDay(new Date());
  const start = new Date(today);
  start.setDate(today.getDate() - (days - 1));
  return start.toISOString();
}

function safeNumber(value) {
  const num = Number(value);
  return Number.isFinite(num) ? num : 0;
}

function getClientKey(req) {
  const ip = String(req.headers['x-forwarded-for'] || req.ip || 'unknown').split(',')[0].trim();
  const deviceId = String(req.headers['x-device-id'] || '').trim().slice(0, 64);
  const ua = String(req.headers['user-agent'] || '').trim().slice(0, 120);
  return `${ip}|${deviceId || 'no-device'}|${ua || 'no-ua'}`;
}

function countRecentAuthEvents({ action, phone = null, email = null, clientKey = null, windowSeconds = 600 }) {
  const since = new Date(Date.now() - windowSeconds * 1000).toISOString();
  if (email && clientKey) {
    return db.prepare(
      `SELECT COUNT(1) AS count
       FROM auth_security_events
       WHERE action = ? AND email = ? AND client_key = ? AND created_at >= ?`,
    ).get(action, email, clientKey, since).count;
  }
  if (email) {
    return db.prepare(
      `SELECT COUNT(1) AS count
       FROM auth_security_events
       WHERE action = ? AND email = ? AND created_at >= ?`,
    ).get(action, email, since).count;
  }
  if (phone && clientKey) {
    return db.prepare(
      `SELECT COUNT(1) AS count
       FROM auth_security_events
       WHERE action = ? AND phone = ? AND client_key = ? AND created_at >= ?`,
    ).get(action, phone, clientKey, since).count;
  }
  if (phone) {
    return db.prepare(
      `SELECT COUNT(1) AS count
       FROM auth_security_events
       WHERE action = ? AND phone = ? AND created_at >= ?`,
    ).get(action, phone, since).count;
  }
  if (clientKey) {
    return db.prepare(
      `SELECT COUNT(1) AS count
       FROM auth_security_events
       WHERE action = ? AND client_key = ? AND created_at >= ?`,
    ).get(action, clientKey, since).count;
  }
  return db.prepare(
    `SELECT COUNT(1) AS count
     FROM auth_security_events
     WHERE action = ? AND created_at >= ?`,
  ).get(action, since).count;
}

function writeAuthEvent({ action, phone = null, email = null, clientKey = null, success = 0, detail = null }) {
  db.prepare(
    `INSERT INTO auth_security_events(action, phone, email, client_key, success, detail, created_at)
     VALUES (?, ?, ?, ?, ?, ?, ?)`,
  ).run(action, phone, email, clientKey, success ? 1 : 0, detail, nowIso());
}

function getUserRoles(userId) {
  return db.prepare(
    `SELECT r.id, r.name, r.description
     FROM auth_roles r
     JOIN auth_user_roles ur ON ur.role_id = r.id
     WHERE ur.user_id = ?`,
  ).all(userId);
}

function getUserPermissions(userId) {
  return db.prepare(
    `SELECT DISTINCT p.code
     FROM auth_permissions p
     JOIN auth_role_permissions rp ON rp.permission_id = p.id
     JOIN auth_user_roles ur ON ur.role_id = rp.role_id
     WHERE ur.user_id = ?`,
  ).all(userId).map((row) => row.code);
}

function getAuthToken(req) {
  const header = String(req.headers.authorization || '');
  if (header.toLowerCase().startsWith('bearer ')) {
    return header.slice(7).trim();
  }
  if (req.body?.token) return String(req.body.token).trim();
  if (req.query?.token) return String(req.query.token).trim();
  return '';
}

function requireSession(req, res) {
  const token = getAuthToken(req);
  if (!token) {
    res.status(401).json({ code: 401, message: '未登录', result: null });
    return null;
  }
  const session = db.prepare(
    `SELECT s.token, s.provider, s.owner_hint, s.expires_at, s.user_id,
            u.display_name, u.phone, u.email, u.account, u.role, u.wechat_openid, u.status
     FROM auth_sessions s
     JOIN auth_users u ON u.id = s.user_id
     WHERE s.token = ?`,
  ).get(token);
  if (!session) {
    res.status(401).json({ code: 401, message: '会话不存在', result: null });
    return null;
  }
  if (new Date(session.expires_at).getTime() < Date.now()) {
    db.prepare('DELETE FROM auth_sessions WHERE token = ?').run(token);
    res.status(401).json({ code: 401, message: '会话已过期', result: null });
    return null;
  }
  db.prepare('UPDATE auth_sessions SET last_seen_at = ? WHERE token = ?').run(
    new Date().toISOString(),
    token,
  );
  return session;
}

function requireAdmin(req, res) {
  const session = requireSession(req, res);
  if (!session) return null;
  if (session.role !== 'admin') {
    res.status(403).json({ code: 403, message: '无管理员权限', result: null });
    return null;
  }
  return session;
}

function requirePermission(req, res, permissionCode) {
  const session = requireSession(req, res);
  if (!session) return null;
  if (session.role === 'admin') return session;
  const permissions = getUserPermissions(session.user_id);
  if (permissions.includes('admin.full') || permissions.includes(permissionCode)) {
    return session;
  }
  res.status(403).json({ code: 403, message: '无权限访问', result: null });
  return null;
}

function ensureSchema() {
  db.exec(`
CREATE TABLE IF NOT EXISTS tasks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  owner TEXT NOT NULL DEFAULT 'me',
  title TEXT NOT NULL,
  note TEXT,
  quadrant INTEGER NOT NULL,
  points INTEGER NOT NULL DEFAULT 0,
  due_date TEXT,
  due_mode TEXT NOT NULL DEFAULT 'day',
  repeat_type TEXT NOT NULL DEFAULT 'none',
  repeat_interval INTEGER NOT NULL DEFAULT 1,
  repeat_weekdays TEXT,
  repeat_until TEXT,
  is_done INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS point_wallets (
  owner TEXT PRIMARY KEY,
  points INTEGER NOT NULL DEFAULT 0,
  updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS point_ledger (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  owner TEXT NOT NULL,
  amount INTEGER NOT NULL,
  reason TEXT NOT NULL,
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS products (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  publisher TEXT NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  points_cost INTEGER NOT NULL,
  stock INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS owned_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  owner TEXT NOT NULL,
  product_id INTEGER NOT NULL,
  product_name TEXT NOT NULL,
  points_spent INTEGER NOT NULL,
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS profiles (
  owner TEXT PRIMARY KEY,
  display_name TEXT NOT NULL,
  bio TEXT,
  avatar TEXT,
  relationship_label TEXT NOT NULL DEFAULT '搭档',
  updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS app_settings (
  owner TEXT PRIMARY KEY,
  duo_enabled INTEGER NOT NULL DEFAULT 0,
  notifications_enabled INTEGER NOT NULL DEFAULT 1,
  quiet_hours_start TEXT,
  quiet_hours_end TEXT,
  relation_checkin INTEGER NOT NULL DEFAULT 1,
  relation_reminder INTEGER NOT NULL DEFAULT 1,
  relation_coop_hint INTEGER NOT NULL DEFAULT 1,
  security_login_alert INTEGER NOT NULL DEFAULT 1,
  security_risk_guard INTEGER NOT NULL DEFAULT 1,
  updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS notifications (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  owner TEXT NOT NULL,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  is_read INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS feedback_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  owner TEXT NOT NULL,
  category TEXT NOT NULL,
  title TEXT NOT NULL,
  detail TEXT NOT NULL,
  contact TEXT,
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS auth_users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  account TEXT,
  phone TEXT UNIQUE,
  email TEXT,
  wechat_openid TEXT UNIQUE,
  password_hash TEXT,
  display_name TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'user',
  status TEXT NOT NULL DEFAULT 'active',
  failed_login_count INTEGER NOT NULL DEFAULT 0,
  locked_until TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS auth_sessions (
  token TEXT PRIMARY KEY,
  user_id INTEGER NOT NULL,
  provider TEXT NOT NULL,
  owner_hint TEXT NOT NULL DEFAULT 'me',
  expires_at TEXT NOT NULL,
  created_at TEXT NOT NULL,
  last_seen_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS auth_phone_codes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  phone TEXT NOT NULL,
  code TEXT NOT NULL,
  purpose TEXT NOT NULL,
  expires_at TEXT NOT NULL,
  used_at TEXT,
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS auth_email_codes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email TEXT NOT NULL,
  code TEXT NOT NULL,
  purpose TEXT NOT NULL,
  expires_at TEXT NOT NULL,
  used_at TEXT,
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS auth_invite_codes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'active',
  usage_limit INTEGER NOT NULL DEFAULT 1,
  used_count INTEGER NOT NULL DEFAULT 0,
  created_by INTEGER,
  used_by INTEGER,
  created_at TEXT NOT NULL,
  used_at TEXT,
  expires_at TEXT
);

CREATE TABLE IF NOT EXISTS auth_security_events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  action TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  client_key TEXT,
  success INTEGER NOT NULL DEFAULT 0,
  detail TEXT,
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS auth_roles (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  description TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS auth_permissions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS auth_role_permissions (
  role_id INTEGER NOT NULL,
  permission_id INTEGER NOT NULL,
  created_at TEXT NOT NULL,
  PRIMARY KEY (role_id, permission_id)
);

CREATE TABLE IF NOT EXISTS auth_user_roles (
  user_id INTEGER NOT NULL,
  role_id INTEGER NOT NULL,
  created_at TEXT NOT NULL,
  PRIMARY KEY (user_id, role_id)
);
`);

  const taskColumns = db.prepare("PRAGMA table_info('tasks')").all();
  const hasOwner = taskColumns.some((col) => col.name === 'owner');
  const hasRepeatType = taskColumns.some((col) => col.name === 'repeat_type');
  const hasRepeatInterval = taskColumns.some((col) => col.name === 'repeat_interval');
  const hasDueMode = taskColumns.some((col) => col.name === 'due_mode');
  const hasRepeatWeekdays = taskColumns.some((col) => col.name === 'repeat_weekdays');
  const hasRepeatUntil = taskColumns.some((col) => col.name === 'repeat_until');
  if (!hasOwner) {
    db.exec("ALTER TABLE tasks ADD COLUMN owner TEXT NOT NULL DEFAULT 'me';");
  }
  if (!hasRepeatType) {
    db.exec("ALTER TABLE tasks ADD COLUMN repeat_type TEXT NOT NULL DEFAULT 'none';");
  }
  if (!hasRepeatInterval) {
    db.exec("ALTER TABLE tasks ADD COLUMN repeat_interval INTEGER NOT NULL DEFAULT 1;");
  }
  if (!hasDueMode) {
    db.exec("ALTER TABLE tasks ADD COLUMN due_mode TEXT NOT NULL DEFAULT 'day';");
  }
  if (!hasRepeatWeekdays) {
    db.exec('ALTER TABLE tasks ADD COLUMN repeat_weekdays TEXT;');
  }
  if (!hasRepeatUntil) {
    db.exec("ALTER TABLE tasks ADD COLUMN repeat_until TEXT;");
  }

  const authUserColumns = db.prepare("PRAGMA table_info('auth_users')").all();
  const hasAccount = authUserColumns.some((col) => col.name === 'account');
  const hasEmail = authUserColumns.some((col) => col.name === 'email');
  const hasRole = authUserColumns.some((col) => col.name === 'role');
  const hasFailedLoginCount = authUserColumns.some((col) => col.name === 'failed_login_count');
  const hasLockedUntil = authUserColumns.some((col) => col.name === 'locked_until');
  if (!hasAccount) {
    db.exec('ALTER TABLE auth_users ADD COLUMN account TEXT;');
  }
  if (!hasEmail) {
    db.exec('ALTER TABLE auth_users ADD COLUMN email TEXT;');
  }
  if (!hasRole) {
    db.exec("ALTER TABLE auth_users ADD COLUMN role TEXT NOT NULL DEFAULT 'user';");
  }
  if (!hasFailedLoginCount) {
    db.exec('ALTER TABLE auth_users ADD COLUMN failed_login_count INTEGER NOT NULL DEFAULT 0;');
  }
  if (!hasLockedUntil) {
    db.exec('ALTER TABLE auth_users ADD COLUMN locked_until TEXT;');
  }
  db.exec(
    'CREATE UNIQUE INDEX IF NOT EXISTS idx_auth_users_account_unique ON auth_users(account) WHERE account IS NOT NULL;',
  );
  db.exec('CREATE UNIQUE INDEX IF NOT EXISTS idx_auth_users_email_unique ON auth_users(email) WHERE email IS NOT NULL;');

  const authEventColumns = db.prepare("PRAGMA table_info('auth_security_events')").all();
  const hasEventEmail = authEventColumns.some((col) => col.name === 'email');
  if (!hasEventEmail) {
    db.exec('ALTER TABLE auth_security_events ADD COLUMN email TEXT;');
  }

  const settingsColumns = db.prepare("PRAGMA table_info('app_settings')").all();
  const hasRelationCheckin = settingsColumns.some((col) => col.name === 'relation_checkin');
  const hasRelationReminder = settingsColumns.some((col) => col.name === 'relation_reminder');
  const hasRelationCoopHint = settingsColumns.some((col) => col.name === 'relation_coop_hint');
  const hasSecurityLoginAlert = settingsColumns.some((col) => col.name === 'security_login_alert');
  const hasSecurityRiskGuard = settingsColumns.some((col) => col.name === 'security_risk_guard');
  if (!hasRelationCheckin) {
    db.exec('ALTER TABLE app_settings ADD COLUMN relation_checkin INTEGER NOT NULL DEFAULT 1;');
  }
  if (!hasRelationReminder) {
    db.exec('ALTER TABLE app_settings ADD COLUMN relation_reminder INTEGER NOT NULL DEFAULT 1;');
  }
  if (!hasRelationCoopHint) {
    db.exec('ALTER TABLE app_settings ADD COLUMN relation_coop_hint INTEGER NOT NULL DEFAULT 1;');
  }
  if (!hasSecurityLoginAlert) {
    db.exec('ALTER TABLE app_settings ADD COLUMN security_login_alert INTEGER NOT NULL DEFAULT 1;');
  }
  if (!hasSecurityRiskGuard) {
    db.exec('ALTER TABLE app_settings ADD COLUMN security_risk_guard INTEGER NOT NULL DEFAULT 1;');
  }

  db.exec('CREATE UNIQUE INDEX IF NOT EXISTS idx_auth_invite_codes_code_unique ON auth_invite_codes(code);');
  db.exec('CREATE UNIQUE INDEX IF NOT EXISTS idx_auth_roles_name_unique ON auth_roles(name);');
  db.exec('CREATE UNIQUE INDEX IF NOT EXISTS idx_auth_permissions_code_unique ON auth_permissions(code);');
  db.exec('CREATE INDEX IF NOT EXISTS idx_feedback_items_owner ON feedback_items(owner);');

  const now = new Date().toISOString();
  db.prepare(
    'INSERT OR IGNORE INTO point_wallets(owner, points, updated_at) VALUES (?, ?, ?)',
  ).run(OWNER_ME, 100, now);
  db.prepare(
    'INSERT OR IGNORE INTO point_wallets(owner, points, updated_at) VALUES (?, ?, ?)',
  ).run(OWNER_PARTNER, 100, now);
  db.prepare(
    'INSERT OR IGNORE INTO profiles(owner, display_name, bio, avatar, relationship_label, updated_at) VALUES (?, ?, ?, ?, ?, ?)',
  ).run(OWNER_ME, '我', null, null, '搭档', now);
  db.prepare(
    'INSERT OR IGNORE INTO profiles(owner, display_name, bio, avatar, relationship_label, updated_at) VALUES (?, ?, ?, ?, ?, ?)',
  ).run(OWNER_PARTNER, '搭档', null, null, '搭档', now);
  db.prepare(
    `INSERT OR IGNORE INTO app_settings(
       owner, duo_enabled, notifications_enabled, quiet_hours_start, quiet_hours_end,
       relation_checkin, relation_reminder, relation_coop_hint, security_login_alert, security_risk_guard, updated_at
     ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
  ).run(OWNER_ME, 0, 1, '22:00', '08:00', 1, 1, 1, 1, 1, now);
  db.prepare(
    `INSERT OR IGNORE INTO app_settings(
       owner, duo_enabled, notifications_enabled, quiet_hours_start, quiet_hours_end,
       relation_checkin, relation_reminder, relation_coop_hint, security_login_alert, security_risk_guard, updated_at
     ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
  ).run(OWNER_PARTNER, 0, 1, '22:00', '08:00', 1, 1, 1, 1, 1, now);

  const sampleCount = db.prepare('SELECT COUNT(1) AS count FROM notifications').get().count;
  if (sampleCount === 0) {
    const insertNotice = db.prepare(
      'INSERT INTO notifications(owner, type, title, body, is_read, created_at) VALUES (?, ?, ?, ?, ?, ?)',
    );
    insertNotice.run(OWNER_ME, 'task', '任务提醒', '今晚 21:00 前完成整理计划', 0, now);
    insertNotice.run(OWNER_ME, 'system', '欢迎使用合拍', '单人可用，双人更好用。', 0, now);
    insertNotice.run(OWNER_PARTNER, 'system', '欢迎使用合拍', '你们的协作记录将从今天开始。', 0, now);
  }
}

ensureSchema();

function ensureRbacDefaults() {
  const now = nowIso();
  const permissions = [
    { code: 'admin.full', name: '全量管理权限' },
    { code: 'admin.dashboard.view', name: '查看仪表盘' },
    { code: 'admin.stats.view', name: '查看运营数据' },
    { code: 'admin.invites.view', name: '查看邀请码' },
    { code: 'admin.invites.manage', name: '管理邀请码' },
    { code: 'admin.users.view', name: '查看用户' },
    { code: 'admin.roles.view', name: '查看角色权限' },
    { code: 'admin.roles.manage', name: '管理角色权限' },
    { code: 'admin.security.view', name: '查看安全审计' },
    { code: 'admin.sessions.view', name: '查看会话' },
    { code: 'admin.tasks.view', name: '查看任务运营' },
    { code: 'admin.points.view', name: '查看积分运营' },
    { code: 'admin.store.view', name: '查看商城运营' },
    { code: 'admin.settings.view', name: '查看系统设置' },
  ];

  const insertPerm = db.prepare(
    `INSERT OR IGNORE INTO auth_permissions(code, name, description, created_at, updated_at)
     VALUES (?, ?, NULL, ?, ?)`,
  );
  permissions.forEach((perm) => insertPerm.run(perm.code, perm.name, now, now));

  const insertRole = db.prepare(
    `INSERT OR IGNORE INTO auth_roles(name, description, created_at, updated_at)
     VALUES (?, ?, ?, ?)`,
  );
  insertRole.run('admin', '系统管理员', now, now);
  insertRole.run('viewer', '只读观察者', now, now);

  const adminRole = db.prepare('SELECT id FROM auth_roles WHERE name = ?').get('admin');
  const viewerRole = db.prepare('SELECT id FROM auth_roles WHERE name = ?').get('viewer');
  const permRows = db.prepare('SELECT id, code FROM auth_permissions').all();

  if (adminRole) {
    const insertRolePerm = db.prepare(
      `INSERT OR IGNORE INTO auth_role_permissions(role_id, permission_id, created_at)
       VALUES (?, ?, ?)`,
    );
    permRows.forEach((perm) => insertRolePerm.run(adminRole.id, perm.id, now));
  }

  if (viewerRole) {
    const viewerPerms = permRows.filter((perm) =>
      [
        'admin.dashboard.view',
        'admin.stats.view',
        'admin.invites.view',
        'admin.users.view',
        'admin.roles.view',
        'admin.security.view',
        'admin.sessions.view',
        'admin.tasks.view',
        'admin.points.view',
        'admin.store.view',
        'admin.settings.view',
      ].includes(perm.code),
    );
    const insertRolePerm = db.prepare(
      `INSERT OR IGNORE INTO auth_role_permissions(role_id, permission_id, created_at)
       VALUES (?, ?, ?)`,
    );
    viewerPerms.forEach((perm) => insertRolePerm.run(viewerRole.id, perm.id, now));
  }
}

ensureRbacDefaults();

function ensureAdminAccount() {
  const adminAccount = normalizeAccount(process.env.ADMIN_ACCOUNT || '');
  const adminPassword = String(process.env.ADMIN_PASSWORD || '');
  if (!adminAccount || !isAccount(adminAccount) || !isStrongPassword(adminPassword)) {
    logEvent('auth_admin_missing', {
      account: adminAccount || null,
      reason: 'invalid-admin-env',
    });
    return;
  }
  const displayName = String(process.env.ADMIN_DISPLAY_NAME || '管理员').trim() || '管理员';
  const now = nowIso();
  const existing = db.prepare('SELECT * FROM auth_users WHERE account = ?').get(adminAccount);
  const passwordHash = hashPassword(adminPassword);
  if (!existing) {
    db.prepare(
      `INSERT INTO auth_users(account, phone, email, wechat_openid, password_hash, display_name, role, status, created_at, updated_at)
       VALUES (?, NULL, NULL, NULL, ?, ?, 'admin', 'active', ?, ?)`,
    ).run(adminAccount, passwordHash, displayName, now, now);
    const adminRole = db.prepare('SELECT id FROM auth_roles WHERE name = ?').get('admin');
    if (adminRole) {
      const newUser = db.prepare('SELECT id FROM auth_users WHERE account = ?').get(adminAccount);
      if (newUser) {
        db.prepare(
          'INSERT OR IGNORE INTO auth_user_roles(user_id, role_id, created_at) VALUES (?, ?, ?)',
        ).run(newUser.id, adminRole.id, now);
      }
    }
    logEvent('auth_admin_created', { account: adminAccount });
    return;
  }
  db.prepare(
    'UPDATE auth_users SET password_hash = ?, role = ?, display_name = ?, status = ?, updated_at = ? WHERE id = ?',
  ).run(passwordHash, 'admin', displayName, 'active', now, existing.id);
  const adminRole = db.prepare('SELECT id FROM auth_roles WHERE name = ?').get('admin');
  if (adminRole) {
    db.prepare(
      'INSERT OR IGNORE INTO auth_user_roles(user_id, role_id, created_at) VALUES (?, ?, ?)',
    ).run(existing.id, adminRole.id, now);
  }
  logEvent('auth_admin_updated', { account: adminAccount, id: existing.id });
}

ensureAdminAccount();

function normalizeRepeatType(value) {
  const raw = String(value || 'none').trim();
  if (
    raw === 'daily' ||
    raw === 'weekly' ||
    raw === 'weekly_custom' ||
    raw === 'monthly' ||
    raw === 'yearly' ||
    raw === 'none'
  ) {
    return raw;
  }
  return 'none';
}

function normalizeDueMode(value) {
  const raw = String(value || 'day').trim();
  return raw === 'time' ? 'time' : 'day';
}

function normalizeDueDate(value, dueMode) {
  if (!value) return null;
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return null;
  if (normalizeDueMode(dueMode) === 'day') {
    date.setHours(23, 59, 59, 999);
  }
  return date.toISOString();
}

function normalizeRepeatWeekdays(value) {
  if (!value) return null;
  if (Array.isArray(value)) {
    const days = value
      .map((day) => Number(day))
      .filter((day) => Number.isInteger(day) && day >= 1 && day <= 7);
    if (days.length === 0) return null;
    return [...new Set(days)].sort((a, b) => a - b).join(',');
  }
  const days = String(value)
    .split(',')
    .map((s) => Number(s.trim()))
    .filter((day) => Number.isInteger(day) && day >= 1 && day <= 7);
  if (days.length === 0) return null;
  return [...new Set(days)].sort((a, b) => a - b).join(',');
}

function addRepeatDate(baseDate, repeatType, repeatInterval) {
  if (!(baseDate instanceof Date) || Number.isNaN(baseDate.getTime())) {
    return null;
  }
  const next = new Date(baseDate.getTime());
  if (repeatType === 'daily') {
    next.setDate(next.getDate() + repeatInterval);
    return next;
  }
  if (repeatType === 'weekly') {
    next.setDate(next.getDate() + 7 * repeatInterval);
    return next;
  }
  if (repeatType === 'monthly') {
    next.setMonth(next.getMonth() + repeatInterval);
    return next;
  }
  if (repeatType === 'yearly') {
    next.setFullYear(next.getFullYear() + repeatInterval);
    return next;
  }
  return null;
}

function addNextWeeklyCustomDate(baseDate, repeatWeekdays) {
  if (!(baseDate instanceof Date) || Number.isNaN(baseDate.getTime())) {
    return null;
  }
  if (!repeatWeekdays) return null;
  const weekdays = repeatWeekdays
    .split(',')
    .map((s) => Number(s.trim()))
    .filter((d) => Number.isInteger(d) && d >= 1 && d <= 7)
    .sort((a, b) => a - b);
  if (weekdays.length === 0) return null;

  const currentWeekday = baseDate.getDay() === 0 ? 7 : baseDate.getDay();
  let minDelta = 8;
  for (const weekday of weekdays) {
    const delta = weekday > currentWeekday ? weekday - currentWeekday : 7 - currentWeekday + weekday;
    if (delta > 0 && delta < minDelta) {
      minDelta = delta;
    }
  }
  if (minDelta > 7) return null;
  const next = new Date(baseDate.getTime());
  next.setDate(next.getDate() + minDelta);
  return next;
}

const updateTaskAndMaybeCreateNext = db.transaction((id, owner, patch) => {
  const existing = db.prepare('SELECT * FROM tasks WHERE id = ?').get(id);
  if (!existing) {
    const error = new Error('任务不存在');
    error.code = 404;
    throw error;
  }
  if (existing.owner !== owner) {
    const error = new Error('无权修改此任务');
    error.code = 403;
    throw error;
  }

  const next = {
    title: patch.title ?? existing.title,
    note: patch.note ?? existing.note,
    quadrant: patch.quadrant ?? existing.quadrant,
    points: patch.points ?? existing.points,
    due_date: patch.due_date ?? existing.due_date,
    due_mode: patch.due_mode ?? existing.due_mode ?? 'day',
    repeat_type: patch.repeat_type ?? existing.repeat_type ?? 'none',
    repeat_interval: patch.repeat_interval ?? existing.repeat_interval ?? 1,
    repeat_weekdays: patch.repeat_weekdays ?? existing.repeat_weekdays ?? null,
    repeat_until: patch.repeat_until ?? existing.repeat_until ?? null,
    is_done: patch.is_done ?? existing.is_done,
    updated_at: new Date().toISOString(),
  };

  const normalizedRepeatType = normalizeRepeatType(next.repeat_type);
  const normalizedRepeatInterval = Math.max(1, Number(next.repeat_interval) || 1);
  const normalizedDueMode = normalizeDueMode(next.due_mode);
  const normalizedDueDate = normalizeDueDate(next.due_date, normalizedDueMode);
  const normalizedRepeatWeekdays = normalizedRepeatType === 'weekly_custom'
    ? normalizeRepeatWeekdays(next.repeat_weekdays)
    : null;

  db.prepare(`
    UPDATE tasks
    SET title = ?, note = ?, quadrant = ?, points = ?, due_date = ?, due_mode = ?,
        repeat_type = ?, repeat_interval = ?, repeat_weekdays = ?, repeat_until = ?,
        is_done = ?, updated_at = ?
    WHERE id = ?
  `).run(
    String(next.title).trim(),
    next.note,
    Number(next.quadrant) || 0,
    Number(next.points) || 0,
    normalizedDueDate,
    normalizedDueMode,
    normalizedRepeatType,
    normalizedRepeatInterval,
    normalizedRepeatWeekdays,
    next.repeat_until,
    next.is_done ? 1 : 0,
    next.updated_at,
    id,
  );

  const wasIncomplete = Number(existing.is_done) === 0;
  const nowComplete = next.is_done ? 1 : 0;
  const shouldCreateNext = wasIncomplete && nowComplete === 1 && normalizedRepeatType !== 'none';

  if (shouldCreateNext) {
    const baseDate = normalizedDueDate ? new Date(normalizedDueDate) : new Date();
    const nextDueDate = normalizedRepeatType === 'weekly_custom'
      ? addNextWeeklyCustomDate(baseDate, normalizedRepeatWeekdays)
      : addRepeatDate(baseDate, normalizedRepeatType, normalizedRepeatInterval);
    const repeatUntil = next.repeat_until ? new Date(next.repeat_until) : null;
    const canCreateByUntil = !repeatUntil || (nextDueDate && nextDueDate <= repeatUntil);

    if (nextDueDate && canCreateByUntil) {
      const now = new Date().toISOString();
      db.prepare(`
        INSERT INTO tasks (
          owner, title, note, quadrant, points, due_date, due_mode,
          repeat_type, repeat_interval, repeat_weekdays, repeat_until,
          is_done, created_at, updated_at
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?, ?)
      `).run(
        existing.owner,
        existing.title,
        existing.note,
        existing.quadrant,
        existing.points,
        normalizeDueDate(nextDueDate.toISOString(), normalizedDueMode),
        normalizedDueMode,
        normalizedRepeatType,
        normalizedRepeatInterval,
        normalizedRepeatWeekdays,
        next.repeat_until,
        now,
        now,
      );
    }
  }

  return db.prepare('SELECT * FROM tasks WHERE id = ?').get(id);
});

const createLedgerAndAdjustPoints = db.transaction((owner, amount, reason) => {
  const wallet = db
    .prepare('SELECT owner, points FROM point_wallets WHERE owner = ?')
    .get(owner);
  if (!wallet) {
    throw new Error('钱包不存在');
  }

  const nextPoints = wallet.points + amount;
  if (nextPoints < 0) {
    throw new Error('积分不足');
  }

  const now = new Date().toISOString();
  db.prepare('UPDATE point_wallets SET points = ?, updated_at = ? WHERE owner = ?').run(
    nextPoints,
    now,
    owner,
  );
  db.prepare('INSERT INTO point_ledger(owner, amount, reason, created_at) VALUES (?, ?, ?, ?)').run(
    owner,
    amount,
    reason,
    now,
  );

  return nextPoints;
});

const exchangeProduct = db.transaction((buyer, productId) => {
  const product = db.prepare('SELECT * FROM products WHERE id = ?').get(productId);
  if (!product) throw new Error('商品不存在');
  if (product.publisher === buyer) throw new Error('不能兑换自己发布的商品');
  if (product.stock <= 0) throw new Error('商品库存不足');

  const wallet = db.prepare('SELECT points FROM point_wallets WHERE owner = ?').get(buyer);
  if (!wallet || wallet.points < product.points_cost) throw new Error('积分不足');

  const now = new Date().toISOString();

  db.prepare('UPDATE products SET stock = stock - 1, updated_at = ? WHERE id = ?').run(
    now,
    productId,
  );

  createLedgerAndAdjustPoints(buyer, -product.points_cost, `兑换商品:${product.name}`);

  db.prepare(
    'INSERT INTO owned_items(owner, product_id, product_name, points_spent, created_at) VALUES (?, ?, ?, ?, ?)',
  ).run(buyer, product.id, product.name, product.points_cost, now);

  return { productId: product.id, productName: product.name, pointsCost: product.points_cost };
});

app.use(cors());
app.use(express.json());

app.get('/health', (_req, res) => {
  res.json({
    code: 200,
    message: 'ok',
    result: { service: 'priority_first_backend', dbPath },
  });
});

app.get('/tasks', (req, res) => {
  const owner = req.query.owner || OWNER_ME;
  if (!validateOwner(owner)) {
    return res.status(400).json({ code: 400, message: 'owner 参数非法', result: null });
  }
  const rows = db
    .prepare('SELECT * FROM tasks WHERE owner = ? ORDER BY is_done ASC, updated_at DESC')
    .all(owner);
  res.json({ code: 200, message: '获取任务成功', result: { list: rows, total: rows.length } });
});

app.post('/tasks', (req, res) => {
  const {
    owner = OWNER_ME,
    title,
    note = null,
    quadrant = 0,
    points = 0,
    due_date = null,
    due_mode = 'day',
    repeat_type = 'none',
    repeat_interval = 1,
    repeat_weekdays = null,
    repeat_until = null,
  } = req.body || {};
  if (!validateOwner(owner)) {
    return res.status(400).json({ code: 400, message: 'owner 参数非法', result: null });
  }
  if (!title || String(title).trim() === '') {
    return res.status(400).json({ code: 400, message: 'title 不能为空', result: null });
  }
  const now = new Date().toISOString();
  const stmt = db.prepare(`
    INSERT INTO tasks (
      owner, title, note, quadrant, points, due_date, due_mode,
      repeat_type, repeat_interval, repeat_weekdays, repeat_until,
      is_done, created_at, updated_at
    )
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?, ?)
  `);
  const normalizedDueMode = normalizeDueMode(due_mode);
  const normalizedDueDate = normalizeDueDate(due_date, normalizedDueMode);
  const normalizedRepeatType = normalizeRepeatType(repeat_type);
  const normalizedRepeatWeekdays = normalizedRepeatType === 'weekly_custom'
    ? normalizeRepeatWeekdays(repeat_weekdays)
    : null;
  const info = stmt.run(
    owner,
    String(title).trim(),
    note,
    Number(quadrant) || 0,
    Number(points) || 0,
    normalizedDueDate,
    normalizedDueMode,
    normalizedRepeatType,
    Math.max(1, Number(repeat_interval) || 1),
    normalizedRepeatWeekdays,
    repeat_until,
    now,
    now,
  );
  const row = db.prepare('SELECT * FROM tasks WHERE id = ?').get(info.lastInsertRowid);
  res.json({ code: 200, message: '创建任务成功', result: row });
});

app.patch('/tasks/:id', (req, res) => {
  const id = Number(req.params.id);
  const owner = req.query.owner || req.body?.owner || OWNER_ME;
  if (!validateOwner(owner)) {
    return res.status(400).json({ code: 400, message: 'owner 参数非法', result: null });
  }
  const patch = req.body || {};
  try {
    const row = updateTaskAndMaybeCreateNext(id, owner, patch);
    res.json({ code: 200, message: '更新任务成功', result: row });
  } catch (error) {
    const status = error.code || 400;
    res.status(status).json({ code: status, message: error.message, result: null });
  }
});

app.delete('/tasks/:id', (req, res) => {
  const id = Number(req.params.id);
  const owner = req.query.owner || OWNER_ME;
  if (!validateOwner(owner)) {
    return res.status(400).json({ code: 400, message: 'owner 参数非法', result: null });
  }
  const info = db.prepare('DELETE FROM tasks WHERE id = ? AND owner = ?').run(id, owner);
  if (info.changes === 0) {
    return res.status(404).json({ code: 404, message: '任务不存在', result: null });
  }
  res.json({ code: 200, message: '删除任务成功', result: { id } });
});

app.get('/store/points', (req, res) => {
  const owner = req.query.owner || OWNER_ME;
  if (!validateOwner(owner)) {
    return res.status(400).json({ code: 400, message: 'owner 参数非法', result: null });
  }

  const wallet = db
    .prepare('SELECT owner, points, updated_at FROM point_wallets WHERE owner = ?')
    .get(owner);
  const ledger = db
    .prepare('SELECT id, amount, reason, created_at FROM point_ledger WHERE owner = ? ORDER BY id DESC LIMIT 20')
    .all(owner);
  res.json({ code: 200, message: '获取积分成功', result: { wallet, ledger } });
});

app.post('/store/points/adjust', (req, res) => {
  const { owner = OWNER_ME, amount = 0, reason = '手动调整积分' } = req.body || {};
  if (!validateOwner(owner)) {
    return res.status(400).json({ code: 400, message: 'owner 参数非法', result: null });
  }

  try {
    const nextPoints = createLedgerAndAdjustPoints(
      owner,
      Number(amount) || 0,
      String(reason || '手动调整积分'),
    );
    res.json({ code: 200, message: '积分调整成功', result: { owner, points: nextPoints } });
  } catch (error) {
    res.status(400).json({ code: 400, message: error.message, result: null });
  }
});

app.get('/store/products', (req, res) => {
  const viewer = req.query.viewer || OWNER_ME;
  if (!validateOwner(viewer)) {
    return res.status(400).json({ code: 400, message: 'viewer 参数非法', result: null });
  }
  const targetPublisher = viewer === OWNER_ME ? OWNER_PARTNER : OWNER_ME;
  const list = db
    .prepare('SELECT * FROM products WHERE publisher = ? ORDER BY updated_at DESC')
    .all(targetPublisher);
  res.json({ code: 200, message: '获取可兑换商品成功', result: { list } });
});

app.get('/store/my-products', (req, res) => {
  const owner = req.query.owner || OWNER_ME;
  if (!validateOwner(owner)) {
    return res.status(400).json({ code: 400, message: 'owner 参数非法', result: null });
  }
  const list = db
    .prepare('SELECT * FROM products WHERE publisher = ? ORDER BY updated_at DESC')
    .all(owner);
  res.json({ code: 200, message: '获取我发布的商品成功', result: { list } });
});

app.post('/store/products', (req, res) => {
  const {
    publisher = OWNER_ME,
    name,
    description = null,
    points_cost = 0,
    stock = 0,
  } = req.body || {};

  if (!validateOwner(publisher)) {
    return res.status(400).json({ code: 400, message: 'publisher 参数非法', result: null });
  }
  if (!name || String(name).trim() === '') {
    return res.status(400).json({ code: 400, message: 'name 不能为空', result: null });
  }
  const now = new Date().toISOString();
  const info = db
    .prepare(
      `INSERT INTO products (publisher, name, description, points_cost, stock, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
    )
    .run(
      publisher,
      String(name).trim(),
      description,
      Number(points_cost) || 0,
      Number(stock) || 0,
      now,
      now,
    );
  const row = db.prepare('SELECT * FROM products WHERE id = ?').get(info.lastInsertRowid);
  res.json({ code: 200, message: '发布商品成功', result: row });
});

app.put('/store/products/:id', (req, res) => {
  const id = Number(req.params.id);
  const {
    owner = OWNER_ME,
    name,
    description = null,
    points_cost = 0,
    stock = 0,
  } = req.body || {};
  if (!validateOwner(owner)) {
    return res.status(400).json({ code: 400, message: 'owner 参数非法', result: null });
  }

  const existing = db.prepare('SELECT * FROM products WHERE id = ?').get(id);
  if (!existing) {
    return res.status(404).json({ code: 404, message: '商品不存在', result: null });
  }
  if (existing.publisher !== owner) {
    return res.status(403).json({ code: 403, message: '无权编辑该商品', result: null });
  }
  if (!name || String(name).trim() === '') {
    return res.status(400).json({ code: 400, message: 'name 不能为空', result: null });
  }

  const now = new Date().toISOString();
  db.prepare(
    `UPDATE products
     SET name = ?, description = ?, points_cost = ?, stock = ?, updated_at = ?
     WHERE id = ?`,
  ).run(
    String(name).trim(),
    description,
    Number(points_cost) || 0,
    Number(stock) || 0,
    now,
    id,
  );
  const row = db.prepare('SELECT * FROM products WHERE id = ?').get(id);
  res.json({ code: 200, message: '更新商品成功', result: row });
});

app.delete('/store/products/:id', (req, res) => {
  const id = Number(req.params.id);
  const owner = req.query.owner || OWNER_ME;
  if (!validateOwner(owner)) {
    return res.status(400).json({ code: 400, message: 'owner 参数非法', result: null });
  }

  const existing = db.prepare('SELECT * FROM products WHERE id = ?').get(id);
  if (!existing) {
    return res.status(404).json({ code: 404, message: '商品不存在', result: null });
  }
  if (existing.publisher !== owner) {
    return res.status(403).json({ code: 403, message: '无权下架该商品', result: null });
  }

  db.prepare('DELETE FROM products WHERE id = ?').run(id);
  res.json({ code: 200, message: '商品下架成功', result: { id } });
});

app.post('/store/exchange', (req, res) => {
  const { buyer = OWNER_ME, product_id } = req.body || {};
  if (!validateOwner(buyer)) {
    return res.status(400).json({ code: 400, message: 'buyer 参数非法', result: null });
  }

  try {
    const result = exchangeProduct(buyer, Number(product_id));
    res.json({ code: 200, message: '兑换成功', result });
  } catch (error) {
    res.status(400).json({ code: 400, message: error.message, result: null });
  }
});

app.get('/store/owned', (req, res) => {
  const owner = req.query.owner || OWNER_ME;
  if (!validateOwner(owner)) {
    return res.status(400).json({ code: 400, message: 'owner 参数非法', result: null });
  }

  const list = db
    .prepare('SELECT * FROM owned_items WHERE owner = ? ORDER BY id DESC')
    .all(owner);
  res.json({ code: 200, message: '获取已兑商品成功', result: { list } });
});

app.get('/profile', (req, res) => {
  const owner = req.query.owner || OWNER_ME;
  if (!validateOwner(owner)) {
    return res.status(400).json({ code: 400, message: 'owner 参数非法', result: null });
  }
  const profile = db
    .prepare('SELECT owner, display_name, bio, avatar, relationship_label, updated_at FROM profiles WHERE owner = ?')
    .get(owner);
  res.json({ code: 200, message: '获取资料成功', result: profile });
});

app.put('/profile', (req, res) => {
  const { owner = OWNER_ME, display_name, bio = null, avatar = null, relationship_label = '搭档' } = req.body || {};
  if (!validateOwner(owner)) {
    return res.status(400).json({ code: 400, message: 'owner 参数非法', result: null });
  }
  if (!display_name || String(display_name).trim() === '') {
    return res.status(400).json({ code: 400, message: 'display_name 不能为空', result: null });
  }
  const now = new Date().toISOString();
  db.prepare(
    `UPDATE profiles
      SET display_name = ?, bio = ?, avatar = ?, relationship_label = ?, updated_at = ?
      WHERE owner = ?`,
  ).run(
    String(display_name).trim(),
    bio ? String(bio).trim() : null,
    avatar ? String(avatar).trim() : null,
    String(relationship_label || '搭档').trim(),
    now,
    owner,
  );
  const profile = db.prepare('SELECT * FROM profiles WHERE owner = ?').get(owner);
  res.json({ code: 200, message: '更新资料成功', result: profile });
});

app.get('/settings', (req, res) => {
  const owner = req.query.owner || OWNER_ME;
  if (!validateOwner(owner)) {
    return res.status(400).json({ code: 400, message: 'owner 参数非法', result: null });
  }
  const settings = db
    .prepare(
      `SELECT owner, duo_enabled, notifications_enabled, quiet_hours_start, quiet_hours_end,
       relation_checkin, relation_reminder, relation_coop_hint, security_login_alert, security_risk_guard, updated_at
       FROM app_settings WHERE owner = ?`,
    )
    .get(owner);
  res.json({ code: 200, message: '获取设置成功', result: settings });
});

app.put('/settings', (req, res) => {
  const {
    owner = OWNER_ME,
    duo_enabled,
    notifications_enabled,
    quiet_hours_start = null,
    quiet_hours_end = null,
    relation_checkin,
    relation_reminder,
    relation_coop_hint,
    security_login_alert,
    security_risk_guard,
  } = req.body || {};
  if (!validateOwner(owner)) {
    return res.status(400).json({ code: 400, message: 'owner 参数非法', result: null });
  }
  const existing = db.prepare('SELECT * FROM app_settings WHERE owner = ?').get(owner);
  if (!existing) {
    return res.status(404).json({ code: 404, message: '设置不存在', result: null });
  }
  const nextDuoEnabled = duo_enabled === undefined ? existing.duo_enabled : toBoolInt(duo_enabled, existing.duo_enabled === 1);
  const nextNotificationsEnabled = notifications_enabled === undefined
    ? existing.notifications_enabled
    : toBoolInt(notifications_enabled, existing.notifications_enabled === 1);
  const nextRelationCheckin = relation_checkin === undefined
    ? existing.relation_checkin
    : toBoolInt(relation_checkin, existing.relation_checkin === 1);
  const nextRelationReminder = relation_reminder === undefined
    ? existing.relation_reminder
    : toBoolInt(relation_reminder, existing.relation_reminder === 1);
  const nextRelationCoopHint = relation_coop_hint === undefined
    ? existing.relation_coop_hint
    : toBoolInt(relation_coop_hint, existing.relation_coop_hint === 1);
  const nextSecurityLoginAlert = security_login_alert === undefined
    ? existing.security_login_alert
    : toBoolInt(security_login_alert, existing.security_login_alert === 1);
  const nextSecurityRiskGuard = security_risk_guard === undefined
    ? existing.security_risk_guard
    : toBoolInt(security_risk_guard, existing.security_risk_guard === 1);
  const now = new Date().toISOString();

  db.prepare(
    `UPDATE app_settings
     SET duo_enabled = ?, notifications_enabled = ?, quiet_hours_start = ?, quiet_hours_end = ?,
         relation_checkin = ?, relation_reminder = ?, relation_coop_hint = ?,
         security_login_alert = ?, security_risk_guard = ?, updated_at = ?
     WHERE owner = ?`,
  ).run(
    nextDuoEnabled,
    nextNotificationsEnabled,
    quiet_hours_start ?? existing.quiet_hours_start,
    quiet_hours_end ?? existing.quiet_hours_end,
    nextRelationCheckin,
    nextRelationReminder,
    nextRelationCoopHint,
    nextSecurityLoginAlert,
    nextSecurityRiskGuard,
    now,
    owner,
  );

  const settings = db.prepare('SELECT * FROM app_settings WHERE owner = ?').get(owner);
  res.json({ code: 200, message: '更新设置成功', result: settings });
});

app.get('/feedback', (req, res) => {
  const owner = req.query.owner || OWNER_ME;
  const limit = Math.min(
    Math.max(Number(req.query.limit) || 20, 1),
    APP_CONFIG.feedback.listLimitMax,
  );
  if (!validateOwner(owner)) {
    return res.status(400).json({ code: 400, message: 'owner 参数非法', result: null });
  }
  const list = db
    .prepare(
      'SELECT id, owner, category, title, detail, contact, created_at FROM feedback_items WHERE owner = ? ORDER BY id DESC LIMIT ?',
    )
    .all(owner, limit);
  res.json({ code: 200, message: '获取反馈成功', result: { list } });
});

app.post('/feedback', (req, res) => {
  const { owner = OWNER_ME, category, title, detail, contact = null } = req.body || {};
  if (!validateOwner(owner)) {
    return res.status(400).json({ code: 400, message: 'owner 参数非法', result: null });
  }
  const safeCategory = String(category || '').trim();
  const safeTitle = String(title || '').trim();
  const safeDetail = String(detail || '').trim();
  const safeContact = contact ? String(contact).trim() : null;

  if (!safeCategory) {
    return res.status(400).json({ code: 400, message: 'category 不能为空', result: null });
  }
  if (!safeTitle) {
    return res.status(400).json({ code: 400, message: 'title 不能为空', result: null });
  }
  if (!safeDetail) {
    return res.status(400).json({ code: 400, message: 'detail 不能为空', result: null });
  }
  if (safeCategory.length > APP_CONFIG.feedback.categoryMax) {
    return res
      .status(400)
      .json({ code: 400, message: 'category 超出长度限制', result: null });
  }
  if (safeTitle.length > APP_CONFIG.feedback.titleMax) {
    return res
      .status(400)
      .json({ code: 400, message: 'title 超出长度限制', result: null });
  }
  if (safeDetail.length > APP_CONFIG.feedback.detailMax) {
    return res
      .status(400)
      .json({ code: 400, message: 'detail 超出长度限制', result: null });
  }
  if (safeContact && safeContact.length > APP_CONFIG.feedback.contactMax) {
    return res
      .status(400)
      .json({ code: 400, message: 'contact 超出长度限制', result: null });
  }

  const now = new Date().toISOString();
  const info = db
    .prepare(
      `INSERT INTO feedback_items(owner, category, title, detail, contact, created_at)
       VALUES (?, ?, ?, ?, ?, ?)`,
    )
    .run(owner, safeCategory, safeTitle, safeDetail, safeContact, now);
  const row = db
    .prepare(
      'SELECT id, owner, category, title, detail, contact, created_at FROM feedback_items WHERE id = ?',
    )
    .get(info.lastInsertRowid);
  res.json({ code: 200, message: '提交反馈成功', result: row });
});

app.get('/notifications', (req, res) => {
  const owner = req.query.owner || OWNER_ME;
  const status = req.query.status || 'all';
  const limit = Math.min(Math.max(Number(req.query.limit) || 30, 1), 100);
  if (!validateOwner(owner)) {
    return res.status(400).json({ code: 400, message: 'owner 参数非法', result: null });
  }
  if (status !== 'all' && status !== 'unread') {
    return res.status(400).json({ code: 400, message: 'status 参数非法', result: null });
  }

  const list = status === 'unread'
    ? db
        .prepare(
          'SELECT id, owner, type, title, body, is_read, created_at FROM notifications WHERE owner = ? AND is_read = 0 ORDER BY id DESC LIMIT ?',
        )
        .all(owner, limit)
    : db
        .prepare(
          'SELECT id, owner, type, title, body, is_read, created_at FROM notifications WHERE owner = ? ORDER BY id DESC LIMIT ?',
        )
        .all(owner, limit);
  const unreadCount = db
    .prepare('SELECT COUNT(1) AS count FROM notifications WHERE owner = ? AND is_read = 0')
    .get(owner).count;
  res.json({ code: 200, message: '获取通知成功', result: { list, unread_count: unreadCount } });
});

app.post('/notifications', (req, res) => {
  const { owner = OWNER_ME, type = 'system', title, body } = req.body || {};
  if (!validateOwner(owner)) {
    return res.status(400).json({ code: 400, message: 'owner 参数非法', result: null });
  }
  if (!title || String(title).trim() === '' || !body || String(body).trim() === '') {
    return res.status(400).json({ code: 400, message: 'title/body 不能为空', result: null });
  }
  const now = new Date().toISOString();
  const info = db
    .prepare(
      'INSERT INTO notifications(owner, type, title, body, is_read, created_at) VALUES (?, ?, ?, ?, 0, ?)',
    )
    .run(owner, String(type || 'system').trim(), String(title).trim(), String(body).trim(), now);
  const row = db.prepare('SELECT * FROM notifications WHERE id = ?').get(info.lastInsertRowid);
  res.json({ code: 200, message: '创建通知成功', result: row });
});

app.post('/notifications/mark-read', (req, res) => {
  const { owner = OWNER_ME, id } = req.body || {};
  if (!validateOwner(owner)) {
    return res.status(400).json({ code: 400, message: 'owner 参数非法', result: null });
  }
  const targetId = Number(id);
  if (!targetId) {
    return res.status(400).json({ code: 400, message: 'id 参数非法', result: null });
  }
  const info = db
    .prepare('UPDATE notifications SET is_read = 1 WHERE id = ? AND owner = ?')
    .run(targetId, owner);
  if (info.changes === 0) {
    return res.status(404).json({ code: 404, message: '通知不存在', result: null });
  }
  res.json({ code: 200, message: '通知已读成功', result: { id: targetId } });
});

app.post('/notifications/mark-all-read', (req, res) => {
  const { owner = OWNER_ME } = req.body || {};
  if (!validateOwner(owner)) {
    return res.status(400).json({ code: 400, message: 'owner 参数非法', result: null });
  }
  const info = db
    .prepare('UPDATE notifications SET is_read = 1 WHERE owner = ? AND is_read = 0')
    .run(owner);
  res.json({ code: 200, message: '全部通知已读成功', result: { changes: info.changes } });
});

app.post('/auth/register/phone', (req, res) => {
  const { phone, password, display_name = '新用户' } = req.body || {};
  if (!isPhone(phone)) {
    return res.status(400).json({ code: 400, message: '手机号格式非法', result: null });
  }
  if (!isStrongPassword(password)) {
    return res.status(400).json({ code: 400, message: '密码至少 6 位', result: null });
  }
  const exists = db.prepare('SELECT id FROM auth_users WHERE phone = ?').get(String(phone).trim());
  if (exists) {
    return res.status(409).json({ code: 409, message: '手机号已注册', result: null });
  }
  const now = new Date().toISOString();
  const info = db.prepare(
    `INSERT INTO auth_users(phone, password_hash, display_name, status, created_at, updated_at)
     VALUES (?, ?, ?, 'active', ?, ?)`,
  ).run(
    String(phone).trim(),
    hashPassword(password),
    String(display_name || '新用户').trim(),
    now,
    now,
  );
  const user = db.prepare('SELECT id, account, role, phone, wechat_openid, display_name, status, created_at, updated_at FROM auth_users WHERE id = ?')
    .get(info.lastInsertRowid);
  res.json({ code: 200, message: '手机号注册成功', result: user });
});

app.post('/auth/login/phone', (req, res) => {
  const { phone, password } = req.body || {};
  const clientKey = getClientKey(req);
  const normalizedPhone = String(phone || '').trim();
  if (!isPhone(phone) || !isStrongPassword(password)) {
    writeAuthEvent({
      action: 'login_phone_invalid',
      phone: normalizedPhone || null,
      clientKey,
      success: 0,
      detail: 'format-invalid',
    });
    return res.status(400).json({ code: 400, message: '手机号或密码格式非法', result: null });
  }
  const clientRecentFails = countRecentAuthEvents({
    action: 'login_phone_fail',
    clientKey,
    windowSeconds: 10 * 60,
  });
  if (clientRecentFails >= 20) {
    return res.status(429).json({ code: 429, message: '尝试次数过多，请稍后再试', result: null });
  }

  const user = db.prepare(
    'SELECT * FROM auth_users WHERE phone = ? AND status = ?',
  ).get(normalizedPhone, 'active');
  if (user && user.locked_until && new Date(user.locked_until).getTime() > Date.now()) {
    return res.status(423).json({ code: 423, message: '账号已临时锁定，请稍后再试', result: null });
  }
  if (!user || user.password_hash !== hashPassword(password)) {
    if (user) {
      const nextFail = (Number(user.failed_login_count) || 0) + 1;
      const lockUntil = nextFail >= 5
        ? new Date(Date.now() + 15 * 60 * 1000).toISOString()
        : null;
      db.prepare(
        'UPDATE auth_users SET failed_login_count = ?, locked_until = ?, updated_at = ? WHERE id = ?',
      ).run(nextFail, lockUntil, nowIso(), user.id);
    }
    writeAuthEvent({
      action: 'login_phone_fail',
      phone: normalizedPhone,
      clientKey,
      success: 0,
      detail: 'credential-mismatch',
    });
    return res.status(401).json({ code: 401, message: '手机号或密码错误', result: null });
  }
  const now = new Date();
  const expires = new Date(now.getTime() + 1000 * 60 * 60 * 24 * 30).toISOString();
  const token = createSessionToken();
  db.prepare(
    'UPDATE auth_users SET failed_login_count = 0, locked_until = NULL, updated_at = ? WHERE id = ?',
  ).run(now.toISOString(), user.id);
  db.prepare(
    `INSERT INTO auth_sessions(token, user_id, provider, owner_hint, expires_at, created_at, last_seen_at)
     VALUES (?, ?, 'phone', 'me', ?, ?, ?)`,
  ).run(token, user.id, expires, now.toISOString(), now.toISOString());
  writeAuthEvent({
    action: 'login_phone_success',
    phone: normalizedPhone,
    clientKey,
    success: 1,
    detail: 'ok',
  });
  res.json({
    code: 200,
    message: '登录成功',
    result: {
      token,
      provider: 'phone',
      expires_at: expires,
      user: {
        id: user.id,
        phone: user.phone,
        account: user.account,
        role: user.role,
        roles: getUserRoles(user.id),
        permissions: getUserPermissions(user.id),
        display_name: user.display_name,
        status: user.status,
      },
    },
  });
});

app.post('/auth/login/wechat', (req, res) => {
  const { wechat_code, display_name = '微信用户' } = req.body || {};
  if (!wechat_code || String(wechat_code).trim().length < 4) {
    return res.status(400).json({ code: 400, message: 'wechat_code 非法', result: null });
  }
  const openid = `wx_${String(wechat_code).trim()}`;
  const now = new Date().toISOString();
  let user = db.prepare('SELECT * FROM auth_users WHERE wechat_openid = ?').get(openid);
  if (!user) {
    const info = db.prepare(
      `INSERT INTO auth_users(phone, wechat_openid, password_hash, display_name, status, created_at, updated_at)
       VALUES (NULL, ?, NULL, ?, 'active', ?, ?)`,
    ).run(openid, String(display_name || '微信用户').trim(), now, now);
    user = db.prepare('SELECT * FROM auth_users WHERE id = ?').get(info.lastInsertRowid);
  }
  const nowDate = new Date();
  const expires = new Date(nowDate.getTime() + 1000 * 60 * 60 * 24 * 30).toISOString();
  const token = createSessionToken();
  db.prepare(
    `INSERT INTO auth_sessions(token, user_id, provider, owner_hint, expires_at, created_at, last_seen_at)
     VALUES (?, ?, 'wechat', 'me', ?, ?, ?)`,
  ).run(token, user.id, expires, nowDate.toISOString(), nowDate.toISOString());
  res.json({
    code: 200,
    message: '微信登录成功',
    result: {
      token,
      provider: 'wechat',
      expires_at: expires,
      user: {
        id: user.id,
        account: user.account,
        role: user.role,
        roles: getUserRoles(user.id),
        permissions: getUserPermissions(user.id),
        wechat_openid: user.wechat_openid,
        display_name: user.display_name,
        status: user.status,
      },
    },
  });
});

app.post('/auth/register/account', (req, res) => {
  const { account, password, display_name = '新用户', invite_code } = req.body || {};
  const normalizedAccount = normalizeAccount(account);
  const normalizedInvite = normalizeInviteCode(invite_code);
  const clientKey = getClientKey(req);

  if (!isAccount(normalizedAccount) || !isStrongPassword(password)) {
    writeAuthEvent({
      action: 'register_account_invalid',
      clientKey,
      success: 0,
      detail: 'format-invalid',
    });
    return res.status(400).json({ code: 400, message: '账号或密码格式非法', result: null });
  }
  if (!normalizedInvite) {
    return res.status(400).json({ code: 400, message: '邀请码不能为空', result: null });
  }

  const exists = db.prepare('SELECT id FROM auth_users WHERE account = ?').get(normalizedAccount);
  if (exists) {
    writeAuthEvent({
      action: 'register_account_fail',
      clientKey,
      success: 0,
      detail: 'account-exists',
    });
    return res.status(409).json({ code: 409, message: '账号已注册', result: null });
  }

  const invite = db.prepare('SELECT * FROM auth_invite_codes WHERE code = ?').get(normalizedInvite);
  const inviteCheck = isInviteUsable(invite);
  if (!inviteCheck.ok) {
    writeAuthEvent({
      action: 'register_account_fail',
      clientKey,
      success: 0,
      detail: `invite-${inviteCheck.reason}`,
    });
    return res.status(403).json({ code: 403, message: inviteCheck.reason, result: null });
  }

  try {
    const result = db.transaction(() => {
      const latestInvite = db.prepare('SELECT * FROM auth_invite_codes WHERE code = ?')
        .get(normalizedInvite);
      const latestCheck = isInviteUsable(latestInvite);
      if (!latestCheck.ok) {
        const error = new Error(latestCheck.reason || '邀请码不可用');
        error.code = 'invite-invalid';
        throw error;
      }

      const now = nowIso();
      const info = db.prepare(
        `INSERT INTO auth_users(account, phone, email, wechat_openid, password_hash, display_name, role, status, created_at, updated_at)
         VALUES (?, NULL, NULL, NULL, ?, ?, 'user', 'active', ?, ?)`,
      ).run(
        normalizedAccount,
        hashPassword(password),
        String(display_name || '新用户').trim(),
        now,
        now,
      );
      const newUserId = info.lastInsertRowid;
      const nextUsedCount = Number(latestInvite.used_count) + 1;
      const nextStatus = nextUsedCount >= Number(latestInvite.usage_limit) ? 'exhausted' : 'active';
      db.prepare(
        `UPDATE auth_invite_codes
         SET used_count = ?, used_by = ?, used_at = ?, status = ?
         WHERE id = ?`,
      ).run(
        nextUsedCount,
        newUserId,
        now,
        nextStatus,
        latestInvite.id,
      );

      const token = createSessionToken();
      const expires = new Date(Date.now() + 1000 * 60 * 60 * 24 * 30).toISOString();
      db.prepare(
        `INSERT INTO auth_sessions(token, user_id, provider, owner_hint, expires_at, created_at, last_seen_at)
         VALUES (?, ?, 'account', 'me', ?, ?, ?)`,
      ).run(token, newUserId, expires, now, now);

      return {
        token,
        expires_at: expires,
        user: {
          id: newUserId,
          account: normalizedAccount,
          display_name: String(display_name || '新用户').trim(),
          status: 'active',
          role: 'user',
        },
      };
    })();

    writeAuthEvent({
      action: 'register_account_success',
      clientKey,
      success: 1,
      detail: 'ok',
    });
    res.json({ code: 200, message: '账号注册成功', result });
  } catch (error) {
    if (error?.code === 'invite-invalid') {
      res.status(403).json({ code: 403, message: String(error.message), result: null });
      return;
    }
    console.error('[auth] register account failed', error);
    res.status(500).json({ code: 500, message: '注册失败', result: null });
  }
});

app.post('/auth/login/account', (req, res) => {
  const { account, password } = req.body || {};
  const normalizedAccount = normalizeAccount(account);
  const clientKey = getClientKey(req);

  if (!isAccount(normalizedAccount) || !isStrongPassword(password)) {
    writeAuthEvent({
      action: 'login_account_invalid',
      clientKey,
      success: 0,
      detail: 'format-invalid',
    });
    return res.status(400).json({ code: 400, message: '账号或密码格式非法', result: null });
  }

  const clientRecentFails = countRecentAuthEvents({
    action: 'login_account_fail',
    clientKey,
    windowSeconds: 10 * 60,
  });
  if (clientRecentFails >= 20) {
    return res.status(429).json({ code: 429, message: '尝试次数过多，请稍后再试', result: null });
  }

  const user = db.prepare('SELECT * FROM auth_users WHERE account = ? AND status = ?')
    .get(normalizedAccount, 'active');
  if (user && user.locked_until && new Date(user.locked_until).getTime() > Date.now()) {
    return res.status(423).json({ code: 423, message: '账号已临时锁定，请稍后再试', result: null });
  }
  if (!user || user.password_hash !== hashPassword(password)) {
    if (user) {
      const nextFail = (Number(user.failed_login_count) || 0) + 1;
      const lockUntil = nextFail >= 5
        ? new Date(Date.now() + 15 * 60 * 1000).toISOString()
        : null;
      db.prepare(
        'UPDATE auth_users SET failed_login_count = ?, locked_until = ?, updated_at = ? WHERE id = ?',
      ).run(nextFail, lockUntil, nowIso(), user.id);
    }
    writeAuthEvent({
      action: 'login_account_fail',
      clientKey,
      success: 0,
      detail: 'credential-mismatch',
    });
    return res.status(401).json({ code: 401, message: '账号或密码错误', result: null });
  }

  const now = nowIso();
  const expires = new Date(Date.now() + 1000 * 60 * 60 * 24 * 30).toISOString();
  const token = createSessionToken();
  db.prepare(
    'UPDATE auth_users SET failed_login_count = 0, locked_until = NULL, updated_at = ? WHERE id = ?',
  ).run(now, user.id);
  db.prepare(
    `INSERT INTO auth_sessions(token, user_id, provider, owner_hint, expires_at, created_at, last_seen_at)
     VALUES (?, ?, 'account', 'me', ?, ?, ?)`,
  ).run(token, user.id, expires, now, now);
  writeAuthEvent({
    action: 'login_account_success',
    clientKey,
    success: 1,
    detail: 'ok',
  });

  res.json({
    code: 200,
    message: '账号登录成功',
    result: {
      token,
      provider: 'account',
      expires_at: expires,
      user: {
        id: user.id,
        account: user.account,
        display_name: user.display_name,
        status: user.status,
        role: user.role,
        roles: getUserRoles(user.id),
        permissions: getUserPermissions(user.id),
      },
    },
  });
});

app.post('/admin/invite-codes', (req, res) => {
  const session = requirePermission(req, res, 'admin.invites.manage');
  if (!session) return;
  const count = Math.max(1, Math.min(50, Number(req.body?.count || 1)));
  const usageLimit = Math.max(1, Math.min(10, Number(req.body?.usage_limit || 1)));
  const expiresAt = req.body?.expires_at ? new Date(req.body.expires_at).toISOString() : null;
  const now = nowIso();
  const codes = [];

  const insert = db.prepare(
    `INSERT INTO auth_invite_codes(code, status, usage_limit, used_count, created_by, used_by, created_at, used_at, expires_at)
     VALUES (?, 'active', ?, 0, ?, NULL, ?, NULL, ?)`,
  );

  for (let i = 0; i < count; i += 1) {
    let code;
    let tries = 0;
    while (tries < 20) {
      code = createInviteCode(8);
      try {
        insert.run(code, usageLimit, session.user_id, now, expiresAt);
        codes.push(code);
        break;
      } catch (error) {
        tries += 1;
        if (tries >= 20) {
          console.error('[auth] invite code create failed', error);
        }
      }
    }
  }

  res.json({
    code: 200,
    message: '邀请码创建成功',
    result: { codes, usage_limit: usageLimit, expires_at: expiresAt },
  });
});

app.get('/admin/invite-codes', (req, res) => {
  const session = requirePermission(req, res, 'admin.invites.view');
  if (!session) return;
  const status = String(req.query?.status || '').trim();
  const limit = Math.max(1, Math.min(200, Number(req.query?.limit || 50)));
  const rows = status
    ? db.prepare(
      'SELECT * FROM auth_invite_codes WHERE status = ? ORDER BY id DESC LIMIT ?',
    ).all(status, limit)
    : db.prepare('SELECT * FROM auth_invite_codes ORDER BY id DESC LIMIT ?').all(limit);
  res.json({ code: 200, message: 'ok', result: rows });
});

app.post('/admin/invite-codes/disable', (req, res) => {
  const session = requirePermission(req, res, 'admin.invites.manage');
  if (!session) return;
  const code = normalizeInviteCode(req.body?.code);
  if (!code) {
    return res.status(400).json({ code: 400, message: 'code 不能为空', result: null });
  }
  const row = db.prepare('SELECT * FROM auth_invite_codes WHERE code = ?').get(code);
  if (!row) {
    return res.status(404).json({ code: 404, message: '邀请码不存在', result: null });
  }
  db.prepare('UPDATE auth_invite_codes SET status = ? WHERE id = ?').run('disabled', row.id);
  res.json({ code: 200, message: '邀请码已禁用', result: { code } });
});

app.get('/admin/permissions', (req, res) => {
  const session = requirePermission(req, res, 'admin.roles.view');
  if (!session) return;
  const rows = db.prepare('SELECT * FROM auth_permissions ORDER BY code ASC').all();
  res.json({ code: 200, message: 'ok', result: rows });
});

app.get('/admin/roles', (req, res) => {
  const session = requirePermission(req, res, 'admin.roles.view');
  if (!session) return;
  const roles = db.prepare('SELECT * FROM auth_roles ORDER BY id ASC').all();
  const rolePerms = db.prepare(
    `SELECT rp.role_id, p.code
     FROM auth_role_permissions rp
     JOIN auth_permissions p ON p.id = rp.permission_id`,
  ).all();
  const roleMap = new Map();
  roles.forEach((role) => roleMap.set(role.id, { ...role, permissions: [] }));
  rolePerms.forEach((row) => {
    const target = roleMap.get(row.role_id);
    if (target) target.permissions.push(row.code);
  });
  res.json({ code: 200, message: 'ok', result: Array.from(roleMap.values()) });
});

app.post('/admin/roles', (req, res) => {
  const session = requirePermission(req, res, 'admin.roles.manage');
  if (!session) return;
  const { name, description = null, permission_codes = [] } = req.body || {};
  const normalizedName = String(name || '').trim();
  if (!normalizedName) {
    return res.status(400).json({ code: 400, message: '角色名称不能为空', result: null });
  }
  const now = nowIso();
  const info = db.prepare(
    `INSERT INTO auth_roles(name, description, created_at, updated_at)
     VALUES (?, ?, ?, ?)`,
  ).run(normalizedName, description, now, now);

  const roleId = info.lastInsertRowid;
  const permRows = db.prepare(
    `SELECT id, code FROM auth_permissions WHERE code IN (${permission_codes.map(() => '?').join(',') || "''"})`,
  ).all(...permission_codes);
  const insertRolePerm = db.prepare(
    `INSERT OR IGNORE INTO auth_role_permissions(role_id, permission_id, created_at)
     VALUES (?, ?, ?)`,
  );
  permRows.forEach((perm) => insertRolePerm.run(roleId, perm.id, now));
  res.json({ code: 200, message: '角色创建成功', result: { id: roleId } });
});

app.put('/admin/roles/:id', (req, res) => {
  const session = requirePermission(req, res, 'admin.roles.manage');
  if (!session) return;
  const roleId = Number(req.params.id);
  if (!roleId) {
    return res.status(400).json({ code: 400, message: '角色 id 非法', result: null });
  }
  const { name, description = null, permission_codes = [] } = req.body || {};
  const role = db.prepare('SELECT * FROM auth_roles WHERE id = ?').get(roleId);
  if (!role) {
    return res.status(404).json({ code: 404, message: '角色不存在', result: null });
  }
  const now = nowIso();
  if (name) {
    db.prepare('UPDATE auth_roles SET name = ?, description = ?, updated_at = ? WHERE id = ?')
      .run(String(name).trim(), description, now, roleId);
  } else if (description !== null) {
    db.prepare('UPDATE auth_roles SET description = ?, updated_at = ? WHERE id = ?')
      .run(description, now, roleId);
  }
  db.prepare('DELETE FROM auth_role_permissions WHERE role_id = ?').run(roleId);
  const permRows = db.prepare(
    `SELECT id, code FROM auth_permissions WHERE code IN (${permission_codes.map(() => '?').join(',') || "''"})`,
  ).all(...permission_codes);
  const insertRolePerm = db.prepare(
    `INSERT OR IGNORE INTO auth_role_permissions(role_id, permission_id, created_at)
     VALUES (?, ?, ?)`,
  );
  permRows.forEach((perm) => insertRolePerm.run(roleId, perm.id, now));
  res.json({ code: 200, message: '角色更新成功', result: { id: roleId } });
});

app.delete('/admin/roles/:id', (req, res) => {
  const session = requirePermission(req, res, 'admin.roles.manage');
  if (!session) return;
  const roleId = Number(req.params.id);
  if (!roleId) {
    return res.status(400).json({ code: 400, message: '角色 id 非法', result: null });
  }
  const role = db.prepare('SELECT * FROM auth_roles WHERE id = ?').get(roleId);
  if (!role) {
    return res.status(404).json({ code: 404, message: '角色不存在', result: null });
  }
  if (role.name === 'admin') {
    return res.status(403).json({ code: 403, message: '不可删除管理员角色', result: null });
  }
  db.prepare('DELETE FROM auth_role_permissions WHERE role_id = ?').run(roleId);
  db.prepare('DELETE FROM auth_user_roles WHERE role_id = ?').run(roleId);
  db.prepare('DELETE FROM auth_roles WHERE id = ?').run(roleId);
  res.json({ code: 200, message: '角色删除成功', result: { id: roleId } });
});

app.get('/admin/users', (req, res) => {
  const session = requirePermission(req, res, 'admin.users.view');
  if (!session) return;
  const limit = Math.max(1, Math.min(200, Number(req.query?.limit || 100)));
  const users = db.prepare(
    `SELECT id, account, phone, email, display_name, role, status, created_at, updated_at
     FROM auth_users ORDER BY id DESC LIMIT ?`,
  ).all(limit);
  const roleRows = db.prepare(
    `SELECT ur.user_id, r.id AS role_id, r.name
     FROM auth_user_roles ur
     JOIN auth_roles r ON r.id = ur.role_id`,
  ).all();
  const roleMap = new Map();
  roleRows.forEach((row) => {
    if (!roleMap.has(row.user_id)) roleMap.set(row.user_id, []);
    roleMap.get(row.user_id).push({ id: row.role_id, name: row.name });
  });
  const result = users.map((user) => ({
    ...user,
    roles: roleMap.get(user.id) || [],
  }));
  res.json({ code: 200, message: 'ok', result });
});

app.post('/admin/users/:id/roles', (req, res) => {
  const session = requirePermission(req, res, 'admin.roles.manage');
  if (!session) return;
  const userId = Number(req.params.id);
  if (!userId) {
    return res.status(400).json({ code: 400, message: '用户 id 非法', result: null });
  }
  const roleIds = Array.isArray(req.body?.role_ids) ? req.body.role_ids : [];
  const roles = db.prepare(
    `SELECT id FROM auth_roles WHERE id IN (${roleIds.map(() => '?').join(',') || "''"})`,
  ).all(...roleIds);
  const now = nowIso();
  db.prepare('DELETE FROM auth_user_roles WHERE user_id = ?').run(userId);
  const insert = db.prepare(
    `INSERT OR IGNORE INTO auth_user_roles(user_id, role_id, created_at)
     VALUES (?, ?, ?)`,
  );
  roles.forEach((role) => insert.run(userId, role.id, now));
  res.json({ code: 200, message: '用户角色更新成功', result: { user_id: userId } });
});

app.get('/admin/bootstrap/status', (req, res) => {
  const admin = db.prepare(
    `SELECT id FROM auth_users WHERE role = 'admin' ORDER BY id ASC LIMIT 1`,
  ).get();
  res.json({ code: 200, message: 'ok', result: { initialized: Boolean(admin) } });
});

app.post('/admin/bootstrap', (req, res) => {
  const { account, password, display_name } = req.body || {};
  const normalizedAccount = normalizeAccount(account);
  const displayName = String(display_name || '').trim();
  if (!isAccount(normalizedAccount)) {
    return res.status(400).json({ code: 400, message: '账号格式非法', result: null });
  }
  if (!isStrongPassword(password)) {
    return res.status(400).json({ code: 400, message: '密码强度不足', result: null });
  }
  if (!displayName) {
    return res.status(400).json({ code: 400, message: 'display_name 不能为空', result: null });
  }
  if (displayName.length > 20) {
    return res.status(400).json({ code: 400, message: 'display_name 长度不能超过 20', result: null });
  }

  try {
    const result = db.transaction(() => {
      const existing = db.prepare(
        `SELECT id FROM auth_users WHERE role = 'admin' ORDER BY id ASC LIMIT 1`,
      ).get();
      if (existing) {
        const error = new Error('admin-exists');
        error.code = 'admin-exists';
        throw error;
      }
      const now = nowIso();
      const info = db.prepare(
        `INSERT INTO auth_users(account, phone, email, wechat_openid, password_hash, display_name, role, status, created_at, updated_at)
         VALUES (?, NULL, NULL, NULL, ?, ?, 'admin', 'active', ?, ?)`,
      ).run(
        normalizedAccount,
        hashPassword(password),
        displayName,
        now,
        now,
      );
      const adminRole = db.prepare('SELECT id FROM auth_roles WHERE name = ?').get('admin');
      if (adminRole) {
        db.prepare(
          'INSERT OR IGNORE INTO auth_user_roles(user_id, role_id, created_at) VALUES (?, ?, ?)',
        ).run(info.lastInsertRowid, adminRole.id, now);
      }
      logEvent('admin_bootstrap_success', {
        account: normalizedAccount,
        user_id: info.lastInsertRowid,
      });
      return { account: normalizedAccount, display_name: displayName };
    })();

    res.json({ code: 200, message: '初始化成功', result });
  } catch (error) {
    if (error?.code === 'admin-exists') {
      return res.status(409).json({ code: 409, message: '管理员已初始化', result: null });
    }
    console.error('[admin] bootstrap failed', error);
    return res.status(500).json({ code: 500, message: '初始化失败', result: null });
  }
});

app.get('/admin/stats/overview', (req, res) => {
  const session = requirePermission(req, res, 'admin.dashboard.view');
  if (!session) return;
  const days = parseRangeDays(req.query?.range);
  const since = rangeStartIso(days);
  const totalUsers = safeNumber(db.prepare('SELECT COUNT(1) AS count FROM auth_users').get().count);
  const newUsers = safeNumber(
    db.prepare('SELECT COUNT(1) AS count FROM auth_users WHERE created_at >= ?').get(since).count,
  );
  const activeUsers = safeNumber(
    db.prepare('SELECT COUNT(DISTINCT user_id) AS count FROM auth_sessions WHERE last_seen_at >= ?')
      .get(since).count,
  );
  const tasksCreated = safeNumber(
    db.prepare('SELECT COUNT(1) AS count FROM tasks WHERE created_at >= ?').get(since).count,
  );
  const tasksCompleted = safeNumber(
    db.prepare('SELECT COUNT(1) AS count FROM tasks WHERE is_done = 1 AND updated_at >= ?')
      .get(since).count,
  );
  const completionRate = tasksCreated ? tasksCompleted / tasksCreated : 0;
  const pointsIssued = safeNumber(
    db.prepare(
      `SELECT SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END) AS total
       FROM point_ledger WHERE created_at >= ?`,
    ).get(since).total,
  );
  const pointsSpent = safeNumber(
    db.prepare(
      `SELECT SUM(CASE WHEN amount < 0 THEN -amount ELSE 0 END) AS total
       FROM point_ledger WHERE created_at >= ?`,
    ).get(since).total,
  );
  const productsPublished = safeNumber(
    db.prepare('SELECT COUNT(1) AS count FROM products WHERE created_at >= ?').get(since).count,
  );
  const exchanges = safeNumber(
    db.prepare('SELECT COUNT(1) AS count FROM owned_items WHERE created_at >= ?').get(since).count,
  );
  const inviteCreated = safeNumber(
    db.prepare('SELECT COUNT(1) AS count FROM auth_invite_codes WHERE created_at >= ?')
      .get(since).count,
  );
  const inviteUsed = safeNumber(
    db.prepare('SELECT COUNT(1) AS count FROM auth_invite_codes WHERE used_at >= ?')
      .get(since).count,
  );
  const inviteConversion = inviteCreated ? inviteUsed / inviteCreated : 0;

  res.json({
    code: 200,
    message: 'ok',
    result: {
      range: `${days}d`,
      since,
      users: {
        total: totalUsers,
        new: newUsers,
        active: activeUsers,
      },
      tasks: {
        created: tasksCreated,
        completed: tasksCompleted,
        completion_rate: completionRate,
      },
      points: {
        issued: pointsIssued,
        spent: pointsSpent,
        net: pointsIssued - pointsSpent,
      },
      store: {
        products: productsPublished,
        exchanges,
      },
      invites: {
        created: inviteCreated,
        used: inviteUsed,
        conversion_rate: inviteConversion,
      },
      updated_at: nowIso(),
    },
  });
});

app.get('/admin/stats/series', (req, res) => {
  const session = requirePermission(req, res, 'admin.dashboard.view');
  if (!session) return;
  const days = parseRangeDays(req.query?.range);
  const since = rangeStartIso(days);
  const series = buildDateSeries(days);

  const userRows = db.prepare(
    `SELECT substr(created_at, 1, 10) AS date, COUNT(1) AS count
     FROM auth_users WHERE created_at >= ? GROUP BY date`,
  ).all(since);
  const taskCreatedRows = db.prepare(
    `SELECT substr(created_at, 1, 10) AS date, COUNT(1) AS count
     FROM tasks WHERE created_at >= ? GROUP BY date`,
  ).all(since);
  const taskDoneRows = db.prepare(
    `SELECT substr(updated_at, 1, 10) AS date, COUNT(1) AS count
     FROM tasks WHERE is_done = 1 AND updated_at >= ? GROUP BY date`,
  ).all(since);
  const pointRows = db.prepare(
    `SELECT substr(created_at, 1, 10) AS date,
            SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END) AS issued,
            SUM(CASE WHEN amount < 0 THEN -amount ELSE 0 END) AS spent
     FROM point_ledger WHERE created_at >= ? GROUP BY date`,
  ).all(since);
  const storeRows = db.prepare(
    `SELECT substr(created_at, 1, 10) AS date, COUNT(1) AS count
     FROM owned_items WHERE created_at >= ? GROUP BY date`,
  ).all(since);

  const userMap = new Map(userRows.map((row) => [row.date, safeNumber(row.count)]));
  const taskCreateMap = new Map(taskCreatedRows.map((row) => [row.date, safeNumber(row.count)]));
  const taskDoneMap = new Map(taskDoneRows.map((row) => [row.date, safeNumber(row.count)]));
  const pointMap = new Map(pointRows.map((row) => [
    row.date,
    { issued: safeNumber(row.issued), spent: safeNumber(row.spent) },
  ]));
  const storeMap = new Map(storeRows.map((row) => [row.date, safeNumber(row.count)]));

  const resultSeries = series.map((date) => {
    const points = pointMap.get(date) || { issued: 0, spent: 0 };
    return {
      date,
      users_new: userMap.get(date) || 0,
      tasks_created: taskCreateMap.get(date) || 0,
      tasks_completed: taskDoneMap.get(date) || 0,
      points_issued: points.issued,
      points_spent: points.spent,
      store_exchanges: storeMap.get(date) || 0,
    };
  });

  res.json({
    code: 200,
    message: 'ok',
    result: {
      range: `${days}d`,
      series: resultSeries,
    },
  });
});

app.get('/admin/stats/tasks', (req, res) => {
  const session = requirePermission(req, res, 'admin.tasks.view');
  if (!session) return;
  const days = parseRangeDays(req.query?.range);
  const since = rangeStartIso(days);
  const created = safeNumber(
    db.prepare('SELECT COUNT(1) AS count FROM tasks WHERE created_at >= ?').get(since).count,
  );
  const completed = safeNumber(
    db.prepare('SELECT COUNT(1) AS count FROM tasks WHERE is_done = 1 AND updated_at >= ?')
      .get(since).count,
  );
  const completionRate = created ? completed / created : 0;
  const quadrantRows = db.prepare(
    `SELECT quadrant, COUNT(1) AS count
     FROM tasks WHERE created_at >= ? GROUP BY quadrant`,
  ).all(since);
  const quadrantMap = new Map(quadrantRows.map((row) => [Number(row.quadrant), safeNumber(row.count)]));
  const quadrant = [1, 2, 3, 4].map((value) => ({ quadrant: value, count: quadrantMap.get(value) || 0 }));
  const repeatCount = safeNumber(
    db.prepare(
      `SELECT COUNT(1) AS count FROM tasks
       WHERE created_at >= ? AND repeat_type != 'none'`,
    ).get(since).count,
  );
  const repeatRatio = created ? repeatCount / created : 0;

  res.json({
    code: 200,
    message: 'ok',
    result: {
      range: `${days}d`,
      created,
      completed,
      completion_rate: completionRate,
      quadrant,
      repeat: {
        count: repeatCount,
        ratio: repeatRatio,
      },
    },
  });
});

app.get('/admin/stats/points', (req, res) => {
  const session = requirePermission(req, res, 'admin.points.view');
  if (!session) return;
  const days = parseRangeDays(req.query?.range);
  const since = rangeStartIso(days);
  const issued = safeNumber(
    db.prepare(
      `SELECT SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END) AS total
       FROM point_ledger WHERE created_at >= ?`,
    ).get(since).total,
  );
  const spent = safeNumber(
    db.prepare(
      `SELECT SUM(CASE WHEN amount < 0 THEN -amount ELSE 0 END) AS total
       FROM point_ledger WHERE created_at >= ?`,
    ).get(since).total,
  );
  const balanceTotal = safeNumber(
    db.prepare('SELECT SUM(points) AS total FROM point_wallets').get().total,
  );
  const walletCount = safeNumber(
    db.prepare('SELECT COUNT(1) AS count FROM point_wallets').get().count,
  );
  const topReasons = db.prepare(
    `SELECT reason,
            SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END) AS issued,
            SUM(CASE WHEN amount < 0 THEN -amount ELSE 0 END) AS spent,
            COUNT(1) AS count
     FROM point_ledger WHERE created_at >= ?
     GROUP BY reason
     ORDER BY (issued + spent) DESC
     LIMIT 10`,
  ).all(since).map((row) => ({
    reason: row.reason,
    issued: safeNumber(row.issued),
    spent: safeNumber(row.spent),
    count: safeNumber(row.count),
  }));

  res.json({
    code: 200,
    message: 'ok',
    result: {
      range: `${days}d`,
      issued,
      spent,
      net: issued - spent,
      balance_total: balanceTotal,
      balance_avg: walletCount ? balanceTotal / walletCount : 0,
      top_reasons: topReasons,
    },
  });
});

app.get('/admin/stats/store', (req, res) => {
  const session = requirePermission(req, res, 'admin.store.view');
  if (!session) return;
  const days = parseRangeDays(req.query?.range);
  const since = rangeStartIso(days);
  const productsPublished = safeNumber(
    db.prepare('SELECT COUNT(1) AS count FROM products WHERE created_at >= ?').get(since).count,
  );
  const productsTotal = safeNumber(
    db.prepare('SELECT COUNT(1) AS count FROM products').get().count,
  );
  const stockTotal = safeNumber(
    db.prepare('SELECT SUM(stock) AS total FROM products').get().total,
  );
  const exchanges = safeNumber(
    db.prepare('SELECT COUNT(1) AS count FROM owned_items WHERE created_at >= ?').get(since).count,
  );
  const topProducts = db.prepare(
    `SELECT oi.product_id,
            oi.product_name,
            COUNT(1) AS exchanges,
            SUM(oi.points_spent) AS points_spent,
            COALESCE(p.stock, 0) AS stock
     FROM owned_items oi
     LEFT JOIN products p ON p.id = oi.product_id
     WHERE oi.created_at >= ?
     GROUP BY oi.product_id, oi.product_name, p.stock
     ORDER BY exchanges DESC, points_spent DESC
     LIMIT 10`,
  ).all(since).map((row) => ({
    product_id: row.product_id,
    name: row.product_name,
    exchanges: safeNumber(row.exchanges),
    points_spent: safeNumber(row.points_spent),
    stock: safeNumber(row.stock),
  }));

  res.json({
    code: 200,
    message: 'ok',
    result: {
      range: `${days}d`,
      products_published: productsPublished,
      products_total: productsTotal,
      stock_total: stockTotal,
      exchanges,
      top_products: topProducts,
    },
  });
});

app.get('/admin/stats/invite', (req, res) => {
  const session = requirePermission(req, res, 'admin.invites.view');
  if (!session) return;
  const days = parseRangeDays(req.query?.range);
  const since = rangeStartIso(days);
  const created = safeNumber(
    db.prepare('SELECT COUNT(1) AS count FROM auth_invite_codes WHERE created_at >= ?')
      .get(since).count,
  );
  const used = safeNumber(
    db.prepare('SELECT COUNT(1) AS count FROM auth_invite_codes WHERE used_at >= ?')
      .get(since).count,
  );
  const statusRows = db.prepare(
    `SELECT status, COUNT(1) AS count FROM auth_invite_codes GROUP BY status`,
  ).all();
  const statusMap = new Map(statusRows.map((row) => [row.status, safeNumber(row.count)]));

  res.json({
    code: 200,
    message: 'ok',
    result: {
      range: `${days}d`,
      created,
      used,
      status: {
        active: statusMap.get('active') || 0,
        disabled: statusMap.get('disabled') || 0,
        exhausted: statusMap.get('exhausted') || 0,
      },
    },
  });
});

app.get('/admin/security/events', (req, res) => {
  const session = requirePermission(req, res, 'admin.security.view');
  if (!session) return;
  const days = parseRangeDays(req.query?.range);
  const since = rangeStartIso(days);
  const limit = Math.max(1, Math.min(200, Number(req.query?.limit || 50)));
  const total = safeNumber(
    db.prepare('SELECT COUNT(1) AS count FROM auth_security_events WHERE created_at >= ?')
      .get(since).count,
  );
  const failed = safeNumber(
    db.prepare(
      `SELECT COUNT(1) AS count FROM auth_security_events
       WHERE created_at >= ? AND success = 0`,
    ).get(since).count,
  );
  const lockedUsers = safeNumber(
    db.prepare(
      `SELECT COUNT(1) AS count FROM auth_users
       WHERE locked_until IS NOT NULL AND locked_until > ?`,
    ).get(nowIso()).count,
  );
  const events = db.prepare(
    `SELECT id, action, phone, email, client_key, success, detail, created_at
     FROM auth_security_events
     WHERE created_at >= ?
     ORDER BY id DESC LIMIT ?`,
  ).all(since, limit);

  res.json({
    code: 200,
    message: 'ok',
    result: {
      range: `${days}d`,
      total,
      failed,
      locked_users: lockedUsers,
      events,
    },
  });
});

app.get('/admin/settings', (req, res) => {
  const session = requirePermission(req, res, 'admin.settings.view');
  if (!session) return;
  const adminUser = db.prepare(
    `SELECT account, display_name FROM auth_users WHERE role = 'admin' ORDER BY id ASC LIMIT 1`,
  ).get();
  res.json({
    code: 200,
    message: 'ok',
    result: {
      sms_provider: String(process.env.SMS_PROVIDER || 'mock'),
      email_provider: String(process.env.EMAIL_PROVIDER || 'mock'),
      admin_account: adminUser?.account || null,
      admin_display_name: adminUser?.display_name || null,
      server_time: nowIso(),
      db_path: String(process.env.DB_PATH || 'default'),
      node_env: String(process.env.NODE_ENV || 'development'),
    },
  });
});

app.post('/auth/email/send-code', (req, res) => {
  const { email, purpose = 'login' } = req.body || {};
  const normalizedEmail = normalizeEmail(email);
  const normalizedPurpose = normalizeAuthPurpose(purpose);
  const clientKey = getClientKey(req);
  if (!isEmail(normalizedEmail)) {
    writeAuthEvent({
      action: 'send_email_code_invalid',
      email: normalizedEmail || null,
      clientKey,
      success: 0,
      detail: 'email-invalid',
    });
    return res.status(400).json({ code: 400, message: '邮箱格式非法', result: null });
  }

  const now = Date.now();
  const recent = db.prepare(
    `SELECT created_at FROM auth_email_codes
     WHERE email = ? ORDER BY id DESC LIMIT 1`,
  ).get(normalizedEmail);
  if (recent) {
    const diffMs = now - new Date(recent.created_at).getTime();
    if (diffMs < 60 * 1000) {
      writeAuthEvent({
        action: 'send_email_code_throttled',
        email: normalizedEmail,
        clientKey,
        success: 0,
        detail: 'cooldown-60s',
      });
      return res.status(429).json({ code: 429, message: '请求过于频繁，请稍后重试', result: null });
    }
  }

  const emailCount10m = countRecentAuthEvents({
    action: 'send_email_code_success',
    email: normalizedEmail,
    windowSeconds: 10 * 60,
  });
  if (emailCount10m >= 5) {
    writeAuthEvent({
      action: 'send_email_code_throttled',
      email: normalizedEmail,
      clientKey,
      success: 0,
      detail: 'email-limit-10m',
    });
    return res.status(429).json({ code: 429, message: '发送过于频繁，请 10 分钟后再试', result: null });
  }
  const clientCount10m = countRecentAuthEvents({
    action: 'send_email_code_success',
    clientKey,
    windowSeconds: 10 * 60,
  });
  if (clientCount10m >= 12) {
    writeAuthEvent({
      action: 'send_email_code_throttled',
      email: normalizedEmail,
      clientKey,
      success: 0,
      detail: 'client-limit-10m',
    });
    return res.status(429).json({ code: 429, message: '当前设备请求过多，请稍后重试', result: null });
  }

  const code = createPhoneCode();
  const createdAt = new Date(now).toISOString();
  const expiresAt = new Date(now + 5 * 60 * 1000).toISOString();
  db.prepare(
    `INSERT INTO auth_email_codes(email, code, purpose, expires_at, used_at, created_at)
     VALUES (?, ?, ?, ?, NULL, ?)`,
  ).run(normalizedEmail, code, normalizedPurpose, expiresAt, createdAt);

  emailProvider
    .sendCode({
      email: normalizedEmail,
      code,
      purpose: normalizedPurpose,
    })
    .then(() => {
      const result = {
        email: normalizedEmail,
        purpose: normalizedPurpose,
        expires_at: expiresAt,
        ttl_seconds: 300,
      };
      if (shouldExposeDebugCode()) {
        result.debug_code = code;
      }
      writeAuthEvent({
        action: 'send_email_code_success',
        email: normalizedEmail,
        clientKey,
        success: 1,
        detail: normalizedPurpose,
      });
      res.json({ code: 200, message: '验证码发送成功', result });
    })
    .catch((error) => {
      writeAuthEvent({
        action: 'send_email_code_provider_fail',
        email: normalizedEmail,
        clientKey,
        success: 0,
        detail: String(error.message || 'provider-error'),
      });
      res.status(500).json({ code: 500, message: '邮件发送失败', result: null });
    });
});

app.post('/auth/phone/send-code', (req, res) => {
  const { phone, purpose = 'login' } = req.body || {};
  const normalizedPhone = String(phone || '').trim();
  const normalizedPurpose = normalizeAuthPurpose(purpose);
  const clientKey = getClientKey(req);
  if (!isPhone(normalizedPhone)) {
    writeAuthEvent({
      action: 'send_code_invalid',
      phone: normalizedPhone || null,
      clientKey,
      success: 0,
      detail: 'phone-invalid',
    });
    return res.status(400).json({ code: 400, message: '手机号格式非法', result: null });
  }

  const now = Date.now();
  const recent = db.prepare(
    `SELECT created_at FROM auth_phone_codes
     WHERE phone = ? ORDER BY id DESC LIMIT 1`,
  ).get(normalizedPhone);
  if (recent) {
    const diffMs = now - new Date(recent.created_at).getTime();
    if (diffMs < 60 * 1000) {
      writeAuthEvent({
        action: 'send_code_throttled',
        phone: normalizedPhone,
        clientKey,
        success: 0,
        detail: 'cooldown-60s',
      });
      return res.status(429).json({ code: 429, message: '请求过于频繁，请稍后重试', result: null });
    }
  }

  const phoneCount10m = countRecentAuthEvents({
    action: 'send_code_success',
    phone: normalizedPhone,
    windowSeconds: 10 * 60,
  });
  if (phoneCount10m >= 5) {
    writeAuthEvent({
      action: 'send_code_throttled',
      phone: normalizedPhone,
      clientKey,
      success: 0,
      detail: 'phone-limit-10m',
    });
    return res.status(429).json({ code: 429, message: '发送过于频繁，请 10 分钟后再试', result: null });
  }
  const clientCount10m = countRecentAuthEvents({
    action: 'send_code_success',
    clientKey,
    windowSeconds: 10 * 60,
  });
  if (clientCount10m >= 12) {
    writeAuthEvent({
      action: 'send_code_throttled',
      phone: normalizedPhone,
      clientKey,
      success: 0,
      detail: 'client-limit-10m',
    });
    return res.status(429).json({ code: 429, message: '当前设备请求过多，请稍后重试', result: null });
  }

  const code = createPhoneCode();
  const createdAt = new Date(now).toISOString();
  const expiresAt = new Date(now + 5 * 60 * 1000).toISOString();
  db.prepare(
    `INSERT INTO auth_phone_codes(phone, code, purpose, expires_at, used_at, created_at)
     VALUES (?, ?, ?, ?, NULL, ?)`,
  ).run(normalizedPhone, code, normalizedPurpose, expiresAt, createdAt);
  writeAuthEvent({
    action: 'send_code_success',
    phone: normalizedPhone,
    clientKey,
    success: 1,
    detail: normalizedPurpose,
  });

  smsProvider
    .sendCode({
      phone: normalizedPhone,
      code,
      purpose: normalizedPurpose,
    })
    .then(() => {
      const result = {
        phone: normalizedPhone,
        purpose: normalizedPurpose,
        expires_at: expiresAt,
        ttl_seconds: 300,
      };
      if (shouldExposeDebugCode()) {
        result.debug_code = code;
      }
      res.json({
        code: 200,
        message: '验证码发送成功',
        result,
      });
    })
    .catch((error) => {
      writeAuthEvent({
        action: 'send_code_provider_fail',
        phone: normalizedPhone,
        clientKey,
        success: 0,
        detail: String(error.message || 'provider-error'),
      });
      res.status(500).json({ code: 500, message: '短信发送失败', result: null });
    });
});

app.post('/auth/login/phone-code', (req, res) => {
  const { phone, code } = req.body || {};
  const normalizedPhone = String(phone || '').trim();
  const normalizedCode = String(code || '').trim();
  const clientKey = getClientKey(req);
  if (!isPhone(normalizedPhone) || !isValidCode(normalizedCode)) {
    writeAuthEvent({
      action: 'login_phone_code_invalid',
      phone: normalizedPhone || null,
      clientKey,
      success: 0,
      detail: 'format-invalid',
    });
    return res.status(400).json({ code: 400, message: '手机号或验证码格式非法', result: null });
  }

  const clientRecentFails = countRecentAuthEvents({
    action: 'login_phone_code_fail',
    clientKey,
    windowSeconds: 10 * 60,
  });
  if (clientRecentFails >= 20) {
    return res.status(429).json({ code: 429, message: '尝试次数过多，请稍后再试', result: null });
  }

  const userForPhone = db.prepare('SELECT * FROM auth_users WHERE phone = ? AND status = ?')
    .get(normalizedPhone, 'active');
  if (userForPhone && userForPhone.locked_until && new Date(userForPhone.locked_until).getTime() > Date.now()) {
    return res.status(423).json({ code: 423, message: '账号已临时锁定，请稍后再试', result: null });
  }

  const row = db.prepare(
    `SELECT * FROM auth_phone_codes
     WHERE phone = ? AND code = ? AND purpose = 'login' AND used_at IS NULL
     ORDER BY id DESC LIMIT 1`,
  ).get(normalizedPhone, normalizedCode);
  if (!row) {
    if (userForPhone) {
      const nextFail = (Number(userForPhone.failed_login_count) || 0) + 1;
      const lockUntil = nextFail >= 5
        ? new Date(Date.now() + 15 * 60 * 1000).toISOString()
        : null;
      db.prepare(
        'UPDATE auth_users SET failed_login_count = ?, locked_until = ?, updated_at = ? WHERE id = ?',
      ).run(nextFail, lockUntil, nowIso(), userForPhone.id);
    }
    writeAuthEvent({
      action: 'login_phone_code_fail',
      phone: normalizedPhone,
      clientKey,
      success: 0,
      detail: 'code-mismatch',
    });
    return res.status(401).json({ code: 401, message: '验证码错误', result: null });
  }
  if (new Date(row.expires_at).getTime() < Date.now()) {
    if (userForPhone) {
      const nextFail = (Number(userForPhone.failed_login_count) || 0) + 1;
      const lockUntil = nextFail >= 5
        ? new Date(Date.now() + 15 * 60 * 1000).toISOString()
        : null;
      db.prepare(
        'UPDATE auth_users SET failed_login_count = ?, locked_until = ?, updated_at = ? WHERE id = ?',
      ).run(nextFail, lockUntil, nowIso(), userForPhone.id);
    }
    writeAuthEvent({
      action: 'login_phone_code_fail',
      phone: normalizedPhone,
      clientKey,
      success: 0,
      detail: 'code-expired',
    });
    return res.status(401).json({ code: 401, message: '验证码已过期', result: null });
  }

  if (!userForPhone) {
    writeAuthEvent({
      action: 'login_phone_code_fail',
      phone: normalizedPhone,
      clientKey,
      success: 0,
      detail: 'user-not-found',
    });
    return res.status(404).json({ code: 404, message: '手机号未注册', result: null });
  }

  const now = new Date();
  const token = createSessionToken();
  const expires = new Date(now.getTime() + 1000 * 60 * 60 * 24 * 30).toISOString();
  db.prepare('UPDATE auth_phone_codes SET used_at = ? WHERE id = ?').run(now.toISOString(), row.id);
  db.prepare(
    'UPDATE auth_users SET failed_login_count = 0, locked_until = NULL, updated_at = ? WHERE id = ?',
  ).run(now.toISOString(), userForPhone.id);
  db.prepare(
    `INSERT INTO auth_sessions(token, user_id, provider, owner_hint, expires_at, created_at, last_seen_at)
     VALUES (?, ?, 'phone_code', 'me', ?, ?, ?)`,
  ).run(token, userForPhone.id, expires, now.toISOString(), now.toISOString());
  writeAuthEvent({
    action: 'login_phone_code_success',
    phone: normalizedPhone,
    clientKey,
    success: 1,
    detail: 'ok',
  });

  res.json({
    code: 200,
    message: '验证码登录成功',
    result: {
      token,
      provider: 'phone_code',
      expires_at: expires,
      user: {
        id: userForPhone.id,
        phone: userForPhone.phone,
        account: userForPhone.account,
        role: userForPhone.role,
        roles: getUserRoles(userForPhone.id),
        permissions: getUserPermissions(userForPhone.id),
        display_name: userForPhone.display_name,
        status: userForPhone.status,
      },
    },
  });
});

app.post('/auth/login/email-code', (req, res) => {
  const { email, code } = req.body || {};
  const normalizedEmail = normalizeEmail(email);
  const normalizedCode = String(code || '').trim();
  const clientKey = getClientKey(req);
  if (!isEmail(normalizedEmail) || !isValidCode(normalizedCode)) {
    writeAuthEvent({
      action: 'login_email_code_invalid',
      email: normalizedEmail || null,
      clientKey,
      success: 0,
      detail: 'format-invalid',
    });
    return res.status(400).json({ code: 400, message: '邮箱或验证码格式非法', result: null });
  }

  const clientRecentFails = countRecentAuthEvents({
    action: 'login_email_code_fail',
    clientKey,
    windowSeconds: 10 * 60,
  });
  if (clientRecentFails >= 20) {
    return res.status(429).json({ code: 429, message: '尝试次数过多，请稍后再试', result: null });
  }

  const userForEmail = db.prepare('SELECT * FROM auth_users WHERE email = ? AND status = ?')
    .get(normalizedEmail, 'active');
  if (userForEmail && userForEmail.locked_until && new Date(userForEmail.locked_until).getTime() > Date.now()) {
    return res.status(423).json({ code: 423, message: '账号已临时锁定，请稍后再试', result: null });
  }

  const row = db.prepare(
    `SELECT * FROM auth_email_codes
     WHERE email = ? AND code = ? AND purpose = 'login' AND used_at IS NULL
     ORDER BY id DESC LIMIT 1`,
  ).get(normalizedEmail, normalizedCode);
  if (!row) {
    if (userForEmail) {
      const nextFail = (Number(userForEmail.failed_login_count) || 0) + 1;
      const lockUntil = nextFail >= 5
        ? new Date(Date.now() + 15 * 60 * 1000).toISOString()
        : null;
      db.prepare(
        'UPDATE auth_users SET failed_login_count = ?, locked_until = ?, updated_at = ? WHERE id = ?',
      ).run(nextFail, lockUntil, nowIso(), userForEmail.id);
    }
    writeAuthEvent({
      action: 'login_email_code_fail',
      email: normalizedEmail,
      clientKey,
      success: 0,
      detail: 'code-mismatch',
    });
    return res.status(401).json({ code: 401, message: '验证码错误', result: null });
  }
  if (new Date(row.expires_at).getTime() < Date.now()) {
    if (userForEmail) {
      const nextFail = (Number(userForEmail.failed_login_count) || 0) + 1;
      const lockUntil = nextFail >= 5
        ? new Date(Date.now() + 15 * 60 * 1000).toISOString()
        : null;
      db.prepare(
        'UPDATE auth_users SET failed_login_count = ?, locked_until = ?, updated_at = ? WHERE id = ?',
      ).run(nextFail, lockUntil, nowIso(), userForEmail.id);
    }
    writeAuthEvent({
      action: 'login_email_code_fail',
      email: normalizedEmail,
      clientKey,
      success: 0,
      detail: 'code-expired',
    });
    return res.status(401).json({ code: 401, message: '验证码已过期', result: null });
  }

  if (!userForEmail) {
    writeAuthEvent({
      action: 'login_email_code_fail',
      email: normalizedEmail,
      clientKey,
      success: 0,
      detail: 'user-not-found',
    });
    return res.status(404).json({ code: 404, message: '邮箱未注册', result: null });
  }

  const now = new Date();
  const token = createSessionToken();
  const expires = new Date(now.getTime() + 1000 * 60 * 60 * 24 * 30).toISOString();
  db.prepare('UPDATE auth_email_codes SET used_at = ? WHERE id = ?').run(now.toISOString(), row.id);
  db.prepare(
    'UPDATE auth_users SET failed_login_count = 0, locked_until = NULL, updated_at = ? WHERE id = ?',
  ).run(now.toISOString(), userForEmail.id);
  db.prepare(
    `INSERT INTO auth_sessions(token, user_id, provider, owner_hint, expires_at, created_at, last_seen_at)
     VALUES (?, ?, 'email_code', 'me', ?, ?, ?)`,
  ).run(token, userForEmail.id, expires, now.toISOString(), now.toISOString());
  writeAuthEvent({
    action: 'login_email_code_success',
    email: normalizedEmail,
    clientKey,
    success: 1,
    detail: 'ok',
  });

  res.json({
    code: 200,
    message: '验证码登录成功',
    result: {
      token,
      provider: 'email_code',
      expires_at: expires,
      user: {
        id: userForEmail.id,
        email: userForEmail.email,
        account: userForEmail.account,
        role: userForEmail.role,
        roles: getUserRoles(userForEmail.id),
        permissions: getUserPermissions(userForEmail.id),
        display_name: userForEmail.display_name,
        status: userForEmail.status,
      },
    },
  });
});

app.post('/auth/register/phone-code', (req, res) => {
  const { phone, code, display_name = '新用户', password = null } = req.body || {};
  const normalizedPhone = String(phone || '').trim();
  const normalizedCode = String(code || '').trim();
  const clientKey = getClientKey(req);
  if (!isPhone(normalizedPhone) || !isValidCode(normalizedCode)) {
    writeAuthEvent({
      action: 'register_phone_code_invalid',
      phone: normalizedPhone || null,
      clientKey,
      success: 0,
      detail: 'format-invalid',
    });
    return res.status(400).json({ code: 400, message: '手机号或验证码格式非法', result: null });
  }

  const exists = db.prepare('SELECT id FROM auth_users WHERE phone = ?').get(normalizedPhone);
  if (exists) {
    writeAuthEvent({
      action: 'register_phone_code_fail',
      phone: normalizedPhone,
      clientKey,
      success: 0,
      detail: 'phone-exists',
    });
    return res.status(409).json({ code: 409, message: '手机号已注册', result: null });
  }

  const row = db.prepare(
    `SELECT * FROM auth_phone_codes
     WHERE phone = ? AND code = ? AND purpose = 'register' AND used_at IS NULL
     ORDER BY id DESC LIMIT 1`,
  ).get(normalizedPhone, normalizedCode);
  if (!row) {
    writeAuthEvent({
      action: 'register_phone_code_fail',
      phone: normalizedPhone,
      clientKey,
      success: 0,
      detail: 'code-mismatch',
    });
    return res.status(401).json({ code: 401, message: '验证码错误', result: null });
  }
  if (new Date(row.expires_at).getTime() < Date.now()) {
    writeAuthEvent({
      action: 'register_phone_code_fail',
      phone: normalizedPhone,
      clientKey,
      success: 0,
      detail: 'code-expired',
    });
    return res.status(401).json({ code: 401, message: '验证码已过期', result: null });
  }

  const now = new Date();
  const nowIso = now.toISOString();
  const info = db.prepare(
    `INSERT INTO auth_users(phone, password_hash, display_name, status, created_at, updated_at)
     VALUES (?, ?, ?, 'active', ?, ?)`,
  ).run(
    normalizedPhone,
    isStrongPassword(password) ? hashPassword(password) : null,
    String(display_name || '新用户').trim(),
    nowIso,
    nowIso,
  );
  db.prepare('UPDATE auth_phone_codes SET used_at = ? WHERE id = ?').run(nowIso, row.id);

  const user = db.prepare('SELECT * FROM auth_users WHERE id = ?').get(info.lastInsertRowid);
  const token = createSessionToken();
  const expires = new Date(now.getTime() + 1000 * 60 * 60 * 24 * 30).toISOString();
  db.prepare(
    `INSERT INTO auth_sessions(token, user_id, provider, owner_hint, expires_at, created_at, last_seen_at)
     VALUES (?, ?, 'phone_code', 'me', ?, ?, ?)`,
  ).run(token, user.id, expires, nowIso, nowIso);
  writeAuthEvent({
    action: 'register_phone_code_success',
    phone: normalizedPhone,
    clientKey,
    success: 1,
    detail: 'ok',
  });

  res.json({
    code: 200,
    message: '验证码注册成功',
    result: {
      token,
      provider: 'phone_code',
      expires_at: expires,
      user: {
        id: user.id,
        phone: user.phone,
        account: user.account,
        role: user.role,
        roles: getUserRoles(user.id),
        permissions: getUserPermissions(user.id),
        display_name: user.display_name,
        status: user.status,
      },
    },
  });
});

app.post('/auth/register/email-code', (req, res) => {
  const { email, code, display_name = '新用户', password = null } = req.body || {};
  const normalizedEmail = normalizeEmail(email);
  const normalizedCode = String(code || '').trim();
  const clientKey = getClientKey(req);
  if (!isEmail(normalizedEmail) || !isValidCode(normalizedCode)) {
    writeAuthEvent({
      action: 'register_email_code_invalid',
      email: normalizedEmail || null,
      clientKey,
      success: 0,
      detail: 'format-invalid',
    });
    return res.status(400).json({ code: 400, message: '邮箱或验证码格式非法', result: null });
  }

  const exists = db.prepare('SELECT id FROM auth_users WHERE email = ?').get(normalizedEmail);
  if (exists) {
    writeAuthEvent({
      action: 'register_email_code_fail',
      email: normalizedEmail,
      clientKey,
      success: 0,
      detail: 'email-exists',
    });
    return res.status(409).json({ code: 409, message: '邮箱已注册', result: null });
  }

  const row = db.prepare(
    `SELECT * FROM auth_email_codes
     WHERE email = ? AND code = ? AND purpose = 'register' AND used_at IS NULL
     ORDER BY id DESC LIMIT 1`,
  ).get(normalizedEmail, normalizedCode);
  if (!row) {
    writeAuthEvent({
      action: 'register_email_code_fail',
      email: normalizedEmail,
      clientKey,
      success: 0,
      detail: 'code-mismatch',
    });
    return res.status(401).json({ code: 401, message: '验证码错误', result: null });
  }
  if (new Date(row.expires_at).getTime() < Date.now()) {
    writeAuthEvent({
      action: 'register_email_code_fail',
      email: normalizedEmail,
      clientKey,
      success: 0,
      detail: 'code-expired',
    });
    return res.status(401).json({ code: 401, message: '验证码已过期', result: null });
  }

  const now = new Date();
  const nowIso = now.toISOString();
  const info = db.prepare(
    `INSERT INTO auth_users(phone, email, password_hash, display_name, status, created_at, updated_at)
     VALUES (NULL, ?, ?, ?, 'active', ?, ?)`,
  ).run(
    normalizedEmail,
    isStrongPassword(password) ? hashPassword(password) : null,
    String(display_name || '新用户').trim(),
    nowIso,
    nowIso,
  );
  db.prepare('UPDATE auth_email_codes SET used_at = ? WHERE id = ?').run(nowIso, row.id);

  const user = db.prepare('SELECT * FROM auth_users WHERE id = ?').get(info.lastInsertRowid);
  const token = createSessionToken();
  const expires = new Date(now.getTime() + 1000 * 60 * 60 * 24 * 30).toISOString();
  db.prepare(
    `INSERT INTO auth_sessions(token, user_id, provider, owner_hint, expires_at, created_at, last_seen_at)
     VALUES (?, ?, 'email_code', 'me', ?, ?, ?)`,
  ).run(token, user.id, expires, nowIso, nowIso);
  writeAuthEvent({
    action: 'register_email_code_success',
    email: normalizedEmail,
    clientKey,
    success: 1,
    detail: 'ok',
  });

  res.json({
    code: 200,
    message: '验证码注册成功',
    result: {
      token,
      provider: 'email_code',
      expires_at: expires,
      user: {
        id: user.id,
        email: user.email,
        account: user.account,
        role: user.role,
        roles: getUserRoles(user.id),
        permissions: getUserPermissions(user.id),
        display_name: user.display_name,
        status: user.status,
      },
    },
  });
});

app.get('/auth/session', (req, res) => {
  const token = String(req.query.token || '').trim();
  if (!token) {
    return res.status(400).json({ code: 400, message: 'token 不能为空', result: null });
  }
  const session = db.prepare(
    `SELECT s.token, s.provider, s.owner_hint, s.expires_at, s.user_id,
            u.display_name, u.phone, u.email, u.account, u.role, u.wechat_openid, u.status
     FROM auth_sessions s
     JOIN auth_users u ON u.id = s.user_id
     WHERE s.token = ?`,
  ).get(token);
  if (!session) {
    return res.status(404).json({ code: 404, message: '会话不存在', result: null });
  }
  if (new Date(session.expires_at).getTime() < Date.now()) {
    db.prepare('DELETE FROM auth_sessions WHERE token = ?').run(token);
    return res.status(401).json({ code: 401, message: '会话已过期', result: null });
  }
  db.prepare('UPDATE auth_sessions SET last_seen_at = ? WHERE token = ?').run(
    new Date().toISOString(),
    token,
  );
  res.json({
    code: 200,
    message: '会话有效',
    result: {
      token: session.token,
      provider: session.provider,
      owner_hint: session.owner_hint,
      expires_at: session.expires_at,
      user: {
        id: session.user_id,
        display_name: session.display_name,
        phone: session.phone,
        email: session.email,
        account: session.account,
        role: session.role,
        roles: getUserRoles(session.user_id),
        permissions: getUserPermissions(session.user_id),
        wechat_openid: session.wechat_openid,
        status: session.status,
      },
    },
  });
});

app.post('/auth/logout', (req, res) => {
  const token = String(req.body?.token || '').trim();
  if (!token) {
    return res.status(400).json({ code: 400, message: 'token 不能为空', result: null });
  }
  db.prepare('DELETE FROM auth_sessions WHERE token = ?').run(token);
  res.json({ code: 200, message: '退出成功', result: { token } });
});

app.get('/export/snapshot', (req, res) => {
  const now = new Date().toISOString();
  const result = {
    exported_at: now,
    tasks: db.prepare('SELECT * FROM tasks ORDER BY id DESC').all(),
    points: db.prepare('SELECT * FROM point_wallets ORDER BY owner ASC').all(),
    ledger: db.prepare('SELECT * FROM point_ledger ORDER BY id DESC').all(),
    products: db.prepare('SELECT * FROM products ORDER BY id DESC').all(),
    owned_items: db.prepare('SELECT * FROM owned_items ORDER BY id DESC').all(),
    feedback_items: db.prepare('SELECT * FROM feedback_items ORDER BY id DESC').all(),
    profiles: db.prepare('SELECT * FROM profiles ORDER BY owner ASC').all(),
    settings: db.prepare('SELECT * FROM app_settings ORDER BY owner ASC').all(),
    notifications: db.prepare('SELECT * FROM notifications ORDER BY id DESC').all(),
    auth_users: db.prepare('SELECT id, account, phone, email, wechat_openid, display_name, role, status, failed_login_count, locked_until, created_at, updated_at FROM auth_users ORDER BY id DESC').all(),
    auth_sessions: db.prepare('SELECT token, user_id, provider, owner_hint, expires_at, created_at, last_seen_at FROM auth_sessions ORDER BY created_at DESC').all(),
    auth_security_events: db.prepare('SELECT * FROM auth_security_events ORDER BY id DESC LIMIT 500').all(),
    auth_email_codes: db.prepare('SELECT * FROM auth_email_codes ORDER BY id DESC LIMIT 200').all(),
    auth_invite_codes: db.prepare('SELECT * FROM auth_invite_codes ORDER BY id DESC LIMIT 500').all(),
    auth_roles: db.prepare('SELECT * FROM auth_roles ORDER BY id ASC').all(),
    auth_permissions: db.prepare('SELECT * FROM auth_permissions ORDER BY id ASC').all(),
    auth_role_permissions: db.prepare('SELECT * FROM auth_role_permissions ORDER BY role_id ASC').all(),
    auth_user_roles: db.prepare('SELECT * FROM auth_user_roles ORDER BY user_id ASC').all(),
  };
  res.json({ code: 200, message: '导出快照成功', result });
});

const adminDist = path.join(__dirname, '..', 'public', 'admin');
if (fs.existsSync(adminDist)) {
  app.use('/admin', express.static(adminDist));
  app.get('/admin/*', (req, res) => {
    res.sendFile(path.join(adminDist, 'index.html'));
  });
}

const host = process.env.HOST || '0.0.0.0';
const socketPath = process.env.LISTEN_SOCKET || '';
const isSocketPath = socketPath.startsWith('/') || socketPath.endsWith('.sock');
if (isSocketPath) {
  app.listen(socketPath, () => {
    console.log(`[priority_first_backend] running at unix:${socketPath}`);
  });
} else {
  app.listen(port, host, () => {
    console.log(`[priority_first_backend] running at http://${host}:${port}`);
  });
}
