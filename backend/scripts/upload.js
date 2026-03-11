const fs = require('fs');
const path = require('path');
const { execSync } = require('node:child_process');

function resolveArg(args, name) {
  const idx = args.findIndex((arg) => arg === name);
  if (idx >= 0 && args[idx + 1]) return path.resolve(args[idx + 1]);
  const inline = args.find((arg) => arg.startsWith(`${name}=`));
  if (inline) return path.resolve(inline.split('=')[1]);
  return null;
}

function copyDir(src, dest) {
  if (!fs.existsSync(dest)) fs.mkdirSync(dest, { recursive: true });
  fs.readdirSync(src, { withFileTypes: true }).forEach((entry) => {
    const from = path.join(src, entry.name);
    const to = path.join(dest, entry.name);
    if (entry.isDirectory()) {
      copyDir(from, to);
    } else {
      fs.copyFileSync(from, to);
    }
  });
}

function pruneUploads(destDir, keep) {
  if (!keep || keep <= 0 || !fs.existsSync(destDir)) return;
  const entries = fs.readdirSync(destDir)
    .map((entry) => ({
      name: entry,
      time: fs.statSync(path.join(destDir, entry)).mtimeMs,
    }))
    .sort((a, b) => b.time - a.time);
  entries.slice(keep).forEach((entry) => {
    const target = path.join(destDir, entry.name);
    if (fs.lstatSync(target).isDirectory()) {
      fs.rmSync(target, { recursive: true, force: true });
    } else {
      fs.unlinkSync(target);
    }
  });
}

const args = process.argv.slice(2);
const src = resolveArg(args, '--src');
const dest = resolveArg(args, '--dest') || process.env.UPLOAD_TARGET || null;
const verify = args.includes('--verify') || process.env.UPLOAD_VERIFY === '1';
const deleteOnFail = args.includes('--delete-on-fail') || process.env.UPLOAD_VERIFY_FAIL_DELETE === '1';
const keep = Number(process.env.UPLOAD_KEEP || 0);
const cleanupOnSuccess = args.includes('--cleanup-on-success') || process.env.UPLOAD_CLEANUP_ON_SUCCESS === '1';
const lockTtlMs = Number(process.env.UPLOAD_LOCK_TTL_MS || 10 * 60 * 1000);
const forceUnlock = args.includes('--force-unlock') || process.env.UPLOAD_FORCE_UNLOCK === '1';
const notifyOnFail = args.includes('--notify-fail') || process.env.UPLOAD_NOTIFY_ON_FAIL === '1';
const notifyOnSuccess = args.includes('--notify-ok') || process.env.UPLOAD_NOTIFY_ON_OK === '1';
const autoReport = process.env.UPLOAD_AUTO_REPORT === '1';
const restoreOnFail = args.includes('--restore-on-fail') || process.env.UPLOAD_RESTORE_ON_FAIL === '1';
const latestLink = process.env.UPLOAD_LATEST_LINK || null;

if (!src || !dest) {
  console.error(JSON.stringify({
    type: 'upload_missing_arg',
    message: 'missing --src or --dest (or UPLOAD_TARGET)',
    ts: new Date().toISOString(),
  }));
  process.exit(1);
}

if (!fs.existsSync(src)) {
  console.error(JSON.stringify({
    type: 'upload_missing_src',
    src,
    ts: new Date().toISOString(),
  }));
  process.exit(1);
}

const stat = fs.statSync(src);
const lockPath = stat.isDirectory() ? path.join(dest, '.upload.lock') : `${dest}.lock`;

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
    const isStale = startedAt && Date.now() - startedAt > lockTtlMs;
    const alive = isProcessAlive(raw?.pid);
    if (forceUnlock || !alive || isStale) {
      fs.unlinkSync(lockPath);
    } else {
      console.error(JSON.stringify({
        type: 'upload_locked',
        lock: lockPath,
        started_at: raw?.started_at || null,
        pid: raw?.pid || null,
        ts: new Date().toISOString(),
      }));
      process.exit(1);
    }
  } catch (_) {
    if (forceUnlock) {
      fs.unlinkSync(lockPath);
    } else {
      console.error(JSON.stringify({
        type: 'upload_lock_invalid',
        lock: lockPath,
        ts: new Date().toISOString(),
      }));
      process.exit(1);
    }
  }
}

