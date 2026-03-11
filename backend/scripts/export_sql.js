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
  return path.join(dir, `snapshot-${nowStamp()}.sql`);
}

function escapeValue(value) {
  if (value === null || value === undefined) return 'NULL';
  if (typeof value === 'number') return Number.isFinite(value) ? String(value) : 'NULL';
  if (typeof value === 'boolean') return value ? '1' : '0';
  const text = String(value).replace(/'/g, "''");
  return `'${text}'`;
}

const dbPath = process.env.DB_PATH || path.join(__dirname, '..', 'data', 'priority_first.db');
const db = new Database(dbPath, { readonly: true });

const outputPath = resolveOutputPath();
const out = [];
out.push('-- Priority First SQLite export');
out.push(`-- Exported at ${new Date().toISOString()}`);
out.push('PRAGMA foreign_keys=OFF;');
out.push('BEGIN TRANSACTION;');

const schema = db.prepare(
  `SELECT type, name, tbl_name, sql
   FROM sqlite_master
   WHERE name NOT LIKE 'sqlite_%'
   ORDER BY CASE type WHEN 'table' THEN 0 WHEN 'index' THEN 1 ELSE 2 END, name`,
).all();

schema.forEach((row) => {
  if (row.sql) {
    out.push(`${row.sql};`);
  }
});

const tables = db.prepare(
  `SELECT name FROM sqlite_master
   WHERE type = 'table' AND name NOT LIKE 'sqlite_%'
   ORDER BY name`,
).all();

tables.forEach((row) => {
  const tableName = row.name;
  const columns = db.prepare(`PRAGMA table_info('${tableName}')`).all().map((col) => col.name);
  const rows = db.prepare(`SELECT * FROM ${tableName}`).all();
  rows.forEach((item) => {
    const values = columns.map((col) => escapeValue(item[col]));
    out.push(`INSERT INTO ${tableName} (${columns.join(',')}) VALUES (${values.join(',')});`);
  });
});

out.push('COMMIT;');
fs.writeFileSync(outputPath, `${out.join('\n')}\n`, 'utf8');

const hash = crypto.createHash('sha256').update(fs.readFileSync(outputPath)).digest('hex');
fs.writeFileSync(`${outputPath}.sha256`, `${hash}  ${path.basename(outputPath)}\n`, 'utf8');
console.log(JSON.stringify({
  type: 'db_export_sql_done',
  output: outputPath,
  sha256: hash,
  ts: new Date().toISOString(),
}));

db.close();
