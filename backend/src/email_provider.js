const crypto = require('crypto');
const net = require('net');

function isEmpty(v) {
  return v === undefined || v === null || String(v).trim() === '';
}

function createMockProvider() {
  return {
    name: 'mock',
    async sendCode({ email, code, purpose }) {
      console.log(`[email:mock] email=${email} code=${code} purpose=${purpose}`);
      return { accepted: true, provider: 'mock' };
    },
  };
}

function createDisabledProvider(reason) {
  return {
    name: 'disabled',
    async sendCode() {
      throw new Error(reason || '邮件服务未配置，请设置 EMAIL_PROVIDER');
    },
  };
}

function sendSmtp({ host, port, secure, authUser, authPass, from, to, subject, text }) {
  return new Promise((resolve, reject) => {
    const socket = net.createConnection(port, host);
    socket.setTimeout(12000);
    const lines = [];
    const write = (line) => {
      socket.write(`${line}\r\n`);
    };
    const next = () => {
      const command = lines.shift();
      if (command) {
        write(command);
      } else {
        socket.end();
        resolve({ accepted: true, provider: 'smtp' });
      }
    };
    socket.on('data', (data) => {
      const msg = data.toString();
      if (/^2|^3/.test(msg)) {
        next();
      } else if (/^4|^5/.test(msg)) {
        socket.end();
        reject(new Error(`SMTP 错误: ${msg.trim()}`));
      }
    });
    socket.on('timeout', () => {
      socket.end();
      reject(new Error('SMTP 超时'));
    });
    socket.on('error', reject);

    const boundary = crypto.randomBytes(8).toString('hex');
    const mime = [
      `From: ${from}`,
      `To: ${to}`,
      `Subject: ${subject}`,
      'MIME-Version: 1.0',
      `Content-Type: multipart/alternative; boundary="${boundary}"`,
      '',
      `--${boundary}`,
      'Content-Type: text/plain; charset="UTF-8"',
      '',
      text,
      `--${boundary}--`,
      '',
    ].join('\r\n');

    lines.push(`EHLO ${host}`);
    if (!secure) {
      // no STARTTLS implemented in this minimal SMTP sender
    }
    if (!isEmpty(authUser) && !isEmpty(authPass)) {
      const auth = Buffer.from(`\u0000${authUser}\u0000${authPass}`).toString('base64');
      lines.push('AUTH PLAIN ' + auth);
    }
    lines.push(`MAIL FROM:<${from}>`);
    lines.push(`RCPT TO:<${to}>`);
    lines.push('DATA');
    lines.push(mime + '\r\n.');
    lines.push('QUIT');
  });
}

function createSmtpProvider() {
  const host = process.env.EMAIL_SMTP_HOST;
  const port = Number(process.env.EMAIL_SMTP_PORT || 25);
  const secure = String(process.env.EMAIL_SMTP_SECURE || 'false') === 'true';
  const user = process.env.EMAIL_SMTP_USER;
  const pass = process.env.EMAIL_SMTP_PASS;
  const from = process.env.EMAIL_FROM;
  const subjectTpl = process.env.EMAIL_SUBJECT || '合拍验证码';

  if ([host, from].some(isEmpty)) {
    return createDisabledProvider(
      'SMTP 邮件配置不完整，请设置 EMAIL_SMTP_HOST / EMAIL_FROM',
    );
  }

  return {
    name: 'smtp',
    async sendCode({ email, code, purpose }) {
      const subject = subjectTpl;
      const text = `你的验证码是 ${code}，5 分钟内有效。用途：${purpose}`;
      return sendSmtp({
        host,
        port,
        secure,
        authUser: user,
        authPass: pass,
        from,
        to: email,
        subject,
        text,
      });
    },
  };
}

function createEmailProvider() {
  const provider = String(process.env.EMAIL_PROVIDER || 'mock').trim().toLowerCase();
  if (provider === 'mock') return createMockProvider();
  if (provider === 'smtp') return createSmtpProvider();
  return createDisabledProvider(`不支持的邮件 provider: ${provider}`);
}

module.exports = { createEmailProvider };
