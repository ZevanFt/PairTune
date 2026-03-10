import { Card } from 'antd';

import { SectionHeader } from '../components/SectionHeader';

interface EmptyPageProps {
  title: string;
  subtitle: string;
  placeholder: string;
}

export function EmptyPage({ title, subtitle, placeholder }: EmptyPageProps) {
  return (
    <div className="space-y-6">
      <SectionHeader title={title} subtitle={subtitle} />
      <Card className="shadow-soft rounded-xl2 border border-border">
        <div className="h-60 flex items-center justify-center text-muted">
          {placeholder}
        </div>
      </Card>
    </div>
  );
}
