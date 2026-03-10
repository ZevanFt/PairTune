import { useMemo, useState } from 'react';
import type { ReactNode } from 'react';
import { ConfigProvider } from 'antd';

import { Sidebar, NavKey } from './components/Sidebar';
import { TopBar } from './components/TopBar';
import { Dashboard } from './pages/Dashboard';
import { Invites } from './pages/Invites';
import { Users } from './pages/Users';
import { Roles } from './pages/Roles';
import { Tasks } from './pages/Tasks';
import { Points } from './pages/Points';
import { Store } from './pages/Store';
import { Security } from './pages/Security';
import { Settings } from './pages/Settings';
import { Login } from './pages/Login';
import { t } from './i18n';

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

export function App() {
  const [active, setActive] = useState<NavKey>('dashboard');
  const [authed, setAuthed] = useState(() => Boolean(localStorage.getItem('admin_token')));

  const username = useMemo(() => {
    try {
      const raw = localStorage.getItem('admin_user');
      if (!raw) return 'Admin';
      const parsed = JSON.parse(raw) as { display_name?: string; account?: string };
      return parsed.display_name || parsed.account || 'Admin';
    } catch {
      return 'Admin';
    }
  }, [authed]);

  if (!authed) {
    return (
      <ConfigProvider
        theme={{
          token: {
            colorPrimary: 'var(--color-primary)',
            fontFamily: 'Space Grotesk, system-ui, sans-serif'
          }
        }}
      >
        <Login onSuccess={() => setAuthed(true)} />
      </ConfigProvider>
    );
  }

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
            onLogout={() => {
              localStorage.removeItem('admin_token');
              localStorage.removeItem('admin_user');
              setAuthed(false);
            }}
          />
          <div className="text-sm text-muted">{t('app.title')}</div>
          {navMap[active]}
        </main>
      </div>
    </ConfigProvider>
  );
}
