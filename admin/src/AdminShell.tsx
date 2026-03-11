import { Suspense, lazy, useMemo, useState } from 'react';
import type { ReactNode } from 'react';
import { ConfigProvider } from 'antd';

import { Sidebar, NavKey } from './components/Sidebar';
import { TopBar } from './components/TopBar';
import { t } from './i18n';

const Dashboard = lazy(() => import('./pages/Dashboard').then((mod) => ({ default: mod.Dashboard })));
const Invites = lazy(() => import('./pages/Invites').then((mod) => ({ default: mod.Invites })));
const Users = lazy(() => import('./pages/Users').then((mod) => ({ default: mod.Users })));
const Roles = lazy(() => import('./pages/Roles').then((mod) => ({ default: mod.Roles })));
const Tasks = lazy(() => import('./pages/Tasks').then((mod) => ({ default: mod.Tasks })));
const Points = lazy(() => import('./pages/Points').then((mod) => ({ default: mod.Points })));
const Store = lazy(() => import('./pages/Store').then((mod) => ({ default: mod.Store })));
const Security = lazy(() => import('./pages/Security').then((mod) => ({ default: mod.Security })));
const Settings = lazy(() => import('./pages/Settings').then((mod) => ({ default: mod.Settings })));

const navMap: Record<NavKey, ReactNode> = {
  dashboard: <Dashboard />,
  invites: <Invites />,
  users: <Users />,
  tasks: <Tasks />,
  points: <Points />,
  store: <Store />,
  security: <Security />,
  roles: <Roles />,
  settings: <Settings />
};

interface AdminShellProps {
  onLogout: () => void;
}

export function AdminShell({ onLogout }: AdminShellProps) {
  const [active, setActive] = useState<NavKey>('dashboard');
  const username = useMemo(() => {
    try {
      const raw = localStorage.getItem('admin_user');
      if (!raw) return 'Admin';
      const parsed = JSON.parse(raw) as { display_name?: string; account?: string };
      return parsed.display_name || parsed.account || 'Admin';
    } catch {
      return 'Admin';
    }
  }, []);

  return (
    <ConfigProvider
      theme={{
        token: {
          colorPrimary: 'var(--color-primary)',
          fontFamily: 'Space Grotesk, system-ui, sans-serif',
          borderRadius: 12
        }
      }}
    >
      <div className="min-h-screen grid grid-cols-[280px_1fr]">
        <aside className="bg-[var(--sidebar-gradient)]">
          <Sidebar active={active} onChange={setActive} />
        </aside>
        <main className="p-6 space-y-6">
          <TopBar
            username={username}
            onLogout={onLogout}
          />
          <div className="text-sm text-muted">{t('app.title')}</div>
          <Suspense fallback={<div className="text-sm text-muted">{t('common.loading')}</div>}>
            {navMap[active]}
          </Suspense>
        </main>
      </div>
    </ConfigProvider>
  );
}
