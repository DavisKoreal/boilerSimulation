#!/bin/bash

# Define project name
projectName="boiler-dashboard"

# Create Next.js project with TypeScript and Tailwind CSS
echo "Creating Next.js project: $projectName..."
npx create-next-app@latest "$projectName" --typescript --tailwind --eslint --app --src-dir --import-alias "@/*" --yes

# Navigate to project directory
cd "$projectName" || exit 1

# Install dependencies: Recharts for charts, lucide-react for icons
echo "Installing Recharts and lucide-react..."
npm install recharts lucide-react

# Create directory structure
mkdir -p src/lib src/components src/styles

# Create lib/breakpoints.ts - Semantic breakpoints
cat << EOF > src/lib/breakpoints.ts
export const breakpoints = {
  sm: '640px',
  md: '768px',
  lg: '1024px',
  xl: '1280px'
} as const;

export type Breakpoint = keyof typeof breakpoints;
EOF

# Create lib/typography.ts - Responsive typography
cat << EOF > src/lib/typography.ts
export const typography = {
  h1: \`
    font-size: clamp(1.25rem, 4vw, 1.5rem);
    line-height: 1.2;
    font-weight: 700;
    color: #1e293b;
  \`,
  h2: \`
    font-size: clamp(1rem, 3vw, 1.125rem);
    line-height: 1.3;
    font-weight: 600;
    color: #1e293b;
  \`,
  body: \`
    font-size: clamp(0.875rem, 2.5vw, 0.95rem);
    line-height: 1.6;
    color: #475569;
  \`,
  statValue: \`
    font-size: clamp(1.5rem, 4vw, 2rem);
    font-weight: 700;
    color: #1e293b;
  \`,
  statLabel: \`
    font-size: clamp(0.875rem, 2.5vw, 1rem);
    font-weight: 500;
    color: #64748b;
  \`
};
EOF

# Create lib/responsiveUtils.ts - Type-safe responsive utilities
cat << EOF > src/lib/responsiveUtils.ts
import { breakpoints, Breakpoint } from './breakpoints';

export type ResponsiveValue<T> = T | Partial<Record<Breakpoint, T>>;

export function createResponsiveStyles<T>(
  property: string,
  value: ResponsiveValue<T>,
  transform?: (val: T) => string
): string {
  if (typeof value === 'object' && value !== null) {
    return Object.entries(value)
      .map(([breakpoint, val]) => {
        const bp = breakpoints[breakpoint as Breakpoint];
        const cssValue = transform ? transform(val as T) : String(val);
        return \`@media (min-width: \${bp}) { \${property}: \${cssValue} }\`;
      })
      .join('\n');
  }
  
  const cssValue = transform ? transform(value as T) : String(value);
  return \`\${property}: \${cssValue}\`;
}
EOF

# Create lib/boilerModel.ts - Boiler model functions
cat << EOF > src/lib/boilerModel.ts
export interface Fuel {
  type: string;
  quantity: number; // lb/hr or ft³/hr
  heatContent: number; // BTU/lb or BTU/ft³
}

export interface Water {
  quantity: number; // lb/hr
  temperature: number; // °C
}

export interface Air {
  quantity: number; // ft³/hr
  temperature: number; // °C
}

export interface ControlSettings {
  pressure: number; // PSIG
  temperature: number; // °F
}

export interface Steam {
  flowRate: number; // PPH
  pressure: number; // PSIG
  temperature: number; // °F
}

export interface FlueGases {
  volume: number; // ft³/hr
  temp: number; // °C
  composition: { [key: string]: number }; // e.g., { CO2: 10 }
}

export interface BoilerOutput {
  steam: Steam;
  flueGases: FlueGases;
  wasteHeat: number; // BTU/hr
  emissions: { [key: string]: number }; // e.g., { CO: 100 }
}

export interface BoilerParams {
  efficiency: number;
  horsepower: { min: number; max: number };
  steamOutput: { min: number; max: number };
  pressure: { min: number; max: number };
  furnaceDesign: { corrugated: boolean; type: string };
  tubeConfig: { numTubes: number; diameter: number; length: number };
  refractory: { thermalConductivity: number; maxTemp: number };
  heatTransferCoeff: number;
}

const defaultParams: BoilerParams = {
  efficiency: 0.9,
  horsepower: { min: 50, max: 2500 },
  steamOutput: { min: 1725, max: 86250 },
  pressure: { min: 15, max: 350 },
  furnaceDesign: { corrugated: true, type: 'wet-back' },
  tubeConfig: { numTubes: 100, diameter: 2, length: 10 },
  refractory: { thermalConductivity: 0.5, maxTemp: 1200 },
  heatTransferCoeff: 50,
};

// Helper functions
function calculateFlueGasVolume(fuel: Fuel, air: Air): number {
  return air.quantity * 0.9;
}

function calculateFlueGasComposition(fuel: Fuel, air: Air): { [key: string]: number } {
  return { CO2: 10, H2O: 15, O2: 5, N2: 70 };
}

function calculateTubeSurfaceArea(tubeConfig: BoilerParams['tubeConfig']): number {
  return Math.PI * tubeConfig.diameter * tubeConfig.length * tubeConfig.numTubes;
}

function calculateSteamTemp(pressure: number): number {
  return 212 + pressure * 1.7;
}

function calculateSensibleHeat(inletTemp: number, steamTemp: number): number {
  return steamTemp - (inletTemp * 1.8 + 32);
}

function getLatentHeat(pressure: number): number {
  return 970 - pressure * 0.5;
}

function calculateEmissions(fuelType: string): { [key: string]: number } {
  return { CO: 100, NOx: 50 };
}

// Furnace function
export function furnace(fuel: Fuel, air: Air): { energy: number; flueGases: { volume: number; temp: number; composition: { [key: string]: number } } } {
  const energy = fuel.quantity * fuel.heatContent;
  const flueGasTemp = 1100;
  const flueGasVolume = calculateFlueGasVolume(fuel, air);
  const flueGasComposition = calculateFlueGasComposition(fuel, air);
  return {
    energy,
    flueGases: { volume: flueGasVolume, temp: flueGasTemp, composition: flueGasComposition },
  };
}

// Heat Transfer function
export function heatTransfer(
  combustionEnergy: number,
  flueGases: { volume: number; temp: number; composition: { [key: string]: number } },
  water: Water,
  tubeConfig: BoilerParams['tubeConfig'],
  heatTransferCoeff: number,
  furnaceDesign: BoilerParams['furnaceDesign']
): { heatTransferred: number; flueGases: { volume: number; temp: number } } {
  const tubeSurfaceArea = calculateTubeSurfaceArea(tubeConfig);
  const furnaceFactor = furnaceDesign.corrugated ? 1.1 : 1.0;
  const wetBackFactor = furnaceDesign.type === 'wet-back' ? 1.05 : 1.0;
  const heatTransferred = combustionEnergy * 0.9;
  const flueGasExitTemp = 180;
  return {
    heatTransferred,
    flueGases: { volume: flueGases.volume, temp: flueGasExitTemp },
  };
}

// Steam Generation function
export function steamGeneration(
  heatTransferred: number,
  water: Water,
  controlSettings: ControlSettings,
  pressure: number
): Steam {
  const targetPressure = controlSettings.pressure;
  const steamTemp = calculateSteamTemp(targetPressure);
  const latentHeat = getLatentHeat(targetPressure);
  const sensibleHeat = calculateSensibleHeat(water.temperature, steamTemp);
  const totalHeatPerLb = sensibleHeat + latentHeat;
  const steamOutput = heatTransferred / totalHeatPerLb;
  return {
    flowRate: steamOutput,
    pressure: targetPressure,
    temperature: steamTemp,
  };
}

// Flue Gases Generation function
export function generateFlueGases(
  combustionEnergy: number,
  fuel: Fuel,
  air: Air,
  flueGasesFromFurnace: { volume: number; temp: number; composition: { [key: string]: number } }
): { flueGases: FlueGases; emissions: { [key: string]: number } } {
  const flueGasVolume = flueGasesFromFurnace.volume;
  const flueGasTemp = 180;
  const composition = flueGasesFromFurnace.composition;
  const emissions = calculateEmissions(fuel.type);
  return {
    flueGases: { volume: flueGasVolume, temp: flueGasTemp, composition },
    emissions,
  };
}

// Main boiler function
export function boiler(
  fuel: Fuel,
  water: Water,
  air: Air,
  electricity: number,
  controlSettings: ControlSettings,
  params: BoilerParams = defaultParams
): BoilerOutput {
  const { energy, flueGases: initialFlueGases } = furnace(fuel, air);
  const { heatTransferred, flueGases: cooledFlueGases } = heatTransfer(
    energy,
    initialFlueGases,
    water,
    params.tubeConfig,
    params.heatTransferCoeff,
    params.furnaceDesign
  );
  const steam = steamGeneration(heatTransferred, water, controlSettings, params.pressure.min);
  const { flueGases, emissions } = generateFlueGases(energy, fuel, air, initialFlueGases);

  const usableHeat = energy * params.efficiency;
  const wasteHeat = energy * (1 - params.efficiency);

  return {
    steam,
    flueGases,
    wasteHeat,
    emissions,
  };
}
EOF

# Create components/Grid.tsx - Flexible grid component
cat << EOF > src/components/Grid.tsx
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
  const gridStyles = \`
    display: grid;
    \${createResponsiveStyles('grid-template-columns', columns, (val) => typeof val === 'number' ? \`repeat(\${val}, 1fr)\` : val)}
    \${createResponsiveStyles('gap', gap)}
    width: 100%;
    max-width: 1200px;
    margin: 0 auto
  \`;

  return <div style={{ cssText: gridStyles }}>{children}</div>;
};
EOF

# Create components/Card.tsx - Reusable card component
cat << EOF > src/components/Card.tsx
'use client';

interface CardProps {
  children: React.ReactNode;
  className?: string;
}

export const Card: React.FC<CardProps> = ({ children, className = '' }) => {
  const cardStyles = \`
    background-color: white;
    border-radius: clamp(8px, 1vw, 12px);
    padding: clamp(1rem, 3vw, 1.5rem);
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
    border: 1px solid #f1f5f9;
    transition: all 0.2s ease
  \`;

  return (
    <div className={\`card \${className}\`} style={{ cssText: cardStyles }}>
      {children}
    </div>
  );
};
EOF

# Create components/StatCard.tsx - Stat card component
cat << EOF > src/components/StatCard.tsx
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
  const cardStyles = \`
    &:hover {
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
      transform: translateY(-1px)
    }
  \`;

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
EOF

# Create components/ChartCard.tsx - Chart card component
cat << EOF > src/components/ChartCard.tsx
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
EOF

# Create components/MobileNav.tsx - Mobile navigation component
cat << EOF > src/components/MobileNav.tsx
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
EOF

# Create components/BoilerInputForm.tsx - Input form component
cat << EOF > src/components/BoilerInputForm.tsx
'use client';

import { useState } from 'react';
import { Grid } from '@/components/Grid';
import { Fuel, Water, Air, ControlSettings } from '@/lib/boilerModel';
import { typography } from '@/lib/typography';
import { Thermometer, Droplet, Wind, Fuel as FuelIcon, Zap } from 'lucide-react';

interface BoilerInputFormProps {
  onSubmit: (inputs: { fuel: Fuel; water: Water; air: Air; electricity: number; controlSettings: ControlSettings }) => void;
  addActivity: (activity: string) => void;
}

export default function BoilerInputForm({ onSubmit, addActivity }: BoilerInputFormProps) {
  const [fuelType, setFuelType] = useState('wood');
  const [fuelQuantity, setFuelQuantity] = useState(1000);
  const [fuelHeatContent, setFuelHeatContent] = useState(8000);
  const [waterQuantity, setWaterQuantity] = useState(34500);
  const [waterTemp, setWaterTemp] = useState(20);
  const [airQuantity, setAirQuantity] = useState(12000);
  const [airTemp, setAirTemp] = useState(20);
  const [electricity, setElectricity] = useState(50);
  const [pressure, setPressure] = useState(200);
  const [temperature, setTemperature] = useState(382);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const inputs = {
      fuel: { type: fuelType, quantity: fuelQuantity, heatContent: fuelHeatContent },
      water: { quantity: waterQuantity, temperature: waterTemp },
      air: { quantity: airQuantity, temperature: airTemp },
      electricity,
      controlSettings: { pressure, temperature },
    };
    onSubmit(inputs);
    addActivity(\`Ran simulation: \${fuelType}, \${fuelQuantity} lb/hr, \${pressure} PSIG\`);
  };

  const inputStyles = \`
    width: 100%;
    padding: 0.5rem;
    border: 1px solid #e2e8f0;
    border-radius: 8px;
    font-size: clamp(0.875rem, 2.5vw, 0.95rem);
    color: #1e293b;
    &:focus {
      outline: 2px solid #3b82f6;
      outline-offset: 2px
    }
  \`;

  const buttonStyles = \`
    min-height: 44px;
    min-width: 44px;
    padding: 0.75rem 1rem;
    border: none;
    border-radius: 8px;
    background-color: #3b82f6;
    color: white;
    font-size: 1rem;
    cursor: pointer;
    margin-top: 1rem;
    transition: all 0.2s ease;
    &:hover {
      transform: translateY(-1px);
      box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1)
    };
    &:focus {
      outline: 2px solid #3b82f6;
      outline-offset: 2px
    }
  \`;

  return (
    <form onSubmit={handleSubmit} style={{ marginBottom: 'clamp(2rem, 5vw, 3rem)' }}>
      <Grid columns={{ sm: '1fr', md: 'repeat(2, 1fr)', lg: 'repeat(3, 1fr)' }} gap="1rem">
        <div>
          <label className={typography.body}>Fuel Type</label>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <FuelIcon size={16} color="#64748b" />
            <input type="text" value={fuelType} onChange={(e) => setFuelType(e.target.value)} style={{ cssText: inputStyles }} />
          </div>
        </div>
        <div>
          <label className={typography.body}>Fuel Quantity (lb/hr)</label>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <FuelIcon size={16} color="#64748b" />
            <input type="number" value={fuelQuantity} onChange={(e) => setFuelQuantity(Number(e.target.value))} style={{ cssText: inputStyles }} />
          </div>
        </div>
        <div>
          <label className={typography.body}>Fuel Heat Content (BTU/lb)</label>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <FuelIcon size={16} color="#64748b" />
            <input type="number" value={fuelHeatContent} onChange={(e) => setFuelHeatContent(Number(e.target.value))} style={{ cssText: inputStyles }} />
          </div>
        </div>
        <div>
          <label className={typography.body}>Water Quantity (lb/hr)</label>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <Droplet size={16} color="#64748b" />
            <input type="number" value={waterQuantity} onChange={(e) => setWaterQuantity(Number(e.target.value))} style={{ cssText: inputStyles }} />
          </div>
        </div>
        <div>
          <label className={typography.body}>Water Temp (°C)</label>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <Thermometer size={16} color="#64748b" />
            <input type="number" value={waterTemp} onChange={(e) => setWaterTemp(Number(e.target.value))} style={{ cssText: inputStyles }} />
          </div>
        </div>
        <div>
          <label className={typography.body}>Air Quantity (ft³/hr)</label>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <Wind size={16} color="#64748b" />
            <input type="number" value={airQuantity} onChange={(e) => setAirQuantity(Number(e.target.value))} style={{ cssText: inputStyles }} />
          </div>
        </div>
        <div>
          <label className={typography.body}>Air Temp (°C)</label>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <Thermometer size={16} color="#64748b" />
            <input type="number" value={airTemp} onChange={(e) => setAirTemp(Number(e.target.value))} style={{ cssText: inputStyles }} />
          </div>
        </div>
        <div>
          <label className={typography.body}>Electricity (kW)</label>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <Zap size={16} color="#64748b" />
            <input type="number" value={electricity} onChange={(e) => setElectricity(Number(e.target.value))} style={{ cssText: inputStyles }} />
          </div>
        </div>
        <div>
          <label className={typography.body}>Pressure (PSIG)</label>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <Thermometer size={16} color="#64748b" />
            <input type="number" value={pressure} onChange={(e) => setPressure(Number(e.target.value))} style={{ cssText: inputStyles }} />
          </div>
        </div>
        <div>
          <label className={typography.body}>Temperature (°F)</label>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <Thermometer size={16} color="#64748b" />
            <input type="number" value={temperature} onChange={(e) => setTemperature(Number(e.target.value))} style={{ cssText: inputStyles }} />
          </div>
        </div>
      </Grid>
      <button type="submit" style={{ cssText: buttonStyles }}>Simulate Boiler</button>
    </form>
  );
}
EOF

# Create components/BoilerVisualization.tsx - Visualization dashboard
cat << EOF > src/components/BoilerVisualization.tsx
'use client';

import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { Grid } from '@/components/Grid';
import { StatCard } from '@/components/StatCard';
import { ChartCard } from '@/components/ChartCard';
import { BoilerOutput } from '@/lib/boilerModel';
import { Droplet, Thermometer, Wind, Factory } from 'lucide-react';

interface BoilerVisualizationProps {
  output: BoilerOutput;
}

export default function BoilerVisualization({ output }: BoilerVisualizationProps) {
  const energyData = [
    { name: 'Usable Heat', value: output.steam.flowRate * 1000 },
    { name: 'Waste Heat', value: output.wasteHeat },
  ];

  const flueGasCompositionData = Object.entries(output.flueGases.composition).map(([name, value]) => ({ name, value }));

  const emissionsData = Object.entries(output.emissions).map(([name, value]) => ({ name, value }));

  return (
    <div>
      <section style={{ marginBottom: 'clamp(2rem, 5vw, 3rem)' }}>
        <Grid columns={{ sm: '1fr', md: 'repeat(2, 1fr)', lg: 'repeat(4, 1fr)' }}>
          <StatCard
            icon={Droplet}
            title="Steam Flow Rate"
            value={\`\${output.steam.flowRate.toFixed(2)} PPH\`}
            change="+0.0%"
            changeType="positive"
          />
          <StatCard
            icon={Thermometer}
            title="Steam Pressure"
            value={\`\${output.steam.pressure} PSIG\`}
            change="+0.0%"
            changeType="positive"
          />
          <StatCard
            icon={Thermometer}
            title="Steam Temperature"
            value={\`\${output.steam.temperature} °F\`}
            change="+0.0%"
            changeType="positive"
          />
          <StatCard
            icon={Factory}
            title="Efficiency"
            value={\`\${((output.steam.flowRate * 1000) / (output.steam.flowRate * 1000 + output.wasteHeat) * 100).toFixed(1)}%\`}
            change="+0.0%"
            changeType="positive"
          />
        </Grid>
      </section>

      <section>
        <Grid columns={{ sm: '1fr', md: 'repeat(2, 1fr)' }}>
          <ChartCard title="Energy Distribution">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={energyData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="name" />
                <YAxis />
                <Tooltip />
                <Bar dataKey="value" fill="#3b82f6" />
              </BarChart>
            </ResponsiveContainer>
          </ChartCard>
          <ChartCard title="Flue Gas Composition (%)">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={flueGasCompositionData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="name" />
                <YAxis />
                <Tooltip />
                <Bar dataKey="value" fill="#10b981" />
              </BarChart>
            </ResponsiveContainer>
          </ChartCard>
          <ChartCard title="Emissions">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={emissionsData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="name" />
                <YAxis />
                <Tooltip />
                <Bar dataKey="value" fill="#f97316" />
              </BarChart>
            </ResponsiveContainer>
          </ChartCard>
        </Grid>
      </section>
    </div>
  );
}
EOF

# Create components/RecentActivity.tsx - Recent activity component
cat << EOF > src/components/RecentActivity.tsx
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
EOF

# Create app/page.tsx - Main dashboard page with corrected imports and fixed cssText
cat << EOF > src/app/page.tsx
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

  const handleSubmit = (inputs: Parameters<typeof boiler>[0] & Parameters<typeof boiler>[1] & Parameters<typeof boiler>[2] & Parameters<typeof boiler>[3] & Parameters<typeof boiler>[4]) => {
    const result = boiler(inputs.fuel, inputs.water, inputs.air, inputs.electricity, inputs.controlSettings);
    setOutput(result);
  };

  const addActivity = (activity: string) => {
    setActivities((prev) => [activity, ...prev].slice(0, 4)); // Keep last 4 activities
  };

  const headerStyles = \`
    background-color: white;
    border-bottom: 1px solid #f1f5f9;
    \${createResponsiveStyles('padding', { sm: '1rem', md: '1.5rem' })}
    position: sticky;
    top: 0;
    z-index: 40
  \`;

  const containerStyles = \`
    max-width: 1200px;
    margin: 0 auto;
    display: flex;
    align-items: center;
    justify-content: space-between
  \`;

  const mainStyles = \`
    \${createResponsiveStyles('padding', { sm: '1rem', md: '2rem' })}
    max-width: 1200px;
    margin: 0 auto
  \`;

  const searchStyles = \`
    display: flex;
    align-items: center;
    background-color: #f8fafc;
    border-radius: 8px;
    padding: 0.5rem 1rem;
    \${createResponsiveStyles('min-width', { sm: '200px', md: '300px' })}
    border: 1px solid #e2e8f0
  \`;

  const buttonStyles = \`
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
  \`;

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

      <style jsx>{\`
        @media (min-width: \${breakpoints.md}) {
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
      \`}</style>
    </div>
  );
}
EOF

# Create app/globals.css - Global styles with CSS variables
cat << EOF > src/app/globals.css
:root {
  --container-max-width: 1200px;
  --container-padding: clamp(1rem, 5vw, 3rem);
  --grid-gap: clamp(1rem, 3vw, 2rem);
  --border-radius: clamp(8px, 1vw, 12px);
}

body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
  background-color: #ffffff;
}

* {
  box-sizing: border-box;
}
EOF

# Update app/layout.tsx - Move viewport to separate export
cat << EOF > src/app/layout.tsx
import './globals.css';
import { Inter } from 'next/font/google';

const inter = Inter({ subsets: ['latin'] });

export const metadata = {
  title: 'Boiler Visualization Dashboard',
  description: 'A responsive dashboard for boiler simulation',
};

export const viewport = {
  width: 'device-width',
  initialScale: 1,
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className={inter.className}>{children}</body>
    </html>
  );
}
EOF


