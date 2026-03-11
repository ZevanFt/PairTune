import { useEffect, useState } from 'react';
import { Button, Card, InputNumber, message, Modal } from 'antd';

import { SectionHeader } from '../components/SectionHeader';
import { StatusBadge } from '../components/StatusBadge';
import { SimpleTable } from '../components/SimpleTable';
import { createInvites, disableInvite, fetchInvites, InviteCode } from '../services/admin';
import { t } from '../i18n';

export function Invites() {
  const [data, setData] = useState<InviteCode[]>([]);
  const [loading, setLoading] = useState(false);
  const [open, setOpen] = useState(false);
  const [count, setCount] = useState(5);
  const [usageLimit, setUsageLimit] = useState(1);

  const load = async () => {
    setLoading(true);
    try {
      const result = await fetchInvites();
      setData(result);
    } catch {
      message.error(t('invites.loadFail'));
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void load();
  }, []);

  const handleCreate = async () => {
    if (count <= 0 || usageLimit <= 0) {
      message.warning(t('invites.invalidInput'));
      return;
    }
    try {
      await createInvites(count, usageLimit);
      message.success(t('invites.createOk'));
      setOpen(false);
      void load();
    } catch {
      message.error(t('invites.createFail'));
    }
  };

  const handleDisable = async (code: string) => {
    try {
      await disableInvite(code);
      message.success(t('invites.disableOk'));
      void load();
    } catch {
      message.error(t('invites.disableFail'));
    }
  };

  return (
    <div className="space-y-6">
      <SectionHeader
        title={t('invites.headline')}
        subtitle={t('invites.subtitle')}
        action={<Button type="primary" onClick={() => setOpen(true)}>{t('invites.create')}</Button>}
      />
      <Card className="shadow-soft rounded-xl2 border border-border">
        <SimpleTable
          data={data}
          rowKey="id"
          loading={loading}
          columns={[
            { title: t('invites.columns.code'), dataIndex: 'code' },
            { title: t('invites.columns.status'), dataIndex: 'status', render: (value) => <StatusBadge value={String(value)} /> },
            { title: t('invites.columns.usage'), render: (_, row) => `${row.used_count}/${row.usage_limit}` },
            { title: t('invites.columns.created'), dataIndex: 'created_at' },
            { title: t('invites.columns.used'), dataIndex: 'used_at', render: (value) => value || t('common.dash') },
            {
              title: t('invites.columns.action'),
              render: (_, row) => (
                <Button size="small" onClick={() => handleDisable(row.code)} disabled={row.status !== 'active'}>
                  {t('invites.disable')}
                </Button>
              )
            }
          ]}
        />
      </Card>

      <Modal
        title={t('invites.create')}
        open={open}
        onCancel={() => setOpen(false)}
        onOk={handleCreate}
      >
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <div>{t('invites.count')}</div>
            <InputNumber min={1} max={50} value={count} onChange={(value) => setCount(value || 1)} />
          </div>
          <div className="flex items-center justify-between">
            <div>{t('invites.limit')}</div>
            <InputNumber min={1} max={10} value={usageLimit} onChange={(value) => setUsageLimit(value || 1)} />
          </div>
        </div>
      </Modal>
    </div>
  );
}
