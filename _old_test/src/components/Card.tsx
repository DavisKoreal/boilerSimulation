'use client';

interface CardProps {
  children: React.ReactNode;
  className?: string;
}

export const Card: React.FC<CardProps> = ({ children, className = '' }) => {
  const cardStyles = `
    background-color: white;
    border-radius: clamp(8px, 1vw, 12px);
    padding: clamp(1rem, 3vw, 1.5rem);
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
    border: 1px solid #f1f5f9;
    transition: all 0.2s ease;
  `;

  return (
    <div className={`card ${className}`} style={{ cssText: cardStyles }}>
      {children}
    </div>
  );
};
