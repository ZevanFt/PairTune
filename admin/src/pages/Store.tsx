import { Card, Segmented, message } from 'antd';
import { useEffect, useState } from 'react';

import { SectionHeader } from '../components/SectionHeader';
import { StatCard } from '../components/StatCard';
import { SimpleTable } from '../components/SimpleTable';
import { fetchStoreStats, StoreStats } from '../services/admin';
import { t } from '../i18n';

const rangeOptions = [
  { label: t('dashboard.range7'), value: '7d' },
  { label: t('dashboard.range30'), value: '30d' },
  { label: t('dashboard.range90'), value: '90d' }
];

const formatNumber = (value: number) => new Intl.NumberFormat('zh-CN').format(value);

export function Store() {
  const [range, setRange] = useState('30d');
  const [stats, setStats] = useState<StoreStats | null>(null);
  const [loading, setLoading] = useState(false);

  const load = async (nextRange: string) => {
    setLoading(true);
    try {
      const data = await fetchStoreStats(nextRange);
      setStats(data);
    } catch {
      message.error(t('store.loadFail'));
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
        title={t('nav.store')}
        subtitle={t('store.subtitle')}
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
          label={t('store.published')}
          value={formatNumber(stats?.products_published || 0)}
          change={`${t('store.totalProducts')}${formatNumber(stats?.products_total || 0)}`}
        />
        <StatCard
          label={t('store.exchanges')}
          value={formatNumber(stats?.exchanges || 0)}
          change={`${t('store.stockTotal')}${formatNumber(stats?.stock_total || 0)}`}
        />
      </div>
      <Card className="shadow-soft rounded-xl2 border border-border">
        <div className="text-sm text-muted mb-3">{t('store.topProducts')}</div>
        <SimpleTable
          data={stats?.top_products || []}
          loading={loading}
          rowKey="product_id"
          columns={[
            { title: t('store.productName'), dataIndex: 'name' },
            { title: t('store.exchangeCount'), dataIndex: 'exchanges' },
            { title: t('store.pointsSpent'), dataIndex: 'points_spent' },
            { title: t('store.stock'), dataIndex: 'stock' }
          ]}
        />
      </Card>
    </div>
  );
}
