const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

function sha256File(filePath) {
  return crypto.createHash('sha256').update(fs.readFileSync(filePath)).digest('hex');
}

function resolveDir() {
  const args = process.argv.slice(2);
  const dirIndex = args.findIndex((arg) => arg === '--dir');
  if (dirIndex >= 0 && args[dirIndex + 1]) {
    return path.resolve(args[dirIndex + 1]);
  }
  const inline = args.find((arg) => arg.startsWith('--dir='));
  if (inline) {
    return path.resolve(inline.split('=')[1]);
  }
  return null;
}

const dir = resolveDir();
if (!dir) {
  console.error(JSON.stringify({
    type: 'db_verify_missing_arg',
    message: 'missing --dir path',
    ts: new Date().toISOString(),
  }));
  process.exit(1);
}

const manifestPath = path.join(dir, 'MANIFEST.json');
if (!fs.existsSync(manifestPath)) {
  console.error(JSON.stringify({
    type: 'db_verify_missing_manifest',
    path: manifestPath,
    ts: new Date().toISOString(),
  }));
  process.exit(1);
}

const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
const errors = [];

Object.entries(manifest.files || {}).forEach(([relative, expected]) => {
  const target = path.join(dir, relative);
  if (!fs.existsSync(target)) {
    errors.push({ file: relative, error: 'missing' });
    return;
  }
  const actual = sha256File(target);
  if (actual !== expected) {
    errors.push({ file: relative, error: 'checksum-mismatch', expected, actual });
  }
});

if (errors.length) {
  console.error(JSON.stringify({
    type: 'db_verify_failed',
    errors,
    ts: new Date().toISOString(),
  }));
  process.exit(1);
}

console.log(JSON.stringify({
  type: 'db_verify_ok',
  files: Object.keys(manifest.files || {}).length,
  ts: new Date().toISOString(),
}));
