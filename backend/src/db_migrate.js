const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

function hashContent(content) {
  return crypto.createHash('sha256').update(content).digest('hex');
}

function parseMigrationFiles(migrationsDir) {
  const files = fs.readdirSync(migrationsDir).filter((file) => file.endsWith('.sql')).sort();
  const map = new Map();
  files.forEach((file) => {
    const match = file.match(/^(\\d+_.+?)\\.(up|down)\\.sql$/);
    if (match) {
      const id = match[1];
      const entry = map.get(id) || { id, up: null, down: null };
      if (match[2] === 'up') entry.up = file;
      if (match[2] === 'down') entry.down = file;
      map.set(id, entry);
      return;
    }
    // legacy single-file migration: treat as up only
    const legacyId = file.replace(/\\.sql$/, '');
    if (!map.has(legacyId)) {
      map.set(legacyId, { id: legacyId, up: file, down: null });
    }
  });
  return Array.from(map.values()).sort((a, b) => a.id.localeCompare(b.id));
}

function runMigrations({ db, migrationsDir, logger, direction = 'up', steps = null }) {
  const log = logger || ((event, detail) => {
    console.log(JSON.stringify({ type: event, ...detail, ts: new Date().toISOString() }));
  });
  if (!fs.existsSync(migrationsDir)) {
    log('db_migration_missing_dir', { dir: migrationsDir });
    return { applied: [], skipped: [] };
  }

  db.exec(`
CREATE TABLE IF NOT EXISTS schema_migrations (
  id TEXT PRIMARY KEY,
  checksum TEXT NOT NULL,
  applied_at TEXT NOT NULL
);
`);

  const columns = db.prepare("PRAGMA table_info('schema_migrations')").all();
  const hasChecksum = columns.some((col) => col.name === 'checksum');
  if (!hasChecksum) {
    db.exec("ALTER TABLE schema_migrations ADD COLUMN checksum TEXT NOT NULL DEFAULT '';");
  }

  const appliedRows = db.prepare('SELECT id, checksum, applied_at FROM schema_migrations ORDER BY applied_at ASC').all();
  const appliedSet = new Set(appliedRows.map((row) => row.id));
  const files = parseMigrationFiles(migrationsDir);
  const applied = [];
  const skipped = [];

  if (direction === 'down') {
    const candidates = appliedRows.slice().reverse();
    const limit = steps === null ? candidates.length : Math.max(0, Number(steps));
    const toRollback = candidates.slice(0, limit);
    toRollback.forEach((row) => {
      const entry = files.find((item) => item.id === row.id);
      if (!entry || !entry.down) {
        throw new Error(`missing down migration for ${row.id}`);
      }
      const downPath = path.join(migrationsDir, entry.down);
      const sql = fs.readFileSync(downPath, 'utf8');
      const tx = db.transaction(() => {
        db.exec(sql);
        db.prepare('DELETE FROM schema_migrations WHERE id = ?').run(row.id);
      });
      tx();
      applied.push(entry.down);
      log('db_migration_rolled_back', { id: row.id });
    });
    return { applied, skipped };
  }

  files.forEach((entry) => {
    if (appliedSet.has(entry.id)) {
      skipped.push(entry.id);
      return;
    }
    if (!entry.up) {
      throw new Error(`missing up migration for ${entry.id}`);
    }
    const fullPath = path.join(migrationsDir, entry.up);
    const sql = fs.readFileSync(fullPath, 'utf8');
    const now = new Date().toISOString();
    const checksum = hashContent(sql);
    const tx = db.transaction(() => {
      db.exec(sql);
      db.prepare('INSERT INTO schema_migrations(id, checksum, applied_at) VALUES (?, ?, ?)')
        .run(entry.id, checksum, now);
    });
    tx();
    applied.push(entry.up);
    log('db_migration_applied', { id: entry.id });
  });

  if (applied.length === 0) {
    log('db_migration_noop', { count: files.length });
  }

  return { applied, skipped };
}

module.exports = { runMigrations };
