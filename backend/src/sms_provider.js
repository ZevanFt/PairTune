const crypto = require('crypto');
const https = require('https');

function sha256Hex(input) {
  return crypto.createHash('sha256').update(input).digest('hex');
}

function hmacSha256(key, input, encoding = undefined) {
  const h = crypto.createHmac('sha256', key);
  h.update(input);
  return h.digest(encoding);
}

function isEmpty(v) {
  return v === undefined || v === null || String(v).trim() === '';
}

function postJson({ host, headers, body }) {
  const payload = JSON.stringify(body);
  return new Promise((resolve, reject) => {
    const req = https.request(
      {
        protocol: 'https:',
        hostname: host,
        method: 'POST',
        path: '/',
        headers: {
          ...headers,
          'Content-Length': Buffer.byteLength(payload),
        },
      },
      (res) => {
        let raw = '';
        res.setEncoding('utf8');
        res.on('data', (chunk) => {
          raw += chunk;
        });
        res.on('end', () => {
          if (res.statusCode < 200 || res.statusCode >= 300) {
            return reject(
              new Error(`短信网关 HTTP ${res.statusCode}: ${raw.slice(0, 200)}`),
            );
          }
          try {
            resolve(JSON.parse(raw));
          } catch (e) {
            reject(new Error(`短信网关响应非 JSON: ${raw.slice(0, 200)}`));
          }
        });
      },
    );
    req.on('error', reject);
    req.write(payload);
    req.end();
  });
}

function createMockProvider() {
  return {
    name: 'mock',
    async sendCode({ phone, code, purpose }) {
      console.log(`[sms:mock] phone=${phone} code=${code} purpose=${purpose}`);
      return { accepted: true, provider: 'mock' };
    },
  };
}

function createDisabledProvider(reason) {
  return {
    name: 'disabled',
    async sendCode() {
      throw new Error(reason || '短信服务未配置，请设置 SMS_PROVIDER');
    },
  };
}

function createTencentProvider() {
  const secretId = process.env.TENCENT_SMS_SECRET_ID;
  const secretKey = process.env.TENCENT_SMS_SECRET_KEY;
  const sdkAppId = process.env.TENCENT_SMS_SDK_APP_ID;
  const signName = process.env.TENCENT_SMS_SIGN_NAME;
  const templateId = process.env.TENCENT_SMS_TEMPLATE_ID;
  const region = process.env.TENCENT_SMS_REGION || 'ap-guangzhou';
  const host = process.env.TENCENT_SMS_HOST || 'sms.tencentcloudapi.com';
  const version = '2021-01-11';
  const service = 'sms';

  if ([secretId, secretKey, sdkAppId, signName, templateId].some(isEmpty)) {
    return createDisabledProvider(
      '腾讯云短信配置不完整，请设置 TENCENT_SMS_SECRET_ID/TENCENT_SMS_SECRET_KEY/TENCENT_SMS_SDK_APP_ID/TENCENT_SMS_SIGN_NAME/TENCENT_SMS_TEMPLATE_ID',
    );
  }

  return {
    name: 'tencent',
    async sendCode({ phone, code, purpose }) {
      const now = new Date();
      const timestamp = Math.floor(now.getTime() / 1000);
      const date = now.toISOString().slice(0, 10);
      const payload = {
        SmsSdkAppId: String(sdkAppId),
        SignName: String(signName),
        TemplateId: String(templateId),
        TemplateParamSet: [String(code), '5'],
        PhoneNumberSet: [`+86${String(phone).trim()}`],
        SessionContext: String(purpose || 'login'),
      };

      const canonicalHeaders = `content-type:application/json; charset=utf-8\nhost:${host}\n`;
      const signedHeaders = 'content-type;host';
      const hashedPayload = sha256Hex(JSON.stringify(payload));
      const canonicalRequest =
        `POST\n/\n\n${canonicalHeaders}\n${signedHeaders}\n${hashedPayload}`;
      const credentialScope = `${date}/${service}/tc3_request`;
      const stringToSign =
        `TC3-HMAC-SHA256\n${timestamp}\n${credentialScope}\n${sha256Hex(canonicalRequest)}`;

      const secretDate = hmacSha256(`TC3${secretKey}`, date);
      const secretService = hmacSha256(secretDate, service);
      const secretSigning = hmacSha256(secretService, 'tc3_request');
      const signature = hmacSha256(secretSigning, stringToSign, 'hex');
      const authorization =
        `TC3-HMAC-SHA256 Credential=${secretId}/${credentialScope}, ` +
        `SignedHeaders=${signedHeaders}, Signature=${signature}`;

      const response = await postJson({
        host,
        body: payload,
        headers: {
          Authorization: authorization,
          'Content-Type': 'application/json; charset=utf-8',
          Host: host,
          'X-TC-Action': 'SendSms',
          'X-TC-Version': version,
          'X-TC-Region': region,
          'X-TC-Timestamp': String(timestamp),
        },
      });

      const root = response.Response || {};
      if (root.Error) {
        throw new Error(
          `腾讯云短信错误: ${root.Error.Code || 'Unknown'} ${root.Error.Message || ''}`.trim(),
        );
      }
      const status = Array.isArray(root.SendStatusSet) ? root.SendStatusSet[0] : null;
      if (status && status.Code && status.Code !== 'Ok') {
        throw new Error(`腾讯云短信发送失败: ${status.Code} ${status.Message || ''}`.trim());
      }

      return {
        accepted: true,
        provider: 'tencent',
        requestId: root.RequestId || null,
      };
    },
  };
}

function createSmsProvider() {
  const provider = String(process.env.SMS_PROVIDER || 'mock').trim().toLowerCase();
  if (provider === 'mock') return createMockProvider();
  if (provider === 'tencent') return createTencentProvider();
  return createDisabledProvider(`不支持的短信 provider: ${provider}`);
}

module.exports = { createSmsProvider };
