import { ConfigProvider } from 'antd';

import { Login } from './pages/Login';

interface LoginShellProps {
  onSuccess: () => void;
}

export function LoginShell({ onSuccess }: LoginShellProps) {
  return (
    <ConfigProvider
      theme={{
        token: {
          colorPrimary: 'var(--color-primary)',
          fontFamily: 'Space Grotesk, system-ui, sans-serif'
        }
      }}
    >
      <Login onSuccess={onSuccess} />
    </ConfigProvider>
  );
}
