import { Card, Segmented, message } from 'antd';
import { useEffect, useState } from 'react';

import { SectionHeader } from '../components/SectionHeader';
import { StatCard } from '../components/StatCard';
import { SimpleTable } from '../components/SimpleTable';
import { fetchPointStats, PointStats } from '../services/admin';
import { t } from '../i18n';

const rangeOptions = [
  { label: t('dashboard.range7'), value: '7d' },
  { label: t('dashboard.range30'), value: '30d' },
  { label: t('dashboard.range90'), value: '90d' }
];

const formatNumber = (value: number) => new Intl.NumberFormat('zh-CN').format(value);

export function Points() {
  const [range, setRange] = useState('30d');
  const [stats, setStats] = useState<PointStats | null>(null);
  const [loading, setLoading] = useState(false);

  const load = async (nextRange: string) => {
    setLoading(true);
    try {
      const data = await fetchPointStats(nextRange);
      setStats(data);
    } catch {
      message.error(t('points.loadFail'));
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void load(range);
  }, [range]);

  return (
    <div className="space-y-6">
      <SectionHeader
        title={t('nav.points')}
        subtitle={t('points.subtitle')}
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
          label={t('points.issued')}
          value={formatNumber(stats?.issued || 0)}
          change={`${t('points.spent')}${formatNumber(stats?.spent || 0)}`}
        />
        <StatCard
          label={t('points.net')}
          value={formatNumber(stats?.net || 0)}
          change={`${t('points.balanceAvg')}${formatNumber(stats?.balance_avg || 0)}`}
        />
        <StatCard
          label={t('points.balanceTotal')}
          value={formatNumber(stats?.balance_total || 0)}
        />
        <StatCard
          label={t('points.reasonCount')}
          value={formatNumber(stats?.top_reasons.length || 0)}
        />
      </div>
      <Card className="shadow-soft rounded-xl2 border border-border">
        <div className="text-sm text-muted mb-3">{t('points.topReasons')}</div>
        <SimpleTable
          data={stats?.top_reasons || []}
          loading={loading}
          rowKey="reason"
          columns={[
            { title: t('points.reason'), dataIndex: 'reason' },
            { title: t('points.issued'), dataIndex: 'issued' },
            { title: t('points.spent'), dataIndex: 'spent' },
            { title: t('points.count'), dataIndex: 'count' }
          ]}
        />
      </Card>
    </div>
  );
}
