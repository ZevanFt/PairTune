const fs = require('fs');
const path = require('path');
const Database = require('better-sqlite3');
const { execSync } = require('node:child_process');
const { runMigrations } = require('../src/db_migrate');

const dbPath = process.env.DB_PATH || path.join(__dirname, '..', 'data', 'priority_first.db');
const migrationsDir = path.join(__dirname, '..', 'migrations');
const backupDir = path.join(__dirname, '..', 'backups');
const args = process.argv.slice(2);
const downIndex = args.findIndex((arg) => arg === '--down');
const steps = downIndex >= 0 ? Number(args[downIndex + 1] || 1) : null;
const direction = downIndex >= 0 ? 'down' : 'up';
let pipelineDir = null;
const lockPath = path.join(__dirname, '..', '.migrate.lock');

function isProcessAlive(pid) {
  if (!pid) return false;
  try {
    process.kill(pid, 0);
    return true;
  } catch (_) {
    return false;
  }
}

if (fs.existsSync(lockPath)) {
  try {
    const raw = JSON.parse(fs.readFileSync(lockPath, 'utf8'));
    const startedAt = raw?.started_at ? new Date(raw.started_at).getTime() : 0;
    const ttlMs = Number(process.env.MIGRATE_LOCK_TTL_MS || 10 * 60 * 1000);
    const isStale = startedAt && Date.now() - startedAt > ttlMs;
    const alive = isProcessAlive(raw?.pid);
    if (process.env.MIGRATE_FORCE_UNLOCK === '1') {
      fs.unlinkSync(lockPath);
    } else if (!alive || isStale) {
      fs.unlinkSync(lockPath);
    } else {
      console.error(JSON.stringify({
        type: 'db_migration_locked',
        lock: lockPath,
        started_at: raw?.started_at || null,
        pid: raw?.pid || null,
        ts: new Date().toISOString(),
      }));
      process.exit(1);
    }
  } catch (_) {
    if (process.env.MIGRATE_FORCE_UNLOCK === '1') {
      fs.unlinkSync(lockPath);
    } else {
      console.error(JSON.stringify({
        type: 'db_migration_lock_invalid',
        lock: lockPath,
        ts: new Date().toISOString(),
      }));
      process.exit(1);
    }
  }
}

fs.writeFileSync(lockPath, JSON.stringify({
  pid: process.pid,
  started_at: new Date().toISOString(),
  direction,
  steps,
}), 'utf8');

const cleanupLock = () => {
  if (fs.existsSync(lockPath)) {
    fs.unlinkSync(lockPath);
  }
};
process.on('exit', cleanupLock);
process.on('SIGINT', () => {
  cleanupLock();
  process.exit(1);
});
process.on('SIGTERM', () => {
  cleanupLock();
  process.exit(1);
});

const db = new Database(dbPath);
db.pragma('journal_mode = WAL');

const quick = db.prepare('PRAGMA quick_check').get();
if (quick?.quick_check !== 'ok') {
  console.error(JSON.stringify({
    type: 'db_quick_check_failed',
    result: quick?.quick_check || 'unknown',
    ts: new Date().toISOString(),
  }));
  process.exit(1);
}

if (process.env.MIGRATE_RUN_PIPELINE === '1') {
  try {
    const pipeline = path.join(__dirname, 'pipeline.js');
    pipelineDir = path.join(__dirname, '..', 'exports', `pre-migrate-${new Date().toISOString().replace(/[:.]/g, '-')}`);
    fs.mkdirSync(pipelineDir, { recursive: true });
    execSync(`node ${pipeline} --out ${pipelineDir}`, { stdio: 'inherit' });
  } catch (error) {
    console.error(JSON.stringify({
      type: 'db_migration_pipeline_failed',
      message: String(error?.message || error),
      ts: new Date().toISOString(),
    }));
    process.exit(1);
  }
}

let backupPath = null;
if (fs.existsSync(dbPath) && process.env.MIGRATE_SKIP_BACKUP !== '1') {
  if (!fs.existsSync(backupDir)) {
    fs.mkdirSync(backupDir, { recursive: true });
  }
  const stamp = new Date().toISOString().replace(/[:.]/g, '-');
  const prefix = direction === 'down' ? 'pre-rollback' : 'pre-migrate';
  backupPath = path.join(backupDir, `${prefix}-${stamp}.db`);
  fs.copyFileSync(dbPath, backupPath);
  const keep = Number(process.env.MIGRATE_BACKUP_KEEP || 10);
  if (keep > 0) {
    const files = fs.readdirSync(backupDir)
      .filter((file) => file.endsWith('.db'))
      .map((file) => ({
        name: file,
        time: fs.statSync(path.join(backupDir, file)).mtimeMs,
      }))
      .sort((a, b) => b.time - a.time);
    files.slice(keep).forEach((file) => {
      fs.unlinkSync(path.join(backupDir, file.name));
    });
  }
  console.log(JSON.stringify({
    type: 'db_migration_backup',
    output: backupPath,
    ts: new Date().toISOString(),
  }));
}

