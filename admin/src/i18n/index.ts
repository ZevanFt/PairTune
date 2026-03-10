import { zhCN } from './zh-CN';

type Dict = Record<string, string | Dict>;

const dict: Dict = zhCN;

export function t(path: string): string {
  const parts = path.split('.');
  let current: string | Dict = dict;
  for (const part of parts) {
    if (typeof current === 'string') return current;
    current = current[part] as Dict | string;
    if (current === undefined) return path;
  }
  return typeof current === 'string' ? current : path;
}
