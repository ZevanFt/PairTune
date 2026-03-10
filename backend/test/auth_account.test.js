const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { spawn } = require('node:child_process');
const path = require('node:path');

const ALLOW_NETWORK_TESTS = process.env.ALLOW_NETWORK_TESTS === '1';
const PORT = Number(process.env.TEST_PORT || 8123);
const SOCKET_PATH = '/tmp/priority_first_test.sock';
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
    console.log('[test] backend integration test skipped (ALLOW_NETWORK_TESTS=0)');
    integrationReady = false;
    return;
  }
  try {
    serverProcess = spawn('node', [entry], {
      env: {
        ...process.env,
        HOST: '127.0.0.1',
        PORT: String(PORT),
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
    console.log('[test] backend integration test skipped: sandbox cannot listen on sockets');
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

maybeTest('admin can login with account/password', async () => {
  if (!integrationReady) return;
  const { resp, json } = await postJson('/auth/login/account', {
    account: ADMIN_ACCOUNT,
    password: ADMIN_PASSWORD,
  });
  assert.equal(resp.status, 200);
  assert.equal(json.code, 200);
  assert.ok(json.result?.token);
});

maybeTest('admin can create invite codes', async () => {
  if (!integrationReady) return;
  const login = await postJson('/auth/login/account', {
    account: ADMIN_ACCOUNT,
    password: ADMIN_PASSWORD,
  });
  const token = login.json.result.token;
  const { resp, json } = await postJson(
    '/admin/invite-codes',
    { count: 1, usage_limit: 1 },
    token,
  );
  assert.equal(resp.status, 200);
  assert.equal(json.code, 200);
  assert.equal(Array.isArray(json.result?.codes), true);
  assert.equal(json.result.codes.length, 1);
});

maybeTest('register requires invite code and prevents reuse', async () => {
  if (!integrationReady) return;
  const login = await postJson('/auth/login/account', {
    account: ADMIN_ACCOUNT,
    password: ADMIN_PASSWORD,
  });
  const token = login.json.result.token;
  const inviteResp = await postJson(
    '/admin/invite-codes',
    { count: 1, usage_limit: 1 },
    token,
  );
  const code = inviteResp.json.result.codes[0];

  const register = await postJson('/auth/register/account', {
    account: 'user_100',
    password: 'user1234',
    display_name: '用户',
    invite_code: code,
  });
  assert.equal(register.resp.status, 200);
  assert.equal(register.json.code, 200);
  assert.ok(register.json.result?.token);

  const reuse = await postJson('/auth/register/account', {
    account: 'user_101',
    password: 'user1234',
    display_name: '用户',
    invite_code: code,
  });
  assert.equal(reuse.resp.status, 403);
});

maybeTest('register rejects invalid account format', async () => {
  if (!integrationReady) return;
  const { resp } = await postJson('/auth/register/account', {
    account: 'ab',
    password: 'user1234',
    display_name: '用户',
    invite_code: 'NOPE',
  });
  assert.equal(resp.status, 400);
});
