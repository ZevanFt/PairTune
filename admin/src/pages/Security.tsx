import { Card, Segmented, message } from 'antd';
import { useEffect, useState } from 'react';

import { SectionHeader } from '../components/SectionHeader';
import { StatCard } from '../components/StatCard';
import { SimpleTable } from '../components/SimpleTable';
import { fetchSecurityEvents, SecurityStats } from '../services/admin';
import { t } from '../i18n';
import { formatAbsoluteChinaTime, formatAdminTime, onTimeFormatChange, toggleTimeFormatMode } from '../utils/timeFormat';

const rangeOptions = [
  { label: t('dashboard.range7'), value: '7d' },
  { label: t('dashboard.range30'), value: '30d' },
  { label: t('dashboard.range90'), value: '90d' }
];

const formatNumber = (value: number) => new Intl.NumberFormat('zh-CN').format(value);

export function Security() {
  const [range, setRange] = useState('30d');
  const [stats, setStats] = useState<SecurityStats | null>(null);
  const [loading, setLoading] = useState(false);
  const [, setTick] = useState(0);

  const load = async (nextRange: string) => {
    setLoading(true);
    try {
      const data = await fetchSecurityEvents(nextRange, 50);
      setStats(data);
    } catch {
      message.error(t('security.loadFail'));
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void load(range);
  }, [range]);

  useEffect(() => onTimeFormatChange(() => setTick((value) => value + 1)), []);

  return (
    <div className="space-y-6">
      <SectionHeader
        title={t('nav.security')}
        subtitle={t('security.subtitle')}
        action={(
          <Segmented
            options={rangeOptions}
            value={range}
            onChange={(value) => setRange(String(value))}
          />
        )}
      />
      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        <StatCard
          label={t('security.events')}
          value={formatNumber(stats?.total || 0)}
        />
        <StatCard
          label={t('security.failed')}
          value={formatNumber(stats?.failed || 0)}
        />
        <StatCard
          label={t('security.locked')}
          value={formatNumber(stats?.locked_users || 0)}
        />
      </div>
      <Card className="shadow-soft rounded-xl2 border border-border">
        <div className="text-sm text-muted mb-3">{t('security.recent')}</div>
        <SimpleTable
          data={stats?.events || []}
          loading={loading}
          rowKey="id"
          columns={[
            { title: t('security.action'), dataIndex: 'action' },
            {
              title: t('security.target'),
              render: (_, row) => row.email || row.phone || t('common.dash')
            },
            {
              title: t('security.success'),
              render: (_, row) => (row.success ? t('security.successYes') : t('security.successNo'))
            },
            { title: t('security.detail'), dataIndex: 'detail', render: (value) => value || t('common.dash') },
            {
              title: t('security.time'),
              dataIndex: 'created_at',
              render: (value) => {
                const display = formatAdminTime(value);
                const absolute = formatAbsoluteChinaTime(value);
                return (
                  <button
                    type="button"
                    className="time-cell"
                    onClick={toggleTimeFormatMode}
                    title={absolute ? `${absolute} · ${t('topbar.timeToggleHint')}` : t('topbar.timeToggleHint')}
                  >
                    <span className="time-cell-icon">⟳</span>
                    {display || t('common.dash')}
                  </button>
                );
              }
            }
          ]}
        />
      </Card>
    </div>
  );
}
