import { Card, Segmented, message } from 'antd';
import { useEffect, useMemo, useState } from 'react';

import { StatCard } from '../components/StatCard';
import { SectionHeader } from '../components/SectionHeader';
import { SimpleTable } from '../components/SimpleTable';
import { fetchOverview, fetchSeries, OverviewStats, SeriesStats } from '../services/admin';
import { t } from '../i18n';

const rangeOptions = [
  { label: t('dashboard.range7'), value: '7d' },
  { label: t('dashboard.range30'), value: '30d' },
  { label: t('dashboard.range90'), value: '90d' }
];

const formatNumber = (value: number) => new Intl.NumberFormat('zh-CN').format(value);

const formatPercent = (value: number) => `${(value * 100).toFixed(1)}%`;

export function Dashboard() {
  const [range, setRange] = useState('7d');
  const [overview, setOverview] = useState<OverviewStats | null>(null);
  const [series, setSeries] = useState<SeriesStats | null>(null);
  const [loading, setLoading] = useState(false);

  const load = async (nextRange: string) => {
    setLoading(true);
    try {
      const [overviewData, seriesData] = await Promise.all([
        fetchOverview(nextRange),
        fetchSeries(nextRange)
      ]);
      setOverview(overviewData);
      setSeries(seriesData);
    } catch {
      message.error(t('dashboard.loadFail'));
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void load(range);
  }, [range]);

  const seriesRows = useMemo(() => {
    if (!series?.series) return [];
    return series.series.map((row) => ({
      key: row.date,
      date: row.date,
      users_new: row.users_new,
      tasks_created: row.tasks_created,
      tasks_completed: row.tasks_completed,
      points_net: row.points_issued - row.points_spent,
      store_exchanges: row.store_exchanges
    }));
  }, [series]);

  return (
    <div className="space-y-6">
      <SectionHeader
        title={t('dashboard.headline')}
        subtitle={t('app.subtitle')}
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
          label={t('dashboard.users')}
          value={formatNumber(overview?.users.active || 0)}
          change={`${t('dashboard.newUsers')}${formatNumber(overview?.users.new || 0)}`}
        />
        <StatCard
          label={t('dashboard.tasks')}
          value={formatPercent(overview?.tasks.completion_rate || 0)}
          change={`${t('dashboard.tasksCreated')}${formatNumber(overview?.tasks.created || 0)}`}
        />
        <StatCard
          label={t('dashboard.points')}
          value={formatNumber(overview?.points.net || 0)}
          change={`${t('dashboard.pointsIssued')}${formatNumber(overview?.points.issued || 0)}`}
        />
        <StatCard
          label={t('dashboard.store')}
          value={formatNumber(overview?.store.exchanges || 0)}
          change={`${t('dashboard.storeProducts')}${formatNumber(overview?.store.products || 0)}`}
        />
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        <Card className="shadow-soft rounded-xl2 border border-border">
          <div className="text-sm text-muted mb-3">{t('dashboard.growth')}</div>
          <SimpleTable
            data={seriesRows}
            loading={loading}
            rowKey="date"
            columns={[
              { title: t('dashboard.table.date'), dataIndex: 'date' },
              { title: t('dashboard.table.usersNew'), dataIndex: 'users_new' },
              { title: t('dashboard.table.exchanges'), dataIndex: 'store_exchanges' }
            ]}
          />
        </Card>
        <Card className="shadow-soft rounded-xl2 border border-border">
          <div className="text-sm text-muted mb-3">{t('dashboard.overview')}</div>
          <SimpleTable
            data={seriesRows}
            loading={loading}
            rowKey="date"
            columns={[
              { title: t('dashboard.table.date'), dataIndex: 'date' },
              { title: t('dashboard.table.tasksCreated'), dataIndex: 'tasks_created' },
              { title: t('dashboard.table.tasksCompleted'), dataIndex: 'tasks_completed' },
              { title: t('dashboard.table.pointsNet'), dataIndex: 'points_net' }
            ]}
          />
        </Card>
      </div>
    </div>
  );
}
