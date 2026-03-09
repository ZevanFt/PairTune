const path = require('path');
const crypto = require('crypto');
const express = require('express');
const cors = require('cors');
const Database = require('better-sqlite3');

const app = express();
const port = process.env.PORT || 8110;
const dbPath = path.join(__dirname, '..', 'data', 'priority_first.db');
const db = new Database(dbPath);

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

function isStrongPassword(value) {
  return String(value || '').trim().length >= 6;
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

CREATE TABLE IF NOT EXISTS auth_users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  phone TEXT UNIQUE,
  wechat_openid TEXT UNIQUE,
  password_hash TEXT,
  display_name TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'active',
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
    'INSERT OR IGNORE INTO app_settings(owner, duo_enabled, notifications_enabled, quiet_hours_start, quiet_hours_end, updated_at) VALUES (?, ?, ?, ?, ?, ?)',
  ).run(OWNER_ME, 0, 1, '22:00', '08:00', now);
  db.prepare(
    'INSERT OR IGNORE INTO app_settings(owner, duo_enabled, notifications_enabled, quiet_hours_start, quiet_hours_end, updated_at) VALUES (?, ?, ?, ?, ?, ?)',
  ).run(OWNER_PARTNER, 0, 1, '22:00', '08:00', now);

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
      `SELECT owner, duo_enabled, notifications_enabled, quiet_hours_start, quiet_hours_end, updated_at
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
  const now = new Date().toISOString();

  db.prepare(
    `UPDATE app_settings
     SET duo_enabled = ?, notifications_enabled = ?, quiet_hours_start = ?, quiet_hours_end = ?, updated_at = ?
     WHERE owner = ?`,
  ).run(
    nextDuoEnabled,
    nextNotificationsEnabled,
    quiet_hours_start ?? existing.quiet_hours_start,
    quiet_hours_end ?? existing.quiet_hours_end,
    now,
    owner,
  );

  const settings = db.prepare('SELECT * FROM app_settings WHERE owner = ?').get(owner);
  res.json({ code: 200, message: '更新设置成功', result: settings });
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
  const user = db.prepare('SELECT id, phone, wechat_openid, display_name, status, created_at, updated_at FROM auth_users WHERE id = ?')
    .get(info.lastInsertRowid);
  res.json({ code: 200, message: '手机号注册成功', result: user });
});

app.post('/auth/login/phone', (req, res) => {
  const { phone, password } = req.body || {};
  if (!isPhone(phone) || !isStrongPassword(password)) {
    return res.status(400).json({ code: 400, message: '手机号或密码格式非法', result: null });
  }
  const user = db.prepare(
    'SELECT * FROM auth_users WHERE phone = ? AND status = ?',
  ).get(String(phone).trim(), 'active');
  if (!user || user.password_hash !== hashPassword(password)) {
    return res.status(401).json({ code: 401, message: '手机号或密码错误', result: null });
  }
  const now = new Date();
  const expires = new Date(now.getTime() + 1000 * 60 * 60 * 24 * 30).toISOString();
  const token = createSessionToken();
  db.prepare(
    `INSERT INTO auth_sessions(token, user_id, provider, owner_hint, expires_at, created_at, last_seen_at)
     VALUES (?, ?, 'phone', 'me', ?, ?, ?)`,
  ).run(token, user.id, expires, now.toISOString(), now.toISOString());
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
        wechat_openid: user.wechat_openid,
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
            u.display_name, u.phone, u.wechat_openid, u.status
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
    profiles: db.prepare('SELECT * FROM profiles ORDER BY owner ASC').all(),
    settings: db.prepare('SELECT * FROM app_settings ORDER BY owner ASC').all(),
    notifications: db.prepare('SELECT * FROM notifications ORDER BY id DESC').all(),
    auth_users: db.prepare('SELECT id, phone, wechat_openid, display_name, status, created_at, updated_at FROM auth_users ORDER BY id DESC').all(),
    auth_sessions: db.prepare('SELECT token, user_id, provider, owner_hint, expires_at, created_at, last_seen_at FROM auth_sessions ORDER BY created_at DESC').all(),
  };
  res.json({ code: 200, message: '导出快照成功', result });
});

app.listen(port, () => {
  console.log(`[priority_first_backend] running at http://0.0.0.0:${port}`);
});
