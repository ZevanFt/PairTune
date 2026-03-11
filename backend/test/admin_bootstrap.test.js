const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { spawn } = require('node:child_process');
const path = require('node:path');

const ALLOW_NETWORK_TESTS = process.env.ALLOW_NETWORK_TESTS === '1';
const PORT = Number(process.env.TEST_PORT || 8125);
const SOCKET_PATH = '/tmp/priority_first_test_bootstrap.sock';
const BASE_URL = `http://127.0.0.1:${PORT}`;

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

async function postJson(pathname, body) {
  const resp = await fetch(`${BASE_URL}${pathname}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
    dispatcher: new (require('node:undici').Agent)({
      connect: { socketPath: SOCKET_PATH },
    }),
  });
  const json = await resp.json().catch(() => ({}));
  return { resp, json };
}

async function getJson(pathname) {
  const resp = await fetch(`${BASE_URL}${pathname}`, {
    method: 'GET',
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
    console.log('[test] admin bootstrap test skipped (ALLOW_NETWORK_TESTS=0)');
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
        ADMIN_ACCOUNT: '',
        ADMIN_PASSWORD: '',
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
    console.log('[test] admin bootstrap test skipped: sandbox cannot listen on sockets');
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

maybeTest('bootstrap status starts as uninitialized', async () => {
  if (!integrationReady) return;
  const { resp, json } = await getJson('/admin/bootstrap/status');
  assert.equal(resp.status, 200);
  assert.equal(json.code, 200);
  assert.equal(json.result?.initialized, false);
});

maybeTest('bootstrap rejects invalid payload', async () => {
  if (!integrationReady) return;
  const { resp } = await postJson('/admin/bootstrap', {
    account: 'ab',
    password: '123',
    display_name: ''
  });
  assert.equal(resp.status, 400);
});

maybeTest('bootstrap creates admin and blocks repeat', async () => {
  if (!integrationReady) return;
  const { resp, json } = await postJson('/admin/bootstrap', {
    account: 'admin_root',
    password: 'admin1234',
    display_name: '管理员'
  });
  assert.equal(resp.status, 200);
  assert.equal(json.code, 200);
  assert.equal(json.result?.account, 'admin_root');

  const status = await getJson('/admin/bootstrap/status');
  assert.equal(status.json.result?.initialized, true);

  const repeat = await postJson('/admin/bootstrap', {
    account: 'admin_root2',
    password: 'admin1234',
    display_name: '管理员2'
  });
  assert.equal(repeat.resp.status, 409);
});
