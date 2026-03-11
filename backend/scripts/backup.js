const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const zlib = require('zlib');

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
  const dir = path.join(__dirname, '..', 'backups');
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
  return path.join(dir, `priority_first-${nowStamp()}.db`);
}

function pruneBackups(dir, keep) {
  if (!keep || keep <= 0 || !fs.existsSync(dir)) return;
  const files = fs.readdirSync(dir)
    .filter((file) => file.endsWith('.db'))
    .map((file) => ({
      name: file,
      time: fs.statSync(path.join(dir, file)).mtimeMs,
    }))
    .sort((a, b) => b.time - a.time);
  files.slice(keep).forEach((file) => {
    fs.unlinkSync(path.join(dir, file.name));
  });
}

const dbPath = process.env.DB_PATH || path.join(__dirname, '..', 'data', 'priority_first.db');
if (!fs.existsSync(dbPath)) {
  console.error(JSON.stringify({
    type: 'db_backup_missing',
    db_path: dbPath,
    ts: new Date().toISOString(),
  }));
  process.exit(1);
}

const outputPath = resolveOutputPath();
fs.copyFileSync(dbPath, outputPath);
const keep = Number(process.env.BACKUP_KEEP || 10);
pruneBackups(path.dirname(outputPath), keep);
const hash = crypto.createHash('sha256').update(fs.readFileSync(outputPath)).digest('hex');
fs.writeFileSync(`${outputPath}.sha256`, `${hash}  ${path.basename(outputPath)}\n`, 'utf8');

if (process.env.BACKUP_COMPRESS === '1') {
  const gzPath = `${outputPath}.gz`;
  const gzData = zlib.gzipSync(fs.readFileSync(outputPath));
  fs.writeFileSync(gzPath, gzData);
  const gzHash = crypto.createHash('sha256').update(gzData).digest('hex');
  fs.writeFileSync(`${gzPath}.sha256`, `${gzHash}  ${path.basename(gzPath)}\n`, 'utf8');
}
console.log(JSON.stringify({
  type: 'db_backup_done',
  output: outputPath,
  sha256: hash,
  ts: new Date().toISOString(),
}));
