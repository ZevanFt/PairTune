import { Card } from 'antd';

import { SectionHeader } from '../components/SectionHeader';
import { t } from '../i18n';

export function Settings() {
  return (
    <div className="space-y-6">
      <SectionHeader title={t('nav.settings')} subtitle={t('settings.subtitle')} />
      <Card className="shadow-soft rounded-xl2 border border-border">
        <div className="h-60 flex items-center justify-center text-muted">
          {t('settings.waiting')}
        </div>
      </Card>
    </div>
  );
}
