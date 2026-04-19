import { Button, Dropdown } from 'antd';
import { DownOutlined } from '@ant-design/icons';

import { t } from '../i18n';

interface TopBarProps {
  username: string;
  roleLabel: string;
  lastLogin?: string | null;
  timeMode: 'absolute' | 'relative';
  onToggleTimeMode: () => void;
  onLogout: () => void;
}

export function TopBar({ username, roleLabel, lastLogin, timeMode, onToggleTimeMode, onLogout }: TopBarProps) {
  const initials = String(username || '?').trim().slice(0, 1).toUpperCase();
  return (
    <div className="flex items-center justify-between py-4 px-6 bg-[var(--color-surface)] border border-border rounded-xl2 shadow-soft">
      <div>
        <div className="text-lg font-semibold text-ink">{t('topbar.title')}</div>
      </div>
      <div className="flex items-center gap-4">
        <div className="text-right">
          <div className="text-xs text-muted">{t('topbar.lastLogin')}</div>
          <div className="text-sm text-ink">{lastLogin || t('common.dash')}</div>
        </div>
        <button
          type="button"
          onClick={onToggleTimeMode}
          className="px-3 py-1 rounded-full border border-border text-xs text-muted hover:text-ink hover:bg-white"
        >
          {timeMode === 'relative' ? t('topbar.timeRelative') : t('topbar.timeAbsolute')}
        </button>
        <Dropdown
          menu={{
            items: [
              { key: 'logout', label: t('topbar.logout') }
            ],
            onClick: (info) => {
              if (info.key === 'logout') onLogout();
            }
          }}
        >
          <Button type="default" className="topbar-user">
            <span className="topbar-avatar">{initials}</span>
            <span className="topbar-user-meta">
              <span className="topbar-user-name">{username}</span>
              <span className="topbar-user-role">{roleLabel}</span>
            </span>
            <DownOutlined />
          </Button>
        </Dropdown>
      </div>
    </div>
  );
}
