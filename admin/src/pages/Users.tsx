import { useEffect, useState } from 'react';
import { Card, message } from 'antd';

import { SectionHeader } from '../components/SectionHeader';
import { SimpleTable } from '../components/SimpleTable';
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
    } catch {
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
        <SimpleTable
          data={data}
          rowKey="id"
          loading={loading}
          columns={[
            { title: t('users.account'), dataIndex: 'account', render: (value) => value || t('common.dash') },
            { title: t('users.name'), dataIndex: 'display_name' },
            {
              title: t('users.role'),
              render: (_, row) => (
                <div className="flex flex-wrap gap-2">
                  {row.roles.map((role) => (
                    <span key={role.id} className="px-2 py-0.5 rounded-full text-xs bg-slate-100 text-slate-700">
                      {role.name}
                    </span>
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
