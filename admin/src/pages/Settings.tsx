import { Button, Card, Input, Select, Switch, message } from 'antd';
import { useEffect, useState } from 'react';

import { SectionHeader } from '../components/SectionHeader';
import { StatCard } from '../components/StatCard';
import { AdminSettings, fetchAdminSettings, updateAdminSettings } from '../services/admin';
import { t } from '../i18n';

const formatValue = (value: string | null | undefined) => value || t('common.dash');

const smsOptions = [
  { value: 'mock', label: t('settings.smsProviderMock') },
  { value: 'tencent', label: t('settings.smsProviderTencent') }
];

const emailOptions = [
  { value: 'mock', label: t('settings.emailProviderMock') },
  { value: 'smtp', label: t('settings.emailProviderSmtp') }
];

export function Settings() {
  const [settings, setSettings] = useState<AdminSettings | null>(null);
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [siteName, setSiteName] = useState('');
  const [supportEmail, setSupportEmail] = useState('');
  const [supportPhone, setSupportPhone] = useState('');
  const [announcement, setAnnouncement] = useState('');
  const [maintenanceMode, setMaintenanceMode] = useState(false);
  const [smsProvider, setSmsProvider] = useState('mock');
  const [emailProvider, setEmailProvider] = useState('mock');

  const load = async () => {
    setLoading(true);
    try {
      const data = await fetchAdminSettings();
      setSettings(data);
      setSiteName(data.site_name || '');
      setSupportEmail(data.support_email || '');
      setSupportPhone(data.support_phone || '');
      setAnnouncement(data.announcement || '');
      setMaintenanceMode(Boolean(data.maintenance_mode));
      setSmsProvider(data.sms_provider || 'mock');
      setEmailProvider(data.email_provider || 'mock');
    } catch {
      message.error(t('settings.loadFail'));
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void load();
  }, []);

  const handleSave = async () => {
    if (!siteName.trim()) {
      message.warning(t('settings.siteNameRequired'));
      return;
    }
    setSaving(true);
    try {
      await updateAdminSettings({
        site_name: siteName.trim(),
        support_email: supportEmail.trim() || null,
        support_phone: supportPhone.trim() || null,
        announcement: announcement.trim() || null,
        maintenance_mode: maintenanceMode ? 1 : 0,
        sms_provider: smsProvider,
        email_provider: emailProvider
      });
      message.success(t('settings.saveOk'));
      void load();
    } catch {
      message.error(t('settings.saveFail'));
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="space-y-6">
      <SectionHeader title={t('nav.settings')} subtitle={t('settings.subtitle')} />
      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        <StatCard
          label={t('settings.runtimeSmsProvider')}
          value={formatValue(settings?.runtime_sms_provider)}
        />
        <StatCard
          label={t('settings.runtimeEmailProvider')}
          value={formatValue(settings?.runtime_email_provider)}
        />
        <StatCard
          label={t('settings.adminAccount')}
          value={formatValue(settings?.admin_account)}
        />
        <StatCard
          label={t('settings.nodeEnv')}
          value={formatValue(settings?.node_env)}
        />
      </div>
      <Card className="shadow-soft rounded-xl2 border border-border">
        <div className="flex items-center justify-between mb-4">
          <div className="text-sm text-muted">{t('settings.editable')}</div>
          <Button type="primary" onClick={handleSave} loading={saving}>
            {t('settings.save')}
          </Button>
        </div>
        <div className="grid gap-4 md:grid-cols-2">
          <div>
            <div className="text-xs text-muted mb-2">{t('settings.siteName')}</div>
            <Input value={siteName} onChange={(event) => setSiteName(event.target.value)} />
          </div>
          <div>
            <div className="text-xs text-muted mb-2">{t('settings.announcement')}</div>
            <Input value={announcement} onChange={(event) => setAnnouncement(event.target.value)} />
          </div>
          <div>
            <div className="text-xs text-muted mb-2">{t('settings.supportEmail')}</div>
            <Input value={supportEmail} onChange={(event) => setSupportEmail(event.target.value)} />
          </div>
          <div>
            <div className="text-xs text-muted mb-2">{t('settings.supportPhone')}</div>
            <Input value={supportPhone} onChange={(event) => setSupportPhone(event.target.value)} />
          </div>
          <div>
            <div className="text-xs text-muted mb-2">{t('settings.smsProvider')}</div>
            <Select
              value={smsProvider}
              options={smsOptions}
              onChange={(value) => setSmsProvider(value)}
              style={{ width: '100%' }}
            />
          </div>
          <div>
            <div className="text-xs text-muted mb-2">{t('settings.emailProvider')}</div>
            <Select
              value={emailProvider}
              options={emailOptions}
              onChange={(value) => setEmailProvider(value)}
              style={{ width: '100%' }}
            />
          </div>
          <div className="flex items-center justify-between md:col-span-2">
            <div>
              <div className="text-xs text-muted">{t('settings.maintenanceMode')}</div>
              <div className="text-xs text-muted">{t('settings.maintenanceHint')}</div>
            </div>
            <Switch checked={maintenanceMode} onChange={(value) => setMaintenanceMode(value)} />
          </div>
        </div>
        {settings?.settings_updated_at ? (
          <div className="text-xs text-muted mt-3">
            {t('settings.updatedAt')}: {formatValue(settings.settings_updated_at)}
          </div>
        ) : null}
      </Card>
      <Card className="shadow-soft rounded-xl2 border border-border">
        <div className="text-sm text-muted mb-3">{t('settings.runtime')}</div>
        <div className="grid gap-4 md:grid-cols-2">
          <div className="text-sm text-muted">{t('settings.serverTime')}</div>
          <div className="text-sm text-ink">{formatValue(settings?.server_time)}</div>
          <div className="text-sm text-muted">{t('settings.dbPath')}</div>
          <div className="text-sm text-ink">{formatValue(settings?.db_path)}</div>
          <div className="text-sm text-muted">{t('settings.adminName')}</div>
          <div className="text-sm text-ink">{formatValue(settings?.admin_display_name)}</div>
        </div>
        {loading ? <div className="text-xs text-muted mt-3">{t('common.loading')}</div> : null}
      </Card>
    </div>
  );
}
