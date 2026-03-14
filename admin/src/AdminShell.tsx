/* global HTMLDivElement, HTMLButtonElement */
import { Suspense, lazy, useEffect, useMemo, useRef, useState } from 'react';
import type { ReactNode } from 'react';
import { ConfigProvider } from 'antd';

import { Sidebar, NavKey } from './components/Sidebar';
import { TopBar } from './components/TopBar';
import { t } from './i18n';
import { formatAbsoluteChinaTime, getTimeFormatMode, onTimeFormatChange, toggleTimeFormatMode, formatRelativeTime } from './utils/timeFormat';

const Dashboard = lazy(() => import('./pages/Dashboard').then((mod) => ({ default: mod.Dashboard })));
const Invites = lazy(() => import('./pages/Invites').then((mod) => ({ default: mod.Invites })));
const Users = lazy(() => import('./pages/Users').then((mod) => ({ default: mod.Users })));
const Roles = lazy(() => import('./pages/Roles').then((mod) => ({ default: mod.Roles })));
const Tasks = lazy(() => import('./pages/Tasks').then((mod) => ({ default: mod.Tasks })));
const Points = lazy(() => import('./pages/Points').then((mod) => ({ default: mod.Points })));
const Store = lazy(() => import('./pages/Store').then((mod) => ({ default: mod.Store })));
const Feedback = lazy(() => import('./pages/Feedback').then((mod) => ({ default: mod.Feedback })));
const Security = lazy(() => import('./pages/Security').then((mod) => ({ default: mod.Security })));
const Settings = lazy(() => import('./pages/Settings').then((mod) => ({ default: mod.Settings })));

const navMap: Record<NavKey, ReactNode> = {
  dashboard: <Dashboard />,
  invites: <Invites />,
  users: <Users />,
  tasks: <Tasks />,
  points: <Points />,
  store: <Store />,
  feedback: <Feedback />,
  security: <Security />,
  roles: <Roles />,
  settings: <Settings />
};

const navItems: Array<{ key: NavKey; label: string }> = [
  { key: 'dashboard', label: t('nav.dashboard') },
  { key: 'invites', label: t('nav.invites') },
  { key: 'users', label: t('nav.users') },
  { key: 'tasks', label: t('nav.tasks') },
  { key: 'points', label: t('nav.points') },
  { key: 'store', label: t('nav.store') },
  { key: 'feedback', label: t('nav.feedback') },
  { key: 'security', label: t('nav.security') },
  { key: 'roles', label: t('nav.roles') },
  { key: 'settings', label: t('nav.settings') }
];

interface AdminShellProps {
  onLogout: () => void;
}

