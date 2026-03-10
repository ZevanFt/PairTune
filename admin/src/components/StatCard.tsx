import { Card } from 'antd';

interface StatCardProps {
  label: string;
  value: string;
  change?: string;
}

export function StatCard({ label, value, change }: StatCardProps) {
  return (
    <Card className="shadow-soft rounded-xl2 border border-border">
      <div className="flex flex-col gap-3">
        <div className="text-sm text-muted">{label}</div>
        <div className="text-3xl font-semibold text-ink">{value}</div>
        {change ? <div className="text-xs text-primary">{change}</div> : null}
      </div>
    </Card>
  );
}
