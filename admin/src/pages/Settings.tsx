import { Card, message } from 'antd';
import { useEffect, useState } from 'react';

import { SectionHeader } from '../components/SectionHeader';
import { StatCard } from '../components/StatCard';
import { AdminSettings, fetchAdminSettings } from '../services/admin';
import { t } from '../i18n';

const formatValue = (value: string | null | undefined) => value || t('common.dash');

export function Settings() {
  const [settings, setSettings] = useState<AdminSettings | null>(null);
  const [loading, setLoading] = useState(false);

  const load = async () => {
    setLoading(true);
    try {
      const data = await fetchAdminSettings();
      setSettings(data);
    } catch {
      message.error(t('settings.loadFail'));
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void load();
  }, []);

  return (
    <div className="space-y-6">
      <SectionHeader title={t('nav.settings')} subtitle={t('settings.subtitle')} />
      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        <StatCard
          label={t('settings.smsProvider')}
          value={formatValue(settings?.sms_provider)}
        />
        <StatCard
          label={t('settings.emailProvider')}
          value={formatValue(settings?.email_provider)}
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
