import { Menu } from 'antd';
import {
  AppstoreOutlined,
  CalendarOutlined,
  LockOutlined,
  PieChartOutlined,
  SettingOutlined,
  ShoppingOutlined,
  TeamOutlined,
  UserOutlined,
  KeyOutlined
} from '@ant-design/icons';

import { t } from '../i18n';

export type NavKey =
  | 'dashboard'
  | 'invites'
  | 'users'
  | 'tasks'
  | 'points'
  | 'store'
  | 'security'
  | 'roles'
  | 'settings';

interface SidebarProps {
  active: NavKey;
  onChange: (key: NavKey) => void;
}

export function Sidebar({ active, onChange }: SidebarProps) {
  return (
    <div className="h-full flex flex-col text-white">
      <div className="px-6 py-8">
        <div className="text-xs uppercase tracking-[0.3em] text-white/70">{t('sidebar.brandTop')}</div>
        <div className="text-2xl font-semibold">{t('sidebar.brandMain')}</div>
        <div className="text-xs text-white/70 mt-1">{t('app.subtitle')}</div>
      </div>
      <Menu
        theme="dark"
        mode="inline"
        selectedKeys={[active]}
        onClick={(info) => onChange(info.key as NavKey)}
        items={[
          { key: 'dashboard', icon: <PieChartOutlined />, label: t('nav.dashboard') },
          { key: 'invites', icon: <KeyOutlined />, label: t('nav.invites') },
          { key: 'users', icon: <UserOutlined />, label: t('nav.users') },
          { key: 'tasks', icon: <CalendarOutlined />, label: t('nav.tasks') },
          { key: 'points', icon: <AppstoreOutlined />, label: t('nav.points') },
          { key: 'store', icon: <ShoppingOutlined />, label: t('nav.store') },
          { key: 'security', icon: <LockOutlined />, label: t('nav.security') },
          { key: 'roles', icon: <TeamOutlined />, label: t('nav.roles') },
          { key: 'settings', icon: <SettingOutlined />, label: t('nav.settings') }
        ]}
      />
    </div>
  );
}
