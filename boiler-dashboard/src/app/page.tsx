'use client';

import { useState } from 'react';
import { Menu, Bell, Search } from 'lucide-react';
import { Grid } from '@/components/Grid';
import { MobileNav } from '@/components/MobileNav';
import BoilerInputForm from '@/components/BoilerInputForm';
import BoilerVisualization from '@/components/BoilerVisualization';
import { RecentActivity } from '@/components/RecentActivity';
import { boiler, BoilerOutput } from '@/lib/boilerModel';
import { typography } from '@/lib/typography';
import { createResponsiveStyles } from '@/lib/responsiveUtils';
import { breakpoints } from '@/lib/breakpoints';

export default function Home() {
  const [output, setOutput] = useState<BoilerOutput | null>(null);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const [activities, setActivities] = useState<string[]>([]);

  const handleSubmit = (inputs: {
    fuel: Parameters<typeof boiler>[0];
    water: Parameters<typeof boiler>[1];
    air: Parameters<typeof boiler>[2];
    electricity: Parameters<typeof boiler>[3];
    controlSettings: Parameters<typeof boiler>[4];
  }) => {
    const result = boiler(inputs.fuel, inputs.water, inputs.air, inputs.electricity, inputs.controlSettings);
    setOutput(result);
  };

  const addActivity = (activity: string) => {
    setActivities((prev) => [activity, ...prev].slice(0, 4)); // Keep last 4 activities
  };

  const headerStyles = `
    background-color: white;
    border-bottom: 1px solid #f1f5f9;
    ${createResponsiveStyles('padding', { sm: '1rem', md: '1.5rem' })}
    position: sticky;
    top: 0;
    z-index: 40
  `;

  const containerStyles = `
    max-width: 1200px;
    margin: 0 auto;
    display: flex;
    align-items: center;
    justify-content: space-between
  `;

  const mainStyles = `
    ${createResponsiveStyles('padding', { sm: '1rem', md: '2rem' })}
    max-width: 1200px;
    margin: 0 auto
  `;

  const searchStyles = `
    display: flex;
    align-items: center;
    background-color: #f8fafc;
    border-radius: 8px;
    padding: 0.5rem 1rem;
    ${createResponsiveStyles('min-width', { sm: '200px', md: '300px' })}
    border: 1px solid #e2e8f0
  `;

  const buttonStyles = `
    background: none;
    border: none;
    cursor: pointer;
    padding: 0.5rem;
    border-radius: 4px;
    min-height: 44px;
    min-width: 44px;
    &:focus {
      outline: 2px solid #3b82f6;
      outline-offset: 2px
    }
  `;

  return (
    <div style={{ minHeight: '100vh', backgroundColor: '#ffffff' }}>
      <header style={{ cssText: headerStyles }}>
        <div style={{ cssText: containerStyles }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
            <button
              onClick={() => setIsMobileMenuOpen(true)}
              style={{ cssText: buttonStyles }}
              className="md-hidden"
            >
              <Menu size={20} color="#64748b" />
            </button>
            <h1 className={typography.h1}>Boiler Dashboard</h1>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
            <div style={{ cssText: searchStyles }}>
              <Search size={16} color="#64748b" />
              <input
                type="text"
                placeholder="Search simulations..."
                style={{
                  background: 'none',
                  border: 'none',
                  outline: 'none',
                  marginLeft: '0.5rem',
                  fontSize: '0.875rem',
                  width: '100%',
                  color: '#1e293b'
                }}
              />
            </div>
            <button style={{ cssText: buttonStyles }}>
              <Bell size={20} color="#64748b" />
            </button>
          </div>
        </div>
      </header>

      <main style={{ cssText: mainStyles }}>
        <BoilerInputForm onSubmit={handleSubmit} addActivity={addActivity} />
        {output && <BoilerVisualization output={output} />}
        <RecentActivity activities={activities} />
      </main>

      <MobileNav isOpen={isMobileMenuOpen} onClose={() => setIsMobileMenuOpen(false)} />

      <style jsx>{`
        @media (min-width: ${breakpoints.md}) {
          .md-hidden {
            display: none !important;
          }
        }
        
        .card:hover {
          box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1) !important;
          transform: translateY(-1px)
        }
        
        button, a {
          min-height: 44px;
          min-width: 44px;
          touch-action: manipulation
        }
        
        button:focus, input:focus {
          outline: 2px solid #3b82f6;
          outline-offset: 2px
        }
        
        html {
          scroll-behavior: smooth
        }
      `}</style>
    </div>
  );
}
