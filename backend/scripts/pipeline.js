const fs = require('fs');
const path = require('path');
const { execSync } = require('node:child_process');

function nowStamp() {
  const d = new Date();
  const pad = (value) => String(value).padStart(2, '0');
  return `${d.getFullYear()}${pad(d.getMonth() + 1)}${pad(d.getDate())}-${pad(d.getHours())}${pad(d.getMinutes())}${pad(d.getSeconds())}`;
}

function resolveOutputDir() {
  const args = process.argv.slice(2);
  const outIndex = args.findIndex((arg) => arg === '--out');
  if (outIndex >= 0 && args[outIndex + 1]) {
    return path.resolve(args[outIndex + 1]);
  }
  const inline = args.find((arg) => arg.startsWith('--out='));
  if (inline) {
    return path.resolve(inline.split('=')[1]);
  }
  const dir = path.join(__dirname, '..', 'exports', `bundle-${nowStamp()}`);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
  return dir;
}

const outputDir = resolveOutputDir();
const eventsPath = path.join(outputDir, 'events.jsonl');

const logEvent = (event) => {
  fs.appendFileSync(eventsPath, `${JSON.stringify({ ts: new Date().toISOString(), ...event })}\n`, 'utf8');
};

logEvent({ type: 'pipeline_start', output: outputDir });
execSync(`node ${path.join(__dirname, 'export_bundle.js')} --out ${outputDir}`, { stdio: 'inherit' });
logEvent({ type: 'pipeline_export_done' });
execSync(`node ${path.join(__dirname, 'verify_bundle.js')} --dir ${outputDir}`, { stdio: 'inherit' });
logEvent({ type: 'pipeline_verify_done' });
execSync(`node ${path.join(__dirname, 'report.js')} --dir ${outputDir}`, { stdio: 'inherit' });
logEvent({ type: 'pipeline_report_done' });

if (process.env.PIPELINE_UPLOAD_TO) {
  try {
    const upload = path.join(__dirname, 'upload.js');
    const verifyFlag = process.env.PIPELINE_UPLOAD_VERIFY === '1' ? ' --verify' : '';
    execSync(`node ${upload} --src ${outputDir} --dest ${process.env.PIPELINE_UPLOAD_TO}${verifyFlag}`, { stdio: 'inherit' });
    logEvent({ type: 'pipeline_upload_done', dest: process.env.PIPELINE_UPLOAD_TO });
  } catch (error) {
    logEvent({ type: 'pipeline_upload_failed', message: String(error?.message || error) });
    process.exit(1);
  }
}

console.log(JSON.stringify({
  type: 'db_pipeline_done',
  output: outputDir,
  ts: new Date().toISOString(),
}));
