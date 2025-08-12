'use client';

import { LucideIcon } from 'lucide-react';
import { typography } from '@/lib/typography';

interface StatCardProps {
  icon: LucideIcon;
  title: string;
  value: string;
  change: string;
  changeType: 'positive' | 'negative';
}

export const StatCard: React.FC<StatCardProps> = ({ icon: Icon, title, value, change, changeType }) => {
  const cardStyles = `
    &:hover {
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
      transform: translateY(-1px);
    }
  `;

  return (
    <div className="card" style={{ cssText: cardStyles }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '0.75rem' }}>
        <div style={{
          padding: '0.5rem',
          borderRadius: '8px',
          backgroundColor: '#f8fafc',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center'
        }}>
          <Icon size={20} color="#64748b" />
        </div>
        <span style={{
          fontSize: 'clamp(0.75rem, 2vw, 0.875rem)',
          color: changeType === 'positive' ? '#059669' : '#dc2626',
          fontWeight: '500'
        }}>
          {change}
        </span>
      </div>
      <h3 className={typography.statLabel}>{title}</h3>
      <p className={typography.statValue}>{value}</p>
    </div>
  );
};
