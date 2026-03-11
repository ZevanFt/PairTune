const fs = require('fs');
const path = require('path');

function resolveInputPath() {
  const args = process.argv.slice(2);
  const fromIndex = args.findIndex((arg) => arg === '--from');
  if (fromIndex >= 0 && args[fromIndex + 1]) {
    return path.resolve(args[fromIndex + 1]);
  }
  const inline = args.find((arg) => arg.startsWith('--from='));
  if (inline) {
    return path.resolve(inline.split('=')[1]);
  }
  return null;
}

const inputPath = resolveInputPath();
if (!inputPath) {
  console.error(JSON.stringify({
    type: 'db_restore_missing_arg',
    message: 'missing --from path',
    ts: new Date().toISOString(),
  }));
  process.exit(1);
}

if (!fs.existsSync(inputPath)) {
  console.error(JSON.stringify({
    type: 'db_restore_missing_file',
    input: inputPath,
    ts: new Date().toISOString(),
  }));
  process.exit(1);
}

const dbPath = process.env.DB_PATH || path.join(__dirname, '..', 'data', 'priority_first.db');
fs.copyFileSync(inputPath, dbPath);
console.log(JSON.stringify({
  type: 'db_restore_done',
  input: inputPath,
  output: dbPath,
  ts: new Date().toISOString(),
}));
