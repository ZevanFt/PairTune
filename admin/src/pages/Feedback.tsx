import { Button, Card, Input, Segmented, Select, message } from 'antd';
import { useEffect, useMemo, useState } from 'react';

import { SectionHeader } from '../components/SectionHeader';
import { StatCard } from '../components/StatCard';
import { SimpleTable } from '../components/SimpleTable';
import { FeedbackItem, FeedbackStats, fetchFeedback, fetchFeedbackStats } from '../services/admin';
import { t } from '../i18n';
import { formatAbsoluteChinaTime, formatAdminTime, onTimeFormatChange, toggleTimeFormatMode } from '../utils/timeFormat';

const rangeOptions = [
  { label: t('dashboard.range7'), value: '7d' },
  { label: t('dashboard.range30'), value: '30d' },
  { label: t('dashboard.range90'), value: '90d' }
];

const ownerOptions = [
  { label: t('feedback.ownerAll'), value: 'all' },
  { label: t('feedback.ownerMe'), value: 'me' },
  { label: t('feedback.ownerPartner'), value: 'partner' }
];

const formatNumber = (value: number) => new Intl.NumberFormat('zh-CN').format(value);

export function Feedback() {
  const [range, setRange] = useState('30d');
  const [owner, setOwner] = useState('all');
  const [category, setCategory] = useState('all');
  const [keyword, setKeyword] = useState('');
  const [stats, setStats] = useState<FeedbackStats | null>(null);
  const [list, setList] = useState<FeedbackItem[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(false);
  const [, setTick] = useState(0);

  const load = async (nextRange: string, filters?: { owner?: string; category?: string; q?: string }) => {
    setLoading(true);
    try {
      const [statsData, listData] = await Promise.all([
        fetchFeedbackStats(nextRange),
        fetchFeedback(nextRange, {
          owner: filters?.owner,
          category: filters?.category,
          q: filters?.q,
          limit: 80
        })
      ]);
      setStats(statsData);
      setList(listData.list);
      setTotal(listData.total);
    } catch {
      message.error(t('feedback.loadFail'));
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void load(range);
  }, [range]);

  useEffect(() => onTimeFormatChange(() => setTick((value) => value + 1)), []);

  const categories = useMemo(() => {
    const base = stats?.by_category?.map((item) => item.category) || [];
    const unique = Array.from(new Set(base));
    return ['all', ...unique];
  }, [stats]);

  const ownerCounts = useMemo(() => {
    const map = new Map(stats?.by_owner?.map((item) => [item.owner, item.count]));
    return {
      me: map.get('me') || 0,
      partner: map.get('partner') || 0
    };
  }, [stats]);

  const topCategory = useMemo(() => {
    if (!stats?.by_category?.length) return t('common.dash');
    const top = stats.by_category[0];
    return `${top.category} · ${formatNumber(top.count)}`;
  }, [stats]);

  const handleApply = () => {
    void load(range, {
      owner: owner === 'all' ? undefined : owner,
      category: category === 'all' ? undefined : category,
      q: keyword.trim() || undefined
    });
  };

  const handleCopy = async (item: FeedbackItem) => {
    const payload = JSON.stringify(item, null, 2);
    try {
      await window.navigator.clipboard.writeText(payload);
      message.success(t('feedback.copied'));
    } catch {
      message.error(t('feedback.copyFail'));
    }
  };

  return (
    <div className="space-y-6">
      <SectionHeader
        title={t('nav.feedback')}
        subtitle={t('feedback.subtitle')}
        action={(
          <div className="flex items-center gap-2">
            <Segmented
              options={rangeOptions}
              value={range}
              onChange={(value) => setRange(String(value))}
            />
            <Button onClick={handleApply}>{t('common.refresh')}</Button>
          </div>
        )}
      />

      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        <StatCard label={t('feedback.total')} value={formatNumber(total)} />
        <StatCard label={t('feedback.ownerMe')} value={formatNumber(ownerCounts.me)} />
        <StatCard label={t('feedback.ownerPartner')} value={formatNumber(ownerCounts.partner)} />
        <StatCard label={t('feedback.topCategory')} value={topCategory} />
      </div>

      <Card className="shadow-soft rounded-xl2 border border-border">
        <div className="flex flex-wrap gap-3 items-center mb-4">
          <Select
            value={owner}
            onChange={(value) => setOwner(value)}
            options={ownerOptions}
            style={{ width: 140 }}
          />
          <Select
            value={category}
            onChange={(value) => setCategory(value)}
            options={categories.map((item) => ({
              value: item,
              label: item === 'all' ? t('feedback.categoryAll') : item
            }))}
            style={{ width: 180 }}
          />
          <Input
            placeholder={t('feedback.searchPlaceholder')}
            value={keyword}
            onChange={(event) => setKeyword(event.target.value)}
            style={{ width: 240 }}
          />
          <Button type="primary" onClick={handleApply}>{t('feedback.filterApply')}</Button>
        </div>

        <SimpleTable
          data={list}
          loading={loading}
          rowKey="id"
          columns={[
            {
              title: t('feedback.time'),
              dataIndex: 'created_at',
              render: (value) => {
                const display = formatAdminTime(value as string);
                const absolute = formatAbsoluteChinaTime(value as string);
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
            },
            { title: t('feedback.owner'), dataIndex: 'owner' },
            { title: t('feedback.category'), dataIndex: 'category' },
            { title: t('feedback.title'), dataIndex: 'title' },
            {
              title: t('feedback.detail'),
              dataIndex: 'detail',
              render: (value) => (
                <span
                  style={{
                    display: '-webkit-box',
                    WebkitLineClamp: 2,
                    WebkitBoxOrient: 'vertical',
                    overflow: 'hidden'
                  }}
                >
                  {String(value || t('common.dash'))}
                </span>
              )
            },
            {
              title: t('feedback.contact'),
              dataIndex: 'contact',
              render: (value) => value || t('common.dash')
            },
            {
              title: t('feedback.action'),
              render: (_, row) => (
                <Button size="small" onClick={() => handleCopy(row)}>
                  {t('feedback.copy')}
                </Button>
              )
            }
          ]}
          emptyText={t('feedback.empty')}
        />
      </Card>
    </div>
  );
}
