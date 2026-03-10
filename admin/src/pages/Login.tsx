import { useState } from 'react';
import { Button, Card, Form, Input, message } from 'antd';

import { t } from '../i18n';
import { login } from '../services/auth';

interface LoginProps {
  onSuccess: () => void;
}

export function Login({ onSuccess }: LoginProps) {
  const [loading, setLoading] = useState(false);

  const handleFinish = async (values: { account: string; password: string }) => {
    if (!values.account || !values.password) {
      message.warning(t('login.emptyError'));
      return;
    }
    setLoading(true);
    try {
      const session = await login(values.account.trim(), values.password);
      if (session.user.role !== 'admin' && !session.user.permissions?.includes('admin.full')) {
        message.error(t('login.forbidden'));
        return;
      }
      localStorage.setItem('admin_token', session.token);
      localStorage.setItem('admin_user', JSON.stringify(session.user));
      onSuccess();
    } catch (error) {
      message.error(t('login.failed'));
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center px-6">
      <Card className="w-full max-w-md shadow-glow border border-border rounded-xl2">
        <div className="mb-6">
          <div className="text-xl font-semibold text-ink">{t('login.title')}</div>
          <div className="text-sm text-muted">{t('login.hint')}</div>
        </div>
        <Form layout="vertical" onFinish={handleFinish}>
          <Form.Item name="account" label={t('login.account')} rules={[{ required: true }]}>
            <Input placeholder={t('login.accountPlaceholder')} />
          </Form.Item>
          <Form.Item name="password" label={t('login.password')} rules={[{ required: true }]}>
            <Input.Password placeholder={t('login.passwordPlaceholder')} />
          </Form.Item>
          <Button type="primary" htmlType="submit" loading={loading} block>
            {t('login.action')}
          </Button>
        </Form>
      </Card>
    </div>
  );
}
