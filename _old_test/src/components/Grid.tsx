'use client';

import { ResponsiveValue, createResponsiveStyles } from '@/lib/responsiveUtils';

interface GridProps {
  columns?: ResponsiveValue<number | string>;
  gap?: ResponsiveValue<string>;
  children: React.ReactNode;
}

export const Grid: React.FC<GridProps> = ({ 
  columns = 'repeat(auto-fit, minmax(280px, 1fr))',
  gap = '1.5rem',
  children 
}) => {
  const gridStyles = `
    display: grid;
    ${createResponsiveStyles('grid-template-columns', columns, (val) => typeof val === 'number' ? `repeat(${val}, 1fr)` : val)}
    ${createResponsiveStyles('gap', gap)}
    width: 100%;
    max-width: 1200px;
    margin: 0 auto;
  `;

  return <div style={{ cssText: gridStyles }}>{children}</div>;
};