fs.mkdirSync(path.dirname(lockPath), { recursive: true });
fs.writeFileSync(lockPath, JSON.stringify({
  pid: process.pid,
  started_at: new Date().toISOString(),
  src,
  dest,
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

const markerPath = stat.isDirectory() ? path.join(dest, '.upload_marker') : `${dest}.upload_marker`;
fs.mkdirSync(path.dirname(markerPath), { recursive: true });
fs.writeFileSync(markerPath, new Date().toISOString(), 'utf8');
const eventsPath = path.join(path.dirname(markerPath), 'events.jsonl');
const lastSuccessPath = path.join(path.dirname(markerPath), '.upload_last_success.json');
if (stat.isDirectory()) {
  copyDir(src, dest);
} else {
  if (!fs.existsSync(path.dirname(dest))) {
    fs.mkdirSync(path.dirname(dest), { recursive: true });
  }
  fs.copyFileSync(src, dest);
}

let pruned = 0;
if (keep > 0) {
  const before = fs.readdirSync(path.dirname(dest)).length;
  pruneUploads(path.dirname(dest), keep);
  const after = fs.readdirSync(path.dirname(dest)).length;
  pruned = Math.max(0, before - after);
}

const uploadEvent = JSON.stringify({
  type: 'upload_done',
  src,
  dest,
  pruned,
  ts: new Date().toISOString(),
});
console.log(uploadEvent);
if (fs.existsSync(markerPath)) {
  fs.appendFileSync(eventsPath, `${uploadEvent}\n`, 'utf8');
}

if (verify) {
  try {
    const report = path.join(__dirname, 'report.js');
    execSync(`node ${report} --dir ${dest}`, { stdio: 'inherit' });
  } catch (error) {
    console.error(JSON.stringify({
      type: 'upload_verify_failed',
      message: String(error?.message || error),
      ts: new Date().toISOString(),
    }));
    if (deleteOnFail && fs.existsSync(markerPath)) {
      try {
        if (fs.existsSync(dest) && fs.lstatSync(dest).isDirectory()) {
          fs.rmSync(dest, { recursive: true, force: true });
        } else if (fs.existsSync(dest)) {
          fs.unlinkSync(dest);
        }
        if (fs.existsSync(markerPath)) {
          fs.unlinkSync(markerPath);
        }
      } catch (_) {
        // ignore cleanup failure
      }
    }
    if (restoreOnFail && fs.existsSync(lastSuccessPath)) {
      try {
        const last = JSON.parse(fs.readFileSync(lastSuccessPath, 'utf8'));
        if (last?.path && fs.existsSync(last.path)) {
          if (fs.lstatSync(last.path).isDirectory()) {
            copyDir(last.path, dest);
          } else {
            if (!fs.existsSync(path.dirname(dest))) {
              fs.mkdirSync(path.dirname(dest), { recursive: true });
            }
            fs.copyFileSync(last.path, dest);
          }
          const restoreEvent = JSON.stringify({
            type: 'upload_restore_done',
            from: last.path,
            to: dest,
            ts: new Date().toISOString(),
          });
          fs.appendFileSync(eventsPath, `${restoreEvent}\n`, 'utf8');
          if (autoReport) {
            try {
              const report = path.join(__dirname, 'report.js');
              execSync(`node ${report} --dir ${dest}`, { stdio: 'inherit' });
            } catch (_) {
              // ignore report failure
            }
          }
          if (notifyOnFail) {
            try {
              const notify = path.join(__dirname, 'notify.js');
              execSync(`node ${notify} --message=upload_restore_done --dir ${dest}`, { stdio: 'inherit' });
            } catch (_) {
              // ignore notify failure
            }
          }
          if (process.env.UPLOAD_TRIGGER_PIPELINE_SUMMARY === '1') {
            try {
              const pipeline = path.join(__dirname, 'pipeline.js');
              execSync(`node ${pipeline} --out ${dest}`, { stdio: 'inherit' });
            } catch (_) {
              // ignore pipeline failure
            }
          }
        }
      } catch (_) {
        const restoreFail = JSON.stringify({
          type: 'upload_restore_failed',
          dest,
          ts: new Date().toISOString(),
        });
        fs.appendFileSync(eventsPath, `${restoreFail}\n`, 'utf8');
        // ignore restore failure
      }
    }
    if (notifyOnFail) {
      try {
        const notify = path.join(__dirname, 'notify.js');
        execSync(`node ${notify} --message=upload_verify_failed --dir ${dest}`, { stdio: 'inherit' });
      } catch (_) {
        // ignore notify failure
      }
    }
    const failEvent = JSON.stringify({
      type: 'upload_verify_failed',
      dest,
      ts: new Date().toISOString(),
    });
    fs.appendFileSync(eventsPath, `${failEvent}\n`, 'utf8');
    if (autoReport) {
      try {
        const report = path.join(__dirname, 'report.js');
        execSync(`node ${report} --dir ${dest}`, { stdio: 'inherit' });
      } catch (_) {
        // ignore report failure
      }
    }
    cleanupLock();
    process.exit(1);
  }
}

if (autoReport) {
  try {
    const report = path.join(__dirname, 'report.js');
    execSync(`node ${report} --dir ${dest}`, { stdio: 'inherit' });
  } catch (_) {
    // ignore report failure
  }
}

if (notifyOnSuccess) {
  try {
    const notify = path.join(__dirname, 'notify.js');
    execSync(`node ${notify} --message=upload_ok --dir ${dest}`, { stdio: 'inherit' });
  } catch (_) {
    // ignore notify failure
  }
}

if (cleanupOnSuccess && keep > 0) {
  // already pruned above; write a cleanup event for visibility
  const cleanupEvent = JSON.stringify({
    type: 'upload_cleanup_done',
    pruned,
    ts: new Date().toISOString(),
  });
  fs.appendFileSync(eventsPath, `${cleanupEvent}\n`, 'utf8');
}

if (latestLink && fs.existsSync(dest) && fs.lstatSync(dest).isDirectory()) {
  try {
    const manifestPath = path.join(dest, 'MANIFEST.json');
    if (!fs.existsSync(manifestPath)) {
      throw new Error('missing MANIFEST.json');
    }
    if (fs.existsSync(latestLink)) {
      fs.unlinkSync(latestLink);
    }
    fs.symlinkSync(dest, latestLink, 'dir');
    const linkEvent = JSON.stringify({
      type: 'upload_latest_link',
      link: latestLink,
      target: dest,
      ts: new Date().toISOString(),
    });
    fs.appendFileSync(eventsPath, `${linkEvent}\n`, 'utf8');
  } catch (_) {
    // ignore link failure
  }
}

try {
  fs.writeFileSync(lastSuccessPath, JSON.stringify({
    path: dest,
    ts: new Date().toISOString(),
  }), 'utf8');
} catch (_) {
  // ignore
}

cleanupLock();
