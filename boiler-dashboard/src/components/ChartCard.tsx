'use client';

import { Card } from '@/components/Card';
import { typography } from '@/lib/typography';

interface ChartCardProps {
  title: string;
  children: React.ReactNode;
}

export const ChartCard: React.FC<ChartCardProps> = ({ title, children }) => (
  <Card>
    <h3 className={typography.h2}>{title}</h3>
    <div style={{ 
      height: 'clamp(200px, 25vh, 300px)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      backgroundColor: '#f8fafc',
      borderRadius: '8px',
      color: '#64748b'
    }}>
      {children}
    </div>
  </Card>
);
