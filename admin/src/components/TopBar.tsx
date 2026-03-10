import { Button, Dropdown } from 'antd';
import { DownOutlined } from '@ant-design/icons';

import { t } from '../i18n';

interface TopBarProps {
  username: string;
  onLogout: () => void;
}

export function TopBar({ username, onLogout }: TopBarProps) {
  return (
    <div className="flex items-center justify-between py-4 px-6 bg-[var(--color-surface)] border border-border rounded-xl2 shadow-soft">
      <div>
        <div className="text-xs text-muted uppercase tracking-[0.3em]">{t('topbar.tag')}</div>
        <div className="text-lg font-semibold text-ink">{t('topbar.title')}</div>
      </div>
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
        <Button type="default">
          {username} <DownOutlined />
        </Button>
      </Dropdown>
    </div>
  );
}
