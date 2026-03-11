import { Card, Segmented, message } from 'antd';
import { useEffect, useMemo, useState } from 'react';

import { SectionHeader } from '../components/SectionHeader';
import { StatCard } from '../components/StatCard';
import { SimpleTable } from '../components/SimpleTable';
import { fetchTaskStats, TaskStats } from '../services/admin';
import { t } from '../i18n';

const rangeOptions = [
  { label: t('dashboard.range7'), value: '7d' },
  { label: t('dashboard.range30'), value: '30d' },
  { label: t('dashboard.range90'), value: '90d' }
];

const formatNumber = (value: number) => new Intl.NumberFormat('zh-CN').format(value);
const formatPercent = (value: number) => `${(value * 100).toFixed(1)}%`;

export function Tasks() {
  const [range, setRange] = useState('30d');
  const [stats, setStats] = useState<TaskStats | null>(null);
  const [loading, setLoading] = useState(false);

  const load = async (nextRange: string) => {
    setLoading(true);
    try {
      const data = await fetchTaskStats(nextRange);
      setStats(data);
    } catch {
      message.error(t('tasks.loadFail'));
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void load(range);
  }, [range]);

  const quadrantRows = useMemo(() => {
    const total = stats?.created || 0;
    return (stats?.quadrant || []).map((row) => ({
      key: row.quadrant,
      quadrant: row.quadrant,
      count: row.count,
      ratio: total ? formatPercent(row.count / total) : '0.0%'
    }));
  }, [stats]);

  return (
    <div className="space-y-6">
      <SectionHeader
        title={t('nav.tasks')}
        subtitle={t('tasks.subtitle')}
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
          label={t('tasks.created')}
          value={formatNumber(stats?.created || 0)}
          change={`${t('tasks.completed')}${formatNumber(stats?.completed || 0)}`}
        />
        <StatCard
          label={t('tasks.completionRate')}
          value={formatPercent(stats?.completion_rate || 0)}
          change={`${t('tasks.repeat')}${formatNumber(stats?.repeat?.count || 0)}`}
        />
        <StatCard
          label={t('tasks.repeatRatio')}
          value={formatPercent(stats?.repeat?.ratio || 0)}
        />
        <StatCard
          label={t('tasks.quadrantTotal')}
          value={formatNumber(stats?.quadrant.reduce((sum, row) => sum + row.count, 0) || 0)}
        />
      </div>
      <Card className="shadow-soft rounded-xl2 border border-border">
        <div className="text-sm text-muted mb-3">{t('tasks.quadrantTitle')}</div>
        <SimpleTable
          data={quadrantRows}
          loading={loading}
          rowKey="quadrant"
          columns={[
            { title: t('tasks.quadrant'), dataIndex: 'quadrant' },
            { title: t('tasks.count'), dataIndex: 'count' },
            { title: t('tasks.ratio'), dataIndex: 'ratio' }
          ]}
        />
      </Card>
    </div>
  );
}
