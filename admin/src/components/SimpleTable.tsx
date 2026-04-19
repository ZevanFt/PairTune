import type { ReactNode } from 'react';

import { t } from '../i18n';

type DataIndex<T> = keyof T | string;

export interface SimpleColumn<T> {
  title: string;
  dataIndex?: DataIndex<T>;
  render?: (value: unknown, row: T) => ReactNode;
  width?: string;
}

interface SimpleTableProps<T> {
  columns: Array<SimpleColumn<T>>;
  data: T[];
  rowKey: keyof T | ((row: T) => string | number);
  loading?: boolean;
  emptyText?: string;
}

function getRowKey<T>(row: T, rowKey: SimpleTableProps<T>['rowKey']) {
  if (typeof rowKey === 'function') return rowKey(row);
  return String(row[rowKey]);
}

export function SimpleTable<T extends Record<string, unknown>>({
  columns,
  data,
  rowKey,
  loading = false,
  emptyText = t('common.empty')
}: SimpleTableProps<T>) {
  if (loading) {
    return (
      <div className="table-skeleton">
        <table className="w-full text-sm">
          <thead className="text-muted">
            <tr>
              {columns.map((col) => (
                <th
                  key={col.title}
                  className="text-left font-medium py-3 border-b border-border"
                  style={col.width ? { width: col.width } : undefined}
                >
                  {col.title}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {Array.from({ length: 5 }).map((_, idx) => (
              <tr key={`skeleton-${idx}`} className="border-b border-border/60">
                {columns.map((col) => (
                  <td key={`${col.title}-${idx}`} className="py-3">
                    <div className="skeleton" style={{ height: 12, width: '70%' }} />
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    );
  }
  if (!data.length) {
    return (
      <div className="text-sm text-muted py-8 text-center">
        <div className="mb-2 text-base">—</div>
        {emptyText}
      </div>
    );
  }

  return (
    <div className="w-full overflow-x-auto">
      <table className="w-full text-sm">
        <thead className="text-muted">
          <tr>
            {columns.map((col) => (
              <th
                key={col.title}
                className="text-left font-medium py-3 border-b border-border"
                style={col.width ? { width: col.width } : undefined}
              >
                {col.title}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {data.map((row) => (
            <tr key={getRowKey(row, rowKey)} className="border-b border-border/60">
              {columns.map((col) => {
                const value = col.dataIndex ? row[col.dataIndex as keyof T] : undefined;
                return (
                  <td key={col.title} className="py-3 text-ink">
                    {col.render ? col.render(value, row) : String(value ?? t('common.dash'))}
                  </td>
                );
              })}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
