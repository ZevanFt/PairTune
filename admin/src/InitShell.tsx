import { ConfigProvider } from 'antd';

import { Init } from './pages/Init';

interface InitShellProps {
  onSuccess: () => void;
}

export function InitShell({ onSuccess }: InitShellProps) {
  return (
    <ConfigProvider
      theme={{
        token: {
          colorPrimary: 'var(--color-primary)',
          fontFamily: 'Space Grotesk, system-ui, sans-serif'
        }
      }}
    >
      <Init onSuccess={onSuccess} />
    </ConfigProvider>
  );
}
