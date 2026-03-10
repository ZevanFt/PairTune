export type LogLevel = 'info' | 'warn' | 'error';

export function log(level: LogLevel, message: string, detail?: Record<string, unknown>) {
  const payload = {
    level,
    message,
    detail: detail || {},
    ts: new Date().toISOString()
  };
  if (level === 'error') {
    console.error(JSON.stringify(payload));
  } else if (level === 'warn') {
    console.warn(JSON.stringify(payload));
  } else {
    console.log(JSON.stringify(payload));
  }
}
