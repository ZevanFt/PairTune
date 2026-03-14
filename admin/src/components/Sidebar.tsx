import {
  AppstoreOutlined,
  CalendarOutlined,
  LockOutlined,
  MessageOutlined,
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
  | 'feedback'
  | 'security'
  | 'roles'
  | 'settings';

interface SidebarProps {
  active: NavKey;
  onChange: (_key: NavKey) => void;
  recent?: Array<{ key: NavKey; label: string; lastVisited: string; relative: string | null }>;
}

export function Sidebar({ active, onChange, recent = [] }: SidebarProps) {
  const groups = [
    {
      title: t('sidebar.group.core'),
      items: [
        { key: 'dashboard', icon: <PieChartOutlined />, label: t('nav.dashboard') },
        { key: 'invites', icon: <KeyOutlined />, label: t('nav.invites') },
        { key: 'users', icon: <UserOutlined />, label: t('nav.users') }
      ]
    },
    {
      title: t('sidebar.group.ops'),
      items: [
        { key: 'tasks', icon: <CalendarOutlined />, label: t('nav.tasks') },
        { key: 'points', icon: <AppstoreOutlined />, label: t('nav.points') },
        { key: 'store', icon: <ShoppingOutlined />, label: t('nav.store') },
        { key: 'feedback', icon: <MessageOutlined />, label: t('nav.feedback') }
      ]
    },
    {
      title: t('sidebar.group.access'),
      items: [
        { key: 'security', icon: <LockOutlined />, label: t('nav.security') },
        { key: 'roles', icon: <TeamOutlined />, label: t('nav.roles') },
        { key: 'settings', icon: <SettingOutlined />, label: t('nav.settings') }
      ]
    }
  ] as const;

  const quickItems = [
    { key: 'dashboard', label: t('nav.dashboard') },
    { key: 'tasks', label: t('nav.tasks') },
    { key: 'security', label: t('nav.security') }
  ] as const;

  return (
    <div className="h-full flex flex-col text-white sidebar-surface">
      <div className="px-6 py-8">
        <div className="text-[11px] uppercase tracking-[0.35em] text-white/70">{t('sidebar.brandTop')}</div>
        <div className="text-2xl font-semibold">{t('sidebar.brandMain')}</div>
        <div className="text-xs text-white/70 mt-2">{t('app.subtitle')}</div>
      </div>
      <div className="px-3 pb-6 flex-1 min-h-0 sidebar-nav-wrap">
        <nav className="space-y-4 overflow-y-auto pr-2 sidebar-nav sidebar-nav-list">
          <div className="space-y-2">
            <div className="sidebar-group-label px-3">{t('sidebar.group.quick')}</div>
            <div className="sidebar-divider" />
            <div className="flex flex-wrap gap-2 px-3">
              {quickItems.map((item) => (
                <button
                  key={item.key}
                  type="button"
                  onClick={() => onChange(item.key as NavKey)}
                  className="sidebar-chip"
                >
                  {item.label}
                </button>
              ))}
            </div>
          </div>
          {recent.length ? (
            <div className="space-y-2">
              <div className="sidebar-group-label px-3">{t('sidebar.group.recent')}</div>
              <div className="sidebar-divider" />
              <div className="flex flex-wrap gap-2 px-3">
                {recent.map((item) => (
                  <button
                    key={item.key}
                    type="button"
                    onClick={() => onChange(item.key as NavKey)}
                    className="sidebar-chip sidebar-chip--recent"
                    title={item.lastVisited}
                  >
                    <span>{item.label}</span>
                    {item.relative ? <span className="sidebar-chip-time">{item.relative}</span> : null}
                  </button>
                ))}
              </div>
            </div>
          ) : null}
          {groups.map((group) => (
            <div key={group.title} className="space-y-2">
              <div className="sidebar-group-label px-3">{group.title}</div>
              <div className="sidebar-divider" />
              <div className="space-y-1">
                {group.items.map((item) => {
                  const isActive = active === item.key;
                  return (
                    <button
                      key={item.key}
                      type="button"
                      onClick={() => onChange(item.key as NavKey)}
                      className={[
                        'sidebar-item w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm transition',
                        isActive
                          ? 'is-active bg-white/15 text-white shadow-[0_12px_30px_rgba(15,23,42,0.2)]'
                          : 'text-white/75 hover:text-white hover:bg-white/10'
                      ].join(' ')}
                      aria-current={isActive ? 'page' : undefined}
                    >
                      <span className="text-base">{item.icon}</span>
                      <span className="font-medium">{item.label}</span>
                    </button>
                  );
                })}
              </div>
            </div>
          ))}
        </nav>
      </div>
      <div className="mt-auto px-6 pb-6 text-xs text-white/60">
        <div className="sidebar-quote">
          {t('app.subtitle')}
        </div>
      </div>
    </div>
  );
}
