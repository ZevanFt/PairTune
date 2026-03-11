const fs = require('fs');
const path = require('path');

function resolveOutputDir(args) {
  const outIndex = args.findIndex((arg) => arg === '--dir');
  if (outIndex >= 0 && args[outIndex + 1]) {
    return path.resolve(args[outIndex + 1]);
  }
  const inline = args.find((arg) => arg.startsWith('--dir='));
  if (inline) {
    return path.resolve(inline.split('=')[1]);
  }
  return null;
}

const args = process.argv.slice(2);
const dir = resolveOutputDir(args);
const message = args.find((arg) => arg.startsWith('--message='))?.split('=')[1] || 'event';
const payload = {
  ts: new Date().toISOString(),
  message,
  dir,
};

const target = process.env.NOTIFY_LOG || path.join(__dirname, '..', 'exports', 'notify.log');
fs.appendFileSync(target, `${JSON.stringify(payload)}\n`, 'utf8');
console.log(JSON.stringify({
  type: 'notify_written',
  target,
  ts: payload.ts,
}));
