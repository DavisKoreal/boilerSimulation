'use client';

import { Card } from '@/components/Card';
import { typography } from '@/lib/typography';

interface RecentActivityProps {
  activities: string[];
}

export const RecentActivity: React.FC<RecentActivityProps> = ({ activities }) => (
  <section style={{ marginTop: 'clamp(2rem, 5vw, 3rem)' }}>
    <Card>
      <h3 className={typography.h2}>Recent Activity</h3>
      <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
        {activities.map((activity, index) => (
          <div 
            key={index}
            style={{
              padding: '0.75rem',
              backgroundColor: '#f8fafc',
              borderRadius: '6px',
              fontSize: 'clamp(0.875rem, 2.5vw, 0.95rem)',
              color: '#475569'
            }}
          >
            {activity}
          </div>
        ))}
      </div>
    </Card>
  </section>
);
