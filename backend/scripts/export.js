const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const Database = require('better-sqlite3');

function nowStamp() {
  const d = new Date();
  const pad = (value) => String(value).padStart(2, '0');
  return `${d.getFullYear()}${pad(d.getMonth() + 1)}${pad(d.getDate())}-${pad(d.getHours())}${pad(d.getMinutes())}${pad(d.getSeconds())}`;
}

function resolveOutputPath() {
  const args = process.argv.slice(2);
  const outIndex = args.findIndex((arg) => arg === '--out');
  if (outIndex >= 0 && args[outIndex + 1]) {
    return path.resolve(args[outIndex + 1]);
  }
  const inline = args.find((arg) => arg.startsWith('--out='));
  if (inline) {
    return path.resolve(inline.split('=')[1]);
  }
  const dir = path.join(__dirname, '..', 'exports');
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
  return path.join(dir, `snapshot-${nowStamp()}.json`);
}

const dbPath = process.env.DB_PATH || path.join(__dirname, '..', 'data', 'priority_first.db');
const db = new Database(dbPath);
db.pragma('journal_mode = WAL');

const outputPath = resolveOutputPath();
const now = new Date().toISOString();
const result = {
  exported_at: now,
  tasks: db.prepare('SELECT * FROM tasks ORDER BY id DESC').all(),
  points: db.prepare('SELECT * FROM point_wallets ORDER BY owner ASC').all(),
  ledger: db.prepare('SELECT * FROM point_ledger ORDER BY id DESC').all(),
  products: db.prepare('SELECT * FROM products ORDER BY id DESC').all(),
  owned_items: db.prepare('SELECT * FROM owned_items ORDER BY id DESC').all(),
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

fs.writeFileSync(outputPath, JSON.stringify(result, null, 2), 'utf8');
const hash = crypto.createHash('sha256').update(fs.readFileSync(outputPath)).digest('hex');
fs.writeFileSync(`${outputPath}.sha256`, `${hash}  ${path.basename(outputPath)}\n`, 'utf8');
console.log(JSON.stringify({
  type: 'db_export_done',
  output: outputPath,
  sha256: hash,
  ts: new Date().toISOString(),
}));

db.close();
