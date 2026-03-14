type TimeFormatMode = 'absolute' | 'relative';

const STORAGE_KEY = 'admin_time_format';
const EVENT_NAME = 'admin-time-format';

export function getTimeFormatMode(): TimeFormatMode {
  const raw = localStorage.getItem(STORAGE_KEY);
  return raw === 'relative' ? 'relative' : 'absolute';
}

export function setTimeFormatMode(mode: TimeFormatMode) {
  localStorage.setItem(STORAGE_KEY, mode);
  window.dispatchEvent(new window.CustomEvent(EVENT_NAME, { detail: mode }));
}

export function toggleTimeFormatMode(): TimeFormatMode {
  const next = getTimeFormatMode() === 'relative' ? 'absolute' : 'relative';
  setTimeFormatMode(next);
  return next;
}

export function onTimeFormatChange(handler: () => void) {
  window.addEventListener(EVENT_NAME, handler);
  return () => window.removeEventListener(EVENT_NAME, handler);
}

export function formatRelativeTime(value?: string | null): string | null {
  if (!value) return null;
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return null;
  const diffMs = Date.now() - date.getTime();
  const diffSec = Math.floor(diffMs / 1000);
  if (diffSec < 60) return `${diffSec}s`;
  const diffMin = Math.floor(diffSec / 60);
  if (diffMin < 60) return `${diffMin}m`;
  const diffHour = Math.floor(diffMin / 60);
  if (diffHour < 24) return `${diffHour}h`;
  const diffDay = Math.floor(diffHour / 24);
  if (diffDay < 30) return `${diffDay}d`;
  const diffMonth = Math.floor(diffDay / 30);
  if (diffMonth < 12) return `${diffMonth}mo`;
  const diffYear = Math.floor(diffMonth / 12);
  return `${diffYear}y`;
}

export function formatAbsoluteChinaTime(value?: string | null): string | null {
  if (!value) return null;
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return null;
  return new Intl.DateTimeFormat('zh-CN', {
    timeZone: 'Asia/Shanghai',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hour12: false
  }).format(date);
}

export function formatAdminTime(value?: string | null): string | null {
  const mode = getTimeFormatMode();
  if (mode === 'relative') return formatRelativeTime(value);
  return formatAbsoluteChinaTime(value);
}
