const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { execSync } = require('node:child_process');
const zlib = require('zlib');

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

function sha256File(filePath) {
  return crypto.createHash('sha256').update(fs.readFileSync(filePath)).digest('hex');
}

function writeSha(filePath) {
  const hash = sha256File(filePath);
  fs.writeFileSync(`${filePath}.sha256`, `${hash}  ${path.basename(filePath)}\n`, 'utf8');
  return hash;
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

const outputDir = resolveOutputDir();
const bundleName = path.basename(outputDir);
const sqlPath = path.join(outputDir, 'snapshot.sql');
const jsonPath = path.join(outputDir, 'snapshot.json');

execSync(`node ${path.join(__dirname, 'export_sql.js')} --out ${sqlPath}`, { stdio: 'inherit' });
execSync(`node ${path.join(__dirname, 'export.js')} --out ${jsonPath}`, { stdio: 'inherit' });

const migrateDir = path.join(__dirname, '..', 'migrations');
const bundleMigrations = path.join(outputDir, 'migrations');
if (!fs.existsSync(bundleMigrations)) {
  fs.mkdirSync(bundleMigrations, { recursive: true });
}
fs.readdirSync(migrateDir)
  .filter((file) => file.endsWith('.sql'))
  .forEach((file) => {
    fs.copyFileSync(path.join(migrateDir, file), path.join(bundleMigrations, file));
  });

fs.writeFileSync(
  path.join(outputDir, 'README.txt'),
  [
    'Priority First database bundle',
    `Exported at: ${new Date().toISOString()}`,
    `Contains: snapshot.sql, snapshot.json, migrations/`,
  ].join('\n'),
  'utf8',
);

const manifest = {
  exported_at: new Date().toISOString(),
  files: {},
};

listFiles(outputDir)
  .filter((file) => !file.endsWith('.sha256') && !file.endsWith('.gz'))
  .forEach((file) => {
    const relative = path.relative(outputDir, file).replace(/\\/g, '/');
    manifest.files[relative] = writeSha(file);
  });

fs.writeFileSync(path.join(outputDir, 'MANIFEST.json'), JSON.stringify(manifest, null, 2), 'utf8');
writeSha(path.join(outputDir, 'MANIFEST.json'));

const bundleGz = `${outputDir}.tar.gz`;
const tarList = listFiles(outputDir)
  .map((file) => path.relative(path.dirname(outputDir), file))
  .join('\n');
const tarPath = path.join(path.dirname(outputDir), `${bundleName}.tar`);
try {
  const tarCommand = `tar -cf ${tarPath} -C ${path.dirname(outputDir)} ${bundleName}`;
  execSync(tarCommand, { stdio: 'inherit' });
  const tarData = fs.readFileSync(tarPath);
  fs.writeFileSync(bundleGz, zlib.gzipSync(tarData));
  fs.unlinkSync(tarPath);
  writeSha(bundleGz);
} catch (error) {
  console.error(JSON.stringify({
    type: 'db_export_bundle_archive_failed',
    message: String(error?.message || error),
    ts: new Date().toISOString(),
  }));
}

console.log(JSON.stringify({
  type: 'db_export_bundle_done',
  output: outputDir,
  archive: bundleGz,
  ts: new Date().toISOString(),
}));
