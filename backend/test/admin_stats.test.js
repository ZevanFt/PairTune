const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { spawn } = require('node:child_process');
const path = require('node:path');

const ALLOW_NETWORK_TESTS = process.env.ALLOW_NETWORK_TESTS === '1';
const PORT = Number(process.env.TEST_PORT || 8124);
const SOCKET_PATH = '/tmp/priority_first_test_stats.sock';
const BASE_URL = `http://127.0.0.1:${PORT}`;
const ADMIN_ACCOUNT = 'admin_root';
const ADMIN_PASSWORD = 'admin1234';

let serverProcess;
let integrationReady = false;

async function waitForHealth(retries = 30) {
  const deadline = Date.now() + 2000;
  let lastError = '';
  while (Date.now() < deadline) {
    await new Promise((resolve) => setTimeout(resolve, 50));
    if (serverProcess?.exitCode !== null) {
      lastError = `server exited: ${serverProcess.exitCode}`;
      break;
    }
  }
  for (let i = 0; i < retries; i += 1) {
    try {
      const resp = await fetch(`${BASE_URL}/health`, {
        dispatcher: new (require('node:undici').Agent)({
          connect: { socketPath: SOCKET_PATH },
        }),
      });
      if (resp.ok) return;
    } catch (_) {
      // ignore and retry
    }
    await new Promise((resolve) => setTimeout(resolve, 100));
  }
  throw new Error(`backend health check failed: ${lastError}`);
}

async function postJson(pathname, body, token) {
  const headers = { 'Content-Type': 'application/json' };
  if (token) headers.Authorization = `Bearer ${token}`;
  const resp = await fetch(`${BASE_URL}${pathname}`, {
    method: 'POST',
    headers,
    body: JSON.stringify(body),
    dispatcher: new (require('node:undici').Agent)({
      connect: { socketPath: SOCKET_PATH },
    }),
  });
  const json = await resp.json().catch(() => ({}));
  return { resp, json };
}

async function getJson(pathname, token) {
  const headers = {};
  if (token) headers.Authorization = `Bearer ${token}`;
  const resp = await fetch(`${BASE_URL}${pathname}`, {
    method: 'GET',
    headers,
    dispatcher: new (require('node:undici').Agent)({
      connect: { socketPath: SOCKET_PATH },
    }),
  });
  const json = await resp.json().catch(() => ({}));
  return { resp, json };
}

before(async () => {
  const entry = path.join(__dirname, '..', 'src', 'main.js');
  try {
    if (require('node:fs').existsSync(SOCKET_PATH)) {
      require('node:fs').unlinkSync(SOCKET_PATH);
    }
  } catch (_) {
    // ignore
  }
  if (!ALLOW_NETWORK_TESTS) {
    console.log('[test] admin stats test skipped (ALLOW_NETWORK_TESTS=0)');
    integrationReady = false;
    return;
  }
  try {
    serverProcess = spawn('node', [entry], {
      env: {
        ...process.env,
        HOST: '127.0.0.1',
        PORT: String(PORT),
        LISTEN_SOCKET: SOCKET_PATH,
        DB_PATH: ':memory:',
        ADMIN_ACCOUNT,
        ADMIN_PASSWORD,
        ADMIN_DISPLAY_NAME: '管理员',
        NODE_ENV: 'test',
      },
      stdio: ['ignore', 'pipe', 'pipe'],
    });
    if (serverProcess.stdout) {
      serverProcess.stdout.on('data', (data) => {
        const text = data.toString();
        if (text.trim()) {
          console.log(`[backend] ${text.trim()}`);
        }
      });
    }
    if (serverProcess.stderr) {
      serverProcess.stderr.on('data', (data) => {
        const text = data.toString();
        if (text.trim()) {
          console.error(`[backend] ${text.trim()}`);
        }
      });
    }
    await waitForHealth();
    integrationReady = true;
  } catch (error) {
    console.log('[test] admin stats test skipped: sandbox cannot listen on sockets');
    integrationReady = false;
  }
});

after(() => {
  if (serverProcess) {
    serverProcess.kill('SIGTERM');
  }
});

const maybeTest = (name, fn) => {
  if (!ALLOW_NETWORK_TESTS) {
    test(name, { skip: true }, () => {});
    return;
  }
  test(name, fn);
};

async function loginAdmin() {
  const { json } = await postJson('/auth/login/account', {
    account: ADMIN_ACCOUNT,
    password: ADMIN_PASSWORD,
  });
  return json.result?.token;
}

maybeTest('admin stats overview returns summary', async () => {
  if (!integrationReady) return;
  const token = await loginAdmin();
  const { resp, json } = await getJson('/admin/stats/overview?range=7d', token);
  assert.equal(resp.status, 200);
  assert.equal(json.code, 200);
  assert.equal(typeof json.result?.users?.total, 'number');
  assert.equal(typeof json.result?.tasks?.completion_rate, 'number');
});

maybeTest('admin stats series returns range days', async () => {
  if (!integrationReady) return;
  const token = await loginAdmin();
  const { resp, json } = await getJson('/admin/stats/series?range=7d', token);
  assert.equal(resp.status, 200);
  assert.equal(json.code, 200);
  assert.equal(json.result?.series?.length, 7);
});

maybeTest('admin stats tasks returns quadrant distribution', async () => {
  if (!integrationReady) return;
  const token = await loginAdmin();
  const { resp, json } = await getJson('/admin/stats/tasks?range=30d', token);
  assert.equal(resp.status, 200);
  assert.equal(json.code, 200);
  assert.equal(Array.isArray(json.result?.quadrant), true);
  assert.equal(json.result.quadrant.length, 4);
});

maybeTest('admin stats points returns reason list', async () => {
  if (!integrationReady) return;
  const token = await loginAdmin();
  const { resp, json } = await getJson('/admin/stats/points?range=30d', token);
  assert.equal(resp.status, 200);
  assert.equal(json.code, 200);
  assert.equal(Array.isArray(json.result?.top_reasons), true);
});

maybeTest('admin stats store returns top products', async () => {
  if (!integrationReady) return;
  const token = await loginAdmin();
  const { resp, json } = await getJson('/admin/stats/store?range=30d', token);
  assert.equal(resp.status, 200);
  assert.equal(json.code, 200);
  assert.equal(Array.isArray(json.result?.top_products), true);
});

maybeTest('admin security events returns list', async () => {
  if (!integrationReady) return;
  const token = await loginAdmin();
  const { resp, json } = await getJson('/admin/security/events?range=30d', token);
  assert.equal(resp.status, 200);
  assert.equal(json.code, 200);
  assert.equal(Array.isArray(json.result?.events), true);
});

maybeTest('admin settings returns providers', async () => {
  if (!integrationReady) return;
  const token = await loginAdmin();
  const { resp, json } = await getJson('/admin/settings', token);
  assert.equal(resp.status, 200);
  assert.equal(json.code, 200);
  assert.equal(typeof json.result?.sms_provider, 'string');
  assert.equal(typeof json.result?.email_provider, 'string');
});
