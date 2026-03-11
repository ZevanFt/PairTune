const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

function sha256File(filePath) {
  return crypto.createHash('sha256').update(fs.readFileSync(filePath)).digest('hex');
}

function resolveFile() {
  const args = process.argv.slice(2);
  const fileIndex = args.findIndex((arg) => arg === '--file');
  if (fileIndex >= 0 && args[fileIndex + 1]) {
    return path.resolve(args[fileIndex + 1]);
  }
  const inline = args.find((arg) => arg.startsWith('--file='));
  if (inline) {
    return path.resolve(inline.split('=')[1]);
  }
  return null;
}

const target = resolveFile();
if (!target) {
  console.error(JSON.stringify({
    type: 'file_verify_missing_arg',
    message: 'missing --file path',
    ts: new Date().toISOString(),
  }));
  process.exit(1);
}

const checksumPath = `${target}.sha256`;
if (!fs.existsSync(checksumPath)) {
  console.error(JSON.stringify({
    type: 'file_verify_missing_checksum',
    checksum: checksumPath,
    ts: new Date().toISOString(),
  }));
  process.exit(1);
}

const expected = fs.readFileSync(checksumPath, 'utf8').trim().split(/\s+/)[0];
const actual = sha256File(target);

if (actual !== expected) {
  console.error(JSON.stringify({
    type: 'file_verify_failed',
    file: target,
    expected,
    actual,
    ts: new Date().toISOString(),
  }));
  process.exit(1);
}

console.log(JSON.stringify({
  type: 'file_verify_ok',
  file: target,
  sha256: actual,
  ts: new Date().toISOString(),
}));
