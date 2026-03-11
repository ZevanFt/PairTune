import { useState } from 'react';
import { Button, Card, Form, Input, message } from 'antd';

import { t } from '../i18n';
import { bootstrapAdmin } from '../services/admin';

interface InitProps {
  onSuccess: () => void;
}

export function Init({ onSuccess }: InitProps) {
  const [loading, setLoading] = useState(false);
  const [form] = Form.useForm();

  const handleFinish = async (values: {
    account: string;
    password: string;
    password_confirm: string;
    display_name: string;
  }) => {
    if (!values.account || !values.password || !values.display_name) {
      message.warning(t('init.emptyError'));
      return;
    }
    if (values.password !== values.password_confirm) {
      message.warning(t('init.confirmMismatch'));
      return;
    }
    setLoading(true);
    try {
      await bootstrapAdmin({
        account: values.account.trim(),
        password: values.password,
        display_name: values.display_name.trim()
      });
      message.success(t('init.success'));
      form.resetFields();
      onSuccess();
    } catch {
      message.error(t('init.failed'));
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center px-6">
      <Card className="w-full max-w-md shadow-glow border border-border rounded-xl2">
        <div className="mb-6">
          <div className="text-xl font-semibold text-ink">{t('init.title')}</div>
          <div className="text-sm text-muted">{t('init.hint')}</div>
        </div>
        <Form form={form} layout="vertical" onFinish={handleFinish}>
          <Form.Item name="account" label={t('init.account')} rules={[{ required: true }]}>
            <Input placeholder={t('init.accountPlaceholder')} />
          </Form.Item>
          <Form.Item name="display_name" label={t('init.displayName')} rules={[{ required: true }]}>
            <Input placeholder={t('init.displayNamePlaceholder')} />
          </Form.Item>
          <Form.Item name="password" label={t('init.password')} rules={[{ required: true }]}>
            <Input.Password placeholder={t('init.passwordPlaceholder')} />
          </Form.Item>
          <Form.Item name="password_confirm" label={t('init.passwordConfirm')} rules={[{ required: true }]}>
            <Input.Password placeholder={t('init.passwordConfirmPlaceholder')} />
          </Form.Item>
          <Button type="primary" htmlType="submit" loading={loading} block>
            {t('init.action')}
          </Button>
        </Form>
      </Card>
    </div>
  );
}