let result = { applied: [], skipped: [] };
try {
  result = runMigrations({
    db,
    migrationsDir,
    direction,
    steps,
    logger: (event, detail) => {
      console.log(JSON.stringify({ type: event, ...detail, ts: new Date().toISOString() }));
    },
  });
} catch (error) {
  const msg = JSON.stringify({
    type: 'db_migration_failed',
    message: String(error?.message || error),
    ts: new Date().toISOString(),
  });
  console.error(msg);
  if (pipelineDir) {
    const eventsPath = path.join(pipelineDir, 'events.jsonl');
    fs.appendFileSync(eventsPath, `${msg}\n`, 'utf8');
    if (process.env.MIGRATE_REPORT_ON_FAIL === '1') {
      try {
        const report = path.join(__dirname, 'report.js');
        execSync(`node ${report} --dir ${pipelineDir}`, { stdio: 'inherit' });
      } catch (_) {
        // ignore report failure
      }
    }
  }
  if (process.env.NOTIFY_ON_FAIL === '1') {
    try {
      const notify = path.join(__dirname, 'notify.js');
      execSync(`node ${notify} --message=db_migration_failed`, { stdio: 'inherit' });
    } catch (_) {
      // ignore notify failure
    }
  }
  if (backupPath && process.env.MIGRATE_AUTO_RESTORE === '1') {
    try {
      fs.copyFileSync(backupPath, dbPath);
      const restored = JSON.stringify({
        type: 'db_migration_restored',
        backup: backupPath,
        ts: new Date().toISOString(),
      });
      console.log(restored);
      if (pipelineDir) {
        const eventsPath = path.join(pipelineDir, 'events.jsonl');
        fs.appendFileSync(eventsPath, `${restored}\n`, 'utf8');
      }
      if (pipelineDir && process.env.MIGRATE_REPORT_ON_RESTORE === '1') {
        try {
          const report = path.join(__dirname, 'report.js');
          execSync(`node ${report} --dir ${pipelineDir}`, { stdio: 'inherit' });
        } catch (_) {
          // ignore report failure
        }
      }
      if (pipelineDir && process.env.MIGRATE_UPLOAD_ON_RESTORE === '1') {
        try {
          const upload = path.join(__dirname, 'upload.js');
          const target = process.env.MIGRATE_UPLOAD_TARGET;
          if (target) {
            execSync(`node ${upload} --src ${pipelineDir} --dest ${target} --verify`, { stdio: 'inherit' });
            if (process.env.MIGRATE_NOTIFY_ON_RESTORE_UPLOAD === '1') {
              try {
                const notify = path.join(__dirname, 'notify.js');
                execSync(`node ${notify} --message=db_migration_restore_upload_done --dir ${target}`, { stdio: 'inherit' });
              } catch (_) {
                // ignore notify failure
              }
            }
          }
        } catch (_) {
          // ignore upload failure
        }
      }
      if (process.env.MIGRATE_RESTORE_AUTO_FLOW === '1') {
        try {
          const upload = path.join(__dirname, 'upload.js');
          const target = process.env.MIGRATE_UPLOAD_TARGET;
          if (target) {
            execSync(`node ${upload} --src ${pipelineDir} --dest ${target} --verify`, { stdio: 'inherit' });
            const report = path.join(__dirname, 'report.js');
            execSync(`node ${report} --dir ${pipelineDir}`, { stdio: 'inherit' });
            const notify = path.join(__dirname, 'notify.js');
            execSync(`node ${notify} --message=db_migration_restore_auto_flow_done --dir ${target}`, { stdio: 'inherit' });
            if (process.env.MIGRATE_UPLOAD_SUMMARY === '1') {
              const summaryPath = path.join(pipelineDir, 'SUMMARY.txt');
              if (fs.existsSync(summaryPath)) {
                execSync(`node ${upload} --src ${summaryPath} --dest ${path.join(target, 'SUMMARY.txt')}`, { stdio: 'inherit' });
              }
            }
            if (process.env.MIGRATE_UPLOAD_REPORTS === '1') {
              const reportPath = path.join(pipelineDir, 'REPORT.json');
              const manifestPath = path.join(pipelineDir, 'MANIFEST.json');
              if (fs.existsSync(reportPath)) {
                execSync(`node ${upload} --src ${reportPath} --dest ${path.join(target, 'REPORT.json')}`, { stdio: 'inherit' });
              }
              if (fs.existsSync(manifestPath)) {
                execSync(`node ${upload} --src ${manifestPath} --dest ${path.join(target, 'MANIFEST.json')}`, { stdio: 'inherit' });
              }
            }
          }
        } catch (_) {
          // ignore flow failure
        }
      }
      if (process.env.NOTIFY_ON_FAIL === '1') {
        try {
          const notify = path.join(__dirname, 'notify.js');
          execSync(`node ${notify} --message=db_migration_restored`, { stdio: 'inherit' });
        } catch (_) {
          // ignore notify failure
        }
      }
    } catch (restoreError) {
      const restoreMsg = JSON.stringify({
        type: 'db_migration_restore_failed',
        message: String(restoreError?.message || restoreError),
        ts: new Date().toISOString(),
      });
      console.error(restoreMsg);
    }
  }
  db.close();
  cleanupLock();
  process.exit(1);
}

console.log(JSON.stringify({
  type: 'db_migration_summary',
  applied: result.applied,
  skipped: result.skipped,
  ts: new Date().toISOString(),
}));

db.close();
cleanupLock();
