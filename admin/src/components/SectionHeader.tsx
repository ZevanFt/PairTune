import type { ReactNode } from 'react';

interface SectionHeaderProps {
  title: string;
  subtitle?: string;
  action?: ReactNode;
}

export function SectionHeader({ title, subtitle, action }: SectionHeaderProps) {
  return (
    <div className="flex items-center justify-between">
      <div>
        <div className="text-lg font-semibold text-ink">{title}</div>
        {subtitle ? <div className="text-sm text-muted">{subtitle}</div> : null}
      </div>
      {action}
    </div>
  );
}
