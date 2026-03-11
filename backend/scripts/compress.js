const fs = require('fs');
const path = require('path');
const zlib = require('zlib');
const crypto = require('crypto');

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
    type: 'file_compress_missing_arg',
    message: 'missing --file path',
    ts: new Date().toISOString(),
  }));
  process.exit(1);
}

if (!fs.existsSync(target)) {
  console.error(JSON.stringify({
    type: 'file_compress_missing_file',
    file: target,
    ts: new Date().toISOString(),
  }));
  process.exit(1);
}

const gzPath = `${target}.gz`;
const data = fs.readFileSync(target);
const gzData = zlib.gzipSync(data);
fs.writeFileSync(gzPath, gzData);
const hash = crypto.createHash('sha256').update(gzData).digest('hex');
fs.writeFileSync(`${gzPath}.sha256`, `${hash}  ${path.basename(gzPath)}\n`, 'utf8');

console.log(JSON.stringify({
  type: 'file_compress_done',
  file: target,
  output: gzPath,
  sha256: hash,
  ts: new Date().toISOString(),
}));
