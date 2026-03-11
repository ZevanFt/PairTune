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

function resolveOut() {
  const args = process.argv.slice(2);
  const outIndex = args.findIndex((arg) => arg === '--out');
  if (outIndex >= 0 && args[outIndex + 1]) {
    return path.resolve(args[outIndex + 1]);
  }
  const inline = args.find((arg) => arg.startsWith('--out='));
  if (inline) {
    return path.resolve(inline.split('=')[1]);
  }
  return null;
}

function listFiles(dir) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  const results = [];
  entries.forEach((entry) => {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      listFiles(full).forEach((file) => results.push(file));
    } else {
      results.push(full);
    }
  });
  return results;
}

const dir = resolveDir();
if (!dir) {
  console.error(JSON.stringify({
    type: 'report_missing_arg',
    message: 'missing --dir path',
    ts: new Date().toISOString(),
  }));
  process.exit(1);
}
if (!fs.existsSync(dir)) {
  console.error(JSON.stringify({
    type: 'report_missing_dir',
    dir,
    ts: new Date().toISOString(),
  }));
  process.exit(1);
}

const report = {
  generated_at: new Date().toISOString(),
  dir,
  files: [],
  summary: {
    total_files: 0,
    verified: 0,
    mismatched: 0,
    missing_checksums: 0,
    total_bytes: 0,
    upload_pruned: 0,
  },
  events: [],
};

const files = listFiles(dir)
  .filter((file) => !file.endsWith('.sha256'));

const eventsPath = path.join(dir, 'events.jsonl');
if (fs.existsSync(eventsPath)) {
  const lines = fs.readFileSync(eventsPath, 'utf8').split('\n').filter(Boolean);
  report.events = lines.map((line) => {
    try {
      return JSON.parse(line);
    } catch (_) {
      return { raw: line };
    }
  });
  report.summary.upload_pruned = report.events
    .filter((event) => event.type === 'upload_done' && typeof event.pruned === 'number')
    .reduce((sum, event) => sum + event.pruned, 0);
}

files.forEach((file) => {
  const size = fs.statSync(file).size;
  const checksumPath = `${file}.sha256`;
  let expected = null;
  let actual = null;
  let status = 'no-checksum';
  if (fs.existsSync(checksumPath)) {
    expected = fs.readFileSync(checksumPath, 'utf8').trim().split(/\s+/)[0];
    actual = sha256File(file);
    status = expected === actual ? 'ok' : 'mismatch';
  }
  report.files.push({
    path: path.relative(dir, file).replace(/\\/g, '/'),
    size_bytes: size,
    status,
    expected,
    actual,
  });
  report.summary.total_files += 1;
  report.summary.total_bytes += size;
  if (status === 'ok') report.summary.verified += 1;
  if (status === 'mismatch') report.summary.mismatched += 1;
  if (status === 'no-checksum') report.summary.missing_checksums += 1;
});

const outPath = resolveOut() || path.join(dir, 'REPORT.json');
fs.writeFileSync(outPath, JSON.stringify(report, null, 2), 'utf8');

console.log(JSON.stringify({
  type: 'report_done',
  output: outPath,
  summary: report.summary,
  ts: new Date().toISOString(),
}));
