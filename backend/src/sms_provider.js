function createSmsProvider() {
  const provider = String(process.env.SMS_PROVIDER || 'mock').trim().toLowerCase();

  if (provider === 'mock') {
    return {
      name: 'mock',
      async sendCode({ phone, code, purpose }) {
        // Mock provider: writes to stdout for local dev verification.
        // In production, replace with real SMS provider implementation.
        console.log(
          `[sms:mock] phone=${phone} code=${code} purpose=${purpose}`,
        );
        return { accepted: true, provider: 'mock' };
      },
    };
  }

  return {
    name: 'disabled',
    async sendCode() {
      throw new Error('短信服务未配置，请设置 SMS_PROVIDER');
    },
  };
}

module.exports = {
  createSmsProvider,
};

