'use client';

import { X } from 'lucide-react';
import { typography } from '@/lib/typography';

interface MobileNavProps {
  isOpen: boolean;
  onClose: () => void;
}

export const MobileNav: React.FC<MobileNavProps> = ({ isOpen, onClose }) => {
  if (!isOpen) return null;

  return (
    <div style={{
      position: 'fixed',
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      backgroundColor: 'rgba(0, 0, 0, 0.5)',
      zIndex: 50,
      display: 'block'
    }}>
      <div style={{
        position: 'fixed',
        top: 0,
        left: 0,
        bottom: 0,
        width: '280px',
        backgroundColor: 'white',
        padding: '1.5rem',
        boxShadow: '0 10px 25px rgba(0, 0, 0, 0.1)'
      }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
          <h2 className={typography.h2}>Menu</h2>
          <button 
            onClick={onClose}
            style={{
              background: 'none',
              border: 'none',
              cursor: 'pointer',
              padding: '0.5rem',
              borderRadius: '4px',
              display: 'flex',
              alignItems: 'center',
              minHeight: '44px',
              minWidth: '44px'
            }}
          >
            <X size={20} />
          </button>
        </div>
        <nav>
          {['Dashboard', 'Analytics', 'Settings'].map(item => (
            <a 
              key={item}
              href="#"
              style={{
                display: 'block',
                padding: '0.75rem 0',
                color: '#64748b',
                textDecoration: 'none',
                fontSize: '1rem',
                borderBottom: '1px solid #f1f5f9',
                minHeight: '44px'
              }}
            >
              {item}
            </a>
          ))}
        </nav>
      </div>
    </div>
  );
};
