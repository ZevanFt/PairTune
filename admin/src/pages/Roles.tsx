import { useEffect, useState } from 'react';
import { Button, Card, Checkbox, Form, Input, Modal, message } from 'antd';

import { SectionHeader } from '../components/SectionHeader';
import { SimpleTable } from '../components/SimpleTable';
import { createRole, fetchPermissions, fetchRoles, Permission, Role, updateRole } from '../services/admin';
import { t } from '../i18n';

export function Roles() {
  const [roles, setRoles] = useState<Role[]>([]);
  const [permissions, setPermissions] = useState<Permission[]>([]);
  const [loading, setLoading] = useState(false);
  const [open, setOpen] = useState(false);
  const [editing, setEditing] = useState<Role | null>(null);
  const [form] = Form.useForm();

  const load = async () => {
    setLoading(true);
    try {
      const [roleData, permData] = await Promise.all([fetchRoles(), fetchPermissions()]);
      setRoles(roleData);
      setPermissions(permData);
    } catch {
      message.error(t('roles.loadFail'));
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void load();
  }, []);

  const openCreate = () => {
    setEditing(null);
    form.resetFields();
    setOpen(true);
  };

  const openEdit = (role: Role) => {
    setEditing(role);
    form.setFieldsValue({
      name: role.name,
      description: role.description,
      permission_codes: role.permissions
    });
    setOpen(true);
  };

  const handleSubmit = async () => {
    const values = await form.validateFields();
    if (!values.name || values.permission_codes.length === 0) {
      message.warning(t('roles.validate'));
      return;
    }
    try {
      if (editing) {
        await updateRole(editing.id, values);
        message.success(t('roles.saveOk'));
      } else {
        await createRole(values);
        message.success(t('roles.saveOk'));
      }
      setOpen(false);
      void load();
    } catch {
      message.error(t('roles.saveFail'));
    }
  };

  return (
    <div className="space-y-6">
      <SectionHeader
        title={t('roles.headline')}
        subtitle={t('roles.subtitle')}
        action={<Button type="primary" onClick={openCreate}>{t('roles.create')}</Button>}
      />
      <Card className="shadow-soft rounded-xl2 border border-border">
        <SimpleTable
          data={roles}
          rowKey="id"
          loading={loading}
          columns={[
            { title: t('roles.columns.name'), dataIndex: 'name' },
            { title: t('roles.columns.desc'), dataIndex: 'description', render: (value) => value || t('common.dash') },
            { title: t('roles.columns.count'), render: (_, row) => row.permissions.length },
            {
              title: t('roles.columns.action'),
              render: (_, row) => (
                <Button size="small" onClick={() => openEdit(row)}>{t('roles.columns.edit')}</Button>
              )
            }
          ]}
        />
      </Card>

      <Modal
        title={editing ? t('roles.update') : t('roles.create')}
        open={open}
        onCancel={() => setOpen(false)}
        onOk={handleSubmit}
      >
        <Form form={form} layout="vertical">
          <Form.Item name="name" label={t('roles.name')} rules={[{ required: true }]}>
            <Input placeholder={t('roles.namePlaceholder')} />
          </Form.Item>
          <Form.Item name="description" label={t('roles.description')}>
            <Input placeholder={t('roles.descPlaceholder')} />
          </Form.Item>
          <Form.Item name="permission_codes" label={t('roles.perm')} rules={[{ required: true }]}>
            <Checkbox.Group className="grid grid-cols-1 gap-2">
              {permissions.map((perm) => (
                <Checkbox key={perm.code} value={perm.code}>
                  {perm.code} - {perm.name}
                </Checkbox>
              ))}
            </Checkbox.Group>
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
}
