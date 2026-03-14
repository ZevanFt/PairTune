import { Suspense, lazy, useCallback, useEffect, useRef, useState } from 'react';

import { fetchBootstrapStatus } from './services/admin';
import { t } from './i18n';

const AdminShell = lazy(() => import('./AdminShell').then((mod) => ({ default: mod.AdminShell })));
const InitShell = lazy(() => import('./InitShell').then((mod) => ({ default: mod.InitShell })));
const LoginShell = lazy(() => import('./LoginShell').then((mod) => ({ default: mod.LoginShell })));

export function App() {
  const [authed, setAuthed] = useState(() => Boolean(localStorage.getItem('admin_token')));
  const [initialized, setInitialized] = useState<boolean | null>(null);
  const [statusError, setStatusError] = useState(false);
  const [checking, setChecking] = useState(false);
  const [elapsed, setElapsed] = useState(0);

  const checkingRef = useRef(false);

  const loadStatus = useCallback(async () => {
    if (checkingRef.current) return;
    checkingRef.current = true;
    setChecking(true);
    setStatusError(false);
    try {
      const status = await fetchBootstrapStatus();
      setInitialized(Boolean(status.initialized));
    } catch {
      setStatusError(true);
      setInitialized(null);
    }
    checkingRef.current = false;
    setChecking(false);
  }, []);

  useEffect(() => {
    void loadStatus();
  }, [loadStatus]);

  useEffect(() => {
    if (initialized !== null || statusError) return undefined;
    setElapsed(0);
    const timer = window.setInterval(() => {
      setElapsed((prev) => prev + 1);
    }, 1000);
    return () => window.clearInterval(timer);
  }, [initialized, statusError]);

  if (initialized === null) {
    return (
      <div className="min-h-screen flex flex-col items-center justify-center gap-4 text-sm text-muted">
        <div className="spinner" aria-label={t('init.loading')} />
        <div>{t('init.loading')}</div>
        <div className="text-xs text-muted">
          {t('init.loadingTime')}
          {elapsed}s
        </div>
        <button
          type="button"
          className="px-4 py-2 rounded-lg border border-border text-ink"
          onClick={() => void loadStatus()}
          disabled={checking}
        >
          {t('init.retry')}
        </button>
      </div>
    );
  }

  if (statusError) {
    return (
      <div className="min-h-screen flex flex-col items-center justify-center gap-4 text-sm text-muted">
        <div>{t('init.loadFail')}</div>
        <div className="text-xs text-muted">{t('init.backendHint')}</div>
        <button
          type="button"
          className="px-4 py-2 rounded-lg border border-border text-ink"
          onClick={() => void loadStatus()}
        >
          {t('init.retry')}
        </button>
      </div>
    );
  }

  if (!initialized) {
    return (
      <Suspense fallback={null}>
        <InitShell onSuccess={() => setInitialized(true)} />
      </Suspense>
    );
  }

  if (!authed) {
    return (
      <Suspense fallback={null}>
        <LoginShell onSuccess={() => setAuthed(true)} />
      </Suspense>
    );
  }

  return (
    <Suspense fallback={null}>
      <AdminShell
        onLogout={() => {
          localStorage.removeItem('admin_token');
          localStorage.removeItem('admin_user');
          setAuthed(false);
        }}
      />
    </Suspense>
  );
}
