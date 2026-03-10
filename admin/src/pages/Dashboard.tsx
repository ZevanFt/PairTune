import { Card, Segmented } from 'antd';

import { StatCard } from '../components/StatCard';
import { SectionHeader } from '../components/SectionHeader';
import { t } from '../i18n';

export function Dashboard() {
  return (
    <div className="space-y-6">
      <SectionHeader
        title={t('dashboard.headline')}
        subtitle={t('app.subtitle')}
        action={<Segmented options={[t('dashboard.range7'), t('dashboard.range30'), t('dashboard.range90')]} />}
      />

      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        <StatCard label={t('dashboard.users')} value="--" change={t('dashboard.waiting')} />
        <StatCard label={t('dashboard.tasks')} value="--" change={t('dashboard.waiting')} />
        <StatCard label={t('dashboard.points')} value="--" change={t('dashboard.waiting')} />
        <StatCard label={t('dashboard.store')} value="--" change={t('dashboard.waiting')} />
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        <Card className="shadow-soft rounded-xl2 border border-border">
          <div className="text-sm text-muted mb-3">{t('dashboard.growth')}</div>
          <div className="h-56 rounded-xl2 border border-dashed border-border flex items-center justify-center text-muted">
            {t('dashboard.waiting')}
          </div>
        </Card>
        <Card className="shadow-soft rounded-xl2 border border-border">
          <div className="text-sm text-muted mb-3">{t('dashboard.overview')}</div>
          <div className="h-56 rounded-xl2 border border-dashed border-border flex items-center justify-center text-muted">
            {t('dashboard.waiting')}
          </div>
        </Card>
      </div>
    </div>
  );
}
