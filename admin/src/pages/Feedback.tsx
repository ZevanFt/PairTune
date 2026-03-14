import { Button, Card, Input, Modal, Segmented, Select, message } from 'antd';
import { useEffect, useMemo, useState } from 'react';

import { SectionHeader } from '../components/SectionHeader';
import { StatCard } from '../components/StatCard';
import { SimpleTable } from '../components/SimpleTable';
import {
  FeedbackItem,
  FeedbackStats,
  exportFeedback,
  fetchFeedback,
  fetchFeedbackStats,
  updateFeedback
} from '../services/admin';
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

const statusOptions = [
  { label: t('feedback.statusAll'), value: 'all' },
  { label: t('feedback.statusNew'), value: 'new' },
  { label: t('feedback.statusTriaged'), value: 'triaged' },
  { label: t('feedback.statusResolved'), value: 'resolved' }
];

const formatNumber = (value: number) => new Intl.NumberFormat('zh-CN').format(value);

export function Feedback() {
  const [range, setRange] = useState('30d');
  const [owner, setOwner] = useState('all');
  const [category, setCategory] = useState('all');
  const [status, setStatus] = useState('all');
  const [keyword, setKeyword] = useState('');
  const [stats, setStats] = useState<FeedbackStats | null>(null);
  const [list, setList] = useState<FeedbackItem[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(false);
  const [, setTick] = useState(0);
  const [editing, setEditing] = useState<FeedbackItem | null>(null);
  const [saving, setSaving] = useState(false);
  const [editStatus, setEditStatus] = useState('new');
  const [editAssignee, setEditAssignee] = useState('');
  const [editNote, setEditNote] = useState('');
  const [appliedFilters, setAppliedFilters] = useState<{
    owner?: string;
    category?: string;
    status?: string;
    q?: string;
  }>({});

  const load = async (
    nextRange: string,
    filters?: { owner?: string; category?: string; status?: string; q?: string }
  ) => {
    setLoading(true);
    try {
      const [statsData, listData] = await Promise.all([
        fetchFeedbackStats(nextRange),
        fetchFeedback(nextRange, {
          owner: filters?.owner,
          category: filters?.category,
          status: filters?.status,
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
    void load(range, appliedFilters);
  }, [range, appliedFilters]);

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
    setAppliedFilters({
      owner: owner === 'all' ? undefined : owner,
      category: category === 'all' ? undefined : category,
      status: status === 'all' ? undefined : status,
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

  const handleExport = async () => {
    try {
      const result = await exportFeedback(range, {
        owner: owner === 'all' ? undefined : owner,
        category: category === 'all' ? undefined : category,
        status: status === 'all' ? undefined : status,
        q: keyword.trim() || undefined,
        limit: 2000
      });
      const csv = buildCsv(result.list);
      const blob = new window.Blob([csv], { type: 'text/csv;charset=utf-8;' });
      const url = window.URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.download = `feedback-${range}.csv`;
      document.body.appendChild(link);
      link.click();
      link.remove();
      window.URL.revokeObjectURL(url);
      message.success(t('feedback.exported'));
    } catch {
      message.error(t('feedback.exportFail'));
    }
  };

  const openEdit = (item: FeedbackItem) => {
    setEditing(item);
    setEditStatus(item.status || 'new');
    setEditAssignee(item.assignee || '');
    setEditNote(item.note || '');
  };

  const handleSaveEdit = async () => {
    if (!editing) return;
    setSaving(true);
    try {
      const updated = await updateFeedback(editing.id, {
        status: editStatus,
        assignee: editAssignee.trim() || null,
        note: editNote.trim() || null
      });
      setList((prev) => prev.map((item) => (item.id === updated.id ? updated : item)));
      message.success(t('feedback.updated'));
      setEditing(null);
    } catch {
      message.error(t('feedback.updateFail'));
    } finally {
      setSaving(false);
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
            <Button onClick={handleExport}>{t('feedback.export')}</Button>
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
          <Select
            value={status}
            onChange={(value) => setStatus(value)}
            options={statusOptions}
            style={{ width: 160 }}
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
            {
              title: t('feedback.status'),
              dataIndex: 'status',
              render: (value) => {
                const key = String(value || 'new');
                if (key === 'resolved') return t('feedback.statusResolved');
                if (key === 'triaged') return t('feedback.statusTriaged');
                return t('feedback.statusNew');
              }
            },
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
              title: t('feedback.assignee'),
              dataIndex: 'assignee',
              render: (value) => value || t('common.dash')
            },
            {
              title: t('feedback.note'),
              dataIndex: 'note',
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
              title: t('feedback.action'),
              render: (_, row) => (
                <div className="flex gap-2">
                  <Button size="small" onClick={() => handleCopy(row)}>
                    {t('feedback.copy')}
                  </Button>
                  <Button size="small" onClick={() => openEdit(row)}>
                    {t('feedback.handle')}
                  </Button>
                </div>
              )
            }
          ]}
          emptyText={t('feedback.empty')}
        />
      </Card>

      <Modal
        title={t('feedback.handleTitle')}
        open={Boolean(editing)}
        onOk={handleSaveEdit}
        confirmLoading={saving}
        onCancel={() => setEditing(null)}
        okText={t('feedback.handleSave')}
        cancelText={t('common.cancel')}
      >
        <div className="space-y-4">
          <div>
            <div className="text-xs text-muted mb-1">{t('feedback.status')}</div>
            <Select
              value={editStatus}
              onChange={(value) => setEditStatus(value)}
              options={statusOptions.filter((item) => item.value !== 'all')}
              style={{ width: '100%' }}
            />
          </div>
          <div>
            <div className="text-xs text-muted mb-1">{t('feedback.assignee')}</div>
            <Input
              placeholder={t('feedback.assigneePlaceholder')}
              value={editAssignee}
              onChange={(event) => setEditAssignee(event.target.value)}
            />
          </div>
          <div>
            <div className="text-xs text-muted mb-1">{t('feedback.note')}</div>
            <Input.TextArea
              placeholder={t('feedback.notePlaceholder')}
              value={editNote}
              onChange={(event) => setEditNote(event.target.value)}
              rows={4}
            />
          </div>
        </div>
      </Modal>
    </div>
  );
}

function buildCsv(list: FeedbackItem[]) {
  const header = [
    'id',
    'owner',
    'category',
    'status',
    'title',
    'detail',
    'contact',
    'assignee',
    'note',
    'created_at',
    'updated_at'
  ];
  const rows = list.map((item) => [
    item.id,
    item.owner,
    item.category,
    item.status,
    item.title,
    item.detail,
    item.contact || '',
    item.assignee || '',
    item.note || '',
    item.created_at,
    item.updated_at
  ]);
  return [header, ...rows].map((row) => row.map(csvEscape).join(',')).join('\n');
}

function csvEscape(value: unknown) {
  const text = String(value ?? '');
  if (text.includes('"') || text.includes(',') || text.includes('\n')) {
    return `"${text.replace(/"/g, '""')}"`;
  }
  return text;
}