export function AdminShell({ onLogout }: AdminShellProps) {
  const [active, setActive] = useState<NavKey>('dashboard');
  const [tabs, setTabs] = useState<NavKey[]>(() => {
    try {
      const raw = localStorage.getItem('admin_open_tabs');
      if (!raw) return ['dashboard'];
      const parsed = JSON.parse(raw) as NavKey[];
      return Array.isArray(parsed) && parsed.length ? parsed : ['dashboard'];
    } catch {
      return ['dashboard'];
    }
  });
  const [canScrollLeft, setCanScrollLeft] = useState(false);
  const [canScrollRight, setCanScrollRight] = useState(false);
  const [fadeLeft, setFadeLeft] = useState(false);
  const [fadeRight, setFadeRight] = useState(false);
  const [recentKeys, setRecentKeys] = useState<Array<{ key: NavKey; ts: string }>>(() => {
    try {
      const raw = localStorage.getItem('admin_recent_nav');
      if (!raw) return [{ key: 'dashboard', ts: new Date().toISOString() }];
      const parsed = JSON.parse(raw) as Array<{ key: NavKey; ts: string }>;
      return Array.isArray(parsed) && parsed.length ? parsed : [{ key: 'dashboard', ts: new Date().toISOString() }];
    } catch {
      return [{ key: 'dashboard', ts: new Date().toISOString() }];
    }
  });
  const tabsRef = useRef<HTMLDivElement | null>(null);
  const dragState = useRef({ isDown: false, startX: 0, scrollLeft: 0 });
  const dragDistance = useRef(0);
  const snapTimeout = useRef<number | null>(null);
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
  const roleLabel = useMemo(() => {
    try {
      const raw = localStorage.getItem('admin_user');
      if (!raw) return t('topbar.roleAdmin');
      const parsed = JSON.parse(raw) as { role?: string };
      return parsed.role === 'admin' ? t('topbar.roleAdmin') : t('topbar.roleStaff');
    } catch {
      return t('topbar.roleAdmin');
    }
  }, []);
  const lastLogin = useMemo(() => {
    const raw = localStorage.getItem('admin_last_login');
    return formatAbsoluteChinaTime(raw);
  }, []);
  const [timeMode, setTimeMode] = useState<'absolute' | 'relative'>(getTimeFormatMode());
  const handleToggleTimeMode = () => {
    const next = toggleTimeFormatMode();
    setTimeMode(next);
  };

  const persistRecent = (key: NavKey) => {
    setRecentKeys((prev) => {
      const now = new Date().toISOString();
      const next = [{ key, ts: now }, ...prev.filter((item) => item.key !== key)].slice(0, 4);
      localStorage.setItem('admin_recent_nav', JSON.stringify(next));
      return next;
    });
  };

  const handleNavigate = (key: NavKey) => {
    setActive(key);
    setTabs((prev) => (prev.includes(key) ? prev : [...prev, key]));
    persistRecent(key);
  };

  const handleCloseTab = (key: NavKey) => {
    setTabs((prev) => {
      if (prev.length === 1) return prev;
      const next = prev.filter((item) => item !== key);
      localStorage.setItem('admin_open_tabs', JSON.stringify(next.length ? next : ['dashboard']));
      if (active === key) {
        const idx = prev.findIndex((item) => item === key);
        const fallback = next[idx - 1] || next[idx] || next[0];
        setActive(fallback);
      }
      return next;
    });
  };

  const syncScrollState = () => {
    const el = tabsRef.current;
    if (!el) return;
    const max = el.scrollWidth - el.clientWidth;
    const left = el.scrollLeft > 0;
    const right = el.scrollLeft < max - 1;
    setCanScrollLeft(left);
    setCanScrollRight(right);
    setFadeLeft(left);
    setFadeRight(right);
  };

  const snapTabs = () => {
    const el = tabsRef.current;
    if (!el) return;
    const buttons = Array.from(el.querySelectorAll<HTMLButtonElement>('button[data-tab]'));
    if (!buttons.length) return;
    const current = el.scrollLeft;
    let closest = buttons[0];
    let min = Math.abs(closest.offsetLeft - current);
    buttons.forEach((btn) => {
      const diff = Math.abs(btn.offsetLeft - current);
      if (diff < min) {
        min = diff;
        closest = btn;
      }
    });
    el.scrollTo({ left: closest.offsetLeft, behavior: 'smooth' });
  };

  useEffect(() => {
    syncScrollState();
  }, []);

  useEffect(() => {
    localStorage.setItem('admin_open_tabs', JSON.stringify(tabs));
  }, [tabs]);

  useEffect(() => {
    const el = tabsRef.current;
    if (!el) return;
    const btn = el.querySelector<HTMLButtonElement>(`button[data-key="${active}"]`);
    if (!btn) return;
    const left = btn.offsetLeft - 12;
    el.scrollTo({ left, behavior: 'smooth' });
  }, [active]);

  useEffect(() => onTimeFormatChange(() => setTimeMode(getTimeFormatMode())), []);

  const recentItems = useMemo(() => (
    recentKeys
      .map((entry) => {
        const target = navItems.find((item) => item.key === entry.key);
        if (!target) return null;
        return {
          key: target.key,
          label: target.label,
          lastVisited: entry.ts,
          relative: formatRelativeTime(entry.ts)
        };
      })
      .filter((item): item is { key: NavKey; label: string; lastVisited: string; relative: string | null } => Boolean(item))
  ), [recentKeys]);

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
      <div className="h-screen grid grid-cols-[280px_1fr] overflow-hidden">
        <aside className="bg-[var(--sidebar-gradient)] h-screen overflow-hidden">
          <Sidebar active={active} onChange={handleNavigate} recent={recentItems} />
        </aside>
        <div className="h-screen flex flex-col overflow-hidden">
          <header className="px-6 pt-6 pb-3 space-y-3">
            <TopBar
              username={username}
              roleLabel={roleLabel}
              lastLogin={lastLogin}
              timeMode={timeMode}
              onToggleTimeMode={handleToggleTimeMode}
              onLogout={onLogout}
            />
            <div className={`tabs-fade ${fadeLeft ? 'fade-left' : ''} ${fadeRight ? 'fade-right' : ''}`}>
              <button
                type="button"
                className={`tabs-arrow left ${canScrollLeft ? 'is-active' : ''}`}
                onClick={() => {
                  if (!tabsRef.current) return;
                  tabsRef.current.scrollBy({ left: -220, behavior: 'smooth' });
                }}
                aria-label={t('topbar.scrollLeft')}
              >
                ‹
              </button>
              <div
                ref={tabsRef}
                className="tabs-scroll flex items-center gap-2 overflow-x-auto pb-1"
                onPointerDown={(event) => {
                  if (!tabsRef.current) return;
                  dragState.current.isDown = true;
                  dragState.current.startX = event.clientX;
                  dragState.current.scrollLeft = tabsRef.current.scrollLeft;
                  dragDistance.current = 0;
                  tabsRef.current.setPointerCapture(event.pointerId);
                }}
                onPointerMove={(event) => {
                  if (!dragState.current.isDown || !tabsRef.current) return;
                  const walk = event.clientX - dragState.current.startX;
                  dragDistance.current = Math.max(dragDistance.current, Math.abs(walk));
                  tabsRef.current.scrollLeft = dragState.current.scrollLeft - walk;
                  syncScrollState();
                }}
                onPointerUp={(event) => {
                  dragState.current.isDown = false;
                  if (tabsRef.current) {
                    tabsRef.current.releasePointerCapture(event.pointerId);
                  }
                  if (dragDistance.current > 6) {
                    snapTabs();
                  }
                  dragDistance.current = 0;
                }}
                onPointerLeave={() => {
                  dragState.current.isDown = false;
                  dragDistance.current = 0;
                }}
                onScroll={() => {
                  syncScrollState();
                  if (snapTimeout.current) window.clearTimeout(snapTimeout.current);
                  snapTimeout.current = window.setTimeout(() => {
                    if (!dragState.current.isDown && dragDistance.current > 6) {
                      snapTabs();
                    }
                  }, 140);
                }}
              >
              {tabs.map((key) => {
                const item = navItems.find((it) => it.key === key);
                if (!item) return null;
                const isActive = active === item.key;
                return (
                  <button
                    key={item.key}
                    type="button"
                    data-tab
                    data-key={item.key}
                    onClick={() => {
                      if (dragDistance.current > 6) return;
                      handleNavigate(item.key);
                    }}
                    className={[
                      'tabs-pill whitespace-nowrap px-4 py-1.5 rounded-full text-xs font-medium transition border',
                      isActive
                        ? 'bg-[var(--color-ink)] text-white border-[var(--color-ink)] shadow-soft'
                        : 'bg-white/70 text-muted border-border hover:text-ink hover:bg-white'
                    ].join(' ')}
                    aria-current={isActive ? 'page' : undefined}
                  >
                    <span>{item.label}</span>
                    {tabs.length > 1 ? (
                      <button
                        type="button"
                        className="tabs-close"
                        aria-label={t('topbar.tabClose')}
                        onPointerDown={(event) => {
                          event.stopPropagation();
                        }}
                        onClick={(event) => {
                          event.stopPropagation();
                          handleCloseTab(item.key);
                        }}
                      >
                        ×
                      </button>
                    ) : null}
                  </button>
                );
              })}
              </div>
              <button
                type="button"
                className={`tabs-arrow right ${canScrollRight ? 'is-active' : ''}`}
                onClick={() => {
                  if (!tabsRef.current) return;
                  tabsRef.current.scrollBy({ left: 220, behavior: 'smooth' });
                }}
                aria-label={t('topbar.scrollRight')}
              >
                ›
              </button>
            </div>
          </header>
          <main className="flex-1 overflow-y-auto px-6 pb-6 space-y-6">
            <Suspense fallback={<div className="text-sm text-muted">{t('common.loading')}</div>}>
              {navMap[active]}
            </Suspense>
          </main>
        </div>
      </div>
    </ConfigProvider>
  );
}
