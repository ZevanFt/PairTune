import { useEffect, useState } from 'react';
import { Card, Empty, Table, Tag, message } from 'antd';

import { SectionHeader } from '../components/SectionHeader';
import { AdminUser, fetchUsers } from '../services/admin';
import { t } from '../i18n';

export function Users() {
  const [data, setData] = useState<AdminUser[]>([]);
  const [loading, setLoading] = useState(false);

  const load = async () => {
    setLoading(true);
    try {
      const result = await fetchUsers();
      setData(result);
    } catch (error) {
      message.error(t('users.loadFail'));
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void load();
  }, []);

  return (
    <div className="space-y-6">
      <SectionHeader title={t('users.headline')} subtitle={t('users.subtitle')} />
      <Card className="shadow-soft rounded-xl2 border border-border">
        <Table
          dataSource={data}
          rowKey="id"
          loading={loading}
          locale={{ emptyText: <Empty description={t('common.empty')} /> }}
          columns={[
            { title: t('users.account'), dataIndex: 'account', render: (value) => value || t('common.dash') },
            { title: t('users.name'), dataIndex: 'display_name' },
            {
              title: t('users.role'),
              render: (_, row) => (
                <div className="flex flex-wrap gap-1">
                  {row.roles.map((role) => (
                    <Tag key={role.id}>{role.name}</Tag>
                  ))}
                </div>
              )
            },
            { title: t('users.status'), dataIndex: 'status' },
            { title: t('users.created'), dataIndex: 'created_at' }
          ]}
        />
      </Card>
    </div>
  );
}
