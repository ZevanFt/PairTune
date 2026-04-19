import { Card } from 'antd';

interface StatCardProps {
  label: string;
  value: string;
  change?: string;
  trend?: 'up' | 'down';
}

export function StatCard({ label, value, change, trend }: StatCardProps) {
  const resolvedTrend = trend || (change && change.includes('-') ? 'down' : 'up');
  return (
    <Card className="shadow-soft rounded-xl2 border border-border">
      <div className="flex flex-col gap-3">
        <div className="text-sm text-muted">{label}</div>
        <div className="text-3xl font-semibold text-ink">{value}</div>
        {change ? (
          <div
            className={[
              'text-xs inline-flex items-center gap-1 px-2 py-1 rounded-full border w-fit',
              resolvedTrend === 'down'
                ? 'text-rose-600 border-rose-200 bg-rose-50'
                : 'text-emerald-600 border-emerald-200 bg-emerald-50'
            ].join(' ')}
          >
            <span>{resolvedTrend === 'down' ? '↓' : '↑'}</span>
            <span>{change}</span>
          </div>
        ) : null}
      </div>
    </Card>
  );
}
