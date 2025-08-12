# PowerShell script to create a Next.js boiler dashboard project

# Define project name
$projectName = "boiler-dashboard"

# Create Next.js project with TypeScript and Tailwind CSS
Write-Host "Creating Next.js project: $projectName..."
npx create-next-app@latest $projectName --typescript --tailwind --eslint --app --src-dir --import-alias "@/*" --yes

# Navigate to project directory
cd $projectName

# Install Recharts for visualizations
Write-Host "Installing Recharts..."
npm install recharts

# Create directory structure
New-Item -ItemType Directory -Path src/lib -Force
New-Item -ItemType Directory -Path src/components -Force
New-Item -ItemType Directory -Path src/styles -Force

# Create lib/breakpoints.ts - Semantic breakpoints
@"
export const breakpoints = {
  xs: '320px',
  sm: '640px',
  md: '768px',
  lg: '1024px',
  xl: '1280px',
  '2xl': '1536px'
} as const;

export type Breakpoint = keyof typeof breakpoints;
"@ | Out-File -FilePath src/lib/breakpoints.ts -Encoding utf8

# Create lib/typography.ts - Responsive typography
@"
export const typography = {
  h1: `
    font-size: clamp(2rem, 5vw, 3.5rem);
    line-height: 1.2;
    font-weight: 700;
  `,
  h2: `
    font-size: clamp(1.5rem, 4vw, 2.5rem);
    line-height: 1.3;
    font-weight: 600;
  `,
  body: `
    font-size: clamp(0.875rem, 2.5vw, 1rem);
    line-height: 1.6;
  `
};
"@ | Out-File -FilePath src/lib/typography.ts -Encoding utf8

# Create lib/responsiveUtils.ts - Type-safe responsive utilities
@"
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
        return ``@media (min-width: \${bp}) { \${property}: \${cssValue}; }``;
      })
      .join('\n');
  }
  
  const cssValue = transform ? transform(value as T) : String(value);
  return `\${property}: \${cssValue};`;
}
"@ | Out-File -FilePath src/lib/responsiveUtils.ts -Encoding utf8

# Create lib/boilerModel.ts - Boiler model functions
@"
import { breakpoints } from './breakpoints';

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

function getLatentHeat(pressure: number): number {
  return 970 - pressure * 0.5;
}

function calculateSensibleHeat(inletTemp: number, steamTemp: number): number {
  return steamTemp - (inletTemp * 1.8 + 32);
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
"@ | Out-File -FilePath src/lib/boilerModel.ts -Encoding utf8

# Create components/Grid.tsx - Flexible grid component
@"
import { breakpoints } from '@/lib/breakpoints';
import { createResponsiveStyles } from '@/lib/responsiveUtils';

interface GridProps {
  columns?: number | string;
  gap?: string;
  children: React.ReactNode;
}

export const Grid: React.FC<GridProps> = ({ 
  columns = 'repeat(auto-fit, minmax(300px, 1fr))',
  gap = '1rem',
  children 
}) => {
  const gridStyles = `
    display: grid;
    grid-template-columns: \${typeof columns === 'number' ? `repeat(\${columns}, 1fr)` : columns};
    gap: \${gap};
    width: 100%;
    max-width: var(--container-max-width);
    margin: 0 auto;
  `;

  return <div style={{ cssText: gridStyles }}>{children}</div>;
};
"@ | Out-File -FilePath src/components/Grid.tsx -Encoding utf8

# Create components/TouchButton.tsx - Touch-friendly button
@"
import { createResponsiveStyles } from '@/lib/responsiveUtils';

interface TouchButtonProps {
  children: React.ReactNode;
  onClick?: () => void;
  type?: 'button' | 'submit' | 'reset';
}

export const TouchButton: React.FC<TouchButtonProps> = ({ children, onClick, type = 'button' }) => {
  const buttonStyles = `
    min-height: 44px;
    min-width: 44px;
    padding: 0.75rem 1rem;
    border: none;
    border-radius: var(--border-radius);
    background-color: #3b82f6;
    color: white;
    font-size: 1rem;
    cursor: pointer;
    margin: 0.25rem;
    \${createResponsiveStyles('padding', {
      xs: '0.5rem 0.75rem',
      md: '0.75rem 1rem',
      lg: '1rem 1.5rem'
    })}
    @media (hover: hover) {
      &:hover {
        transform: translateY(-1px);
        box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
      }
    }
  `;

  return (
    <button type={type} onClick={onClick} style={{ cssText: buttonStyles }}>
      {children}
    </button>
  );
};
"@ | Out-File -FilePath src/components/TouchButton.tsx -Encoding utf8

# Create components/BoilerInputForm.tsx - Simplified input form
@"
'use client';

import { useState } from 'react';
import { Grid } from '@/components/Grid';
import { TouchButton } from '@/components/TouchButton';
import { typography } from '@/lib/typography';
import { Fuel, Water, Air, ControlSettings } from '@/lib/boilerModel';

interface BoilerInputFormProps {
  onSubmit: (inputs: { fuel: Fuel; water: Water; air: Air; electricity: number; controlSettings: ControlSettings }) => void;
}

export default function BoilerInputForm({ onSubmit }: BoilerInputFormProps) {
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
    onSubmit({
      fuel: { type: fuelType, quantity: fuelQuantity, heatContent: fuelHeatContent },
      water: { quantity: waterQuantity, temperature: waterTemp },
      air: { quantity: airQuantity, temperature: airTemp },
      electricity,
      controlSettings: { pressure, temperature },
    });
  };

  const inputStyles = `
    \${typography.body}
    width: 100%;
    padding: 0.5rem;
    border: 1px solid #d1d5db;
    border-radius: var(--border-radius);
  `;

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <Grid columns={{ xs: '1fr', md: 'repeat(2, 1fr)', lg: 'repeat(3, 1fr)' }} gap="1rem">
        <div>
          <label className={typography.body}>Fuel Type</label>
          <input type="text" value={fuelType} onChange={(e) => setFuelType(e.target.value)} className={inputStyles} />
        </div>
        <div>
          <label className={typography.body}>Fuel Quantity (lb/hr)</label>
          <input type="number" value={fuelQuantity} onChange={(e) => setFuelQuantity(Number(e.target.value))} className={inputStyles} />
        </div>
        <div>
          <label className={typography.body}>Fuel Heat Content (BTU/lb)</label>
          <input type="number" value={fuelHeatContent} onChange={(e) => setFuelHeatContent(Number(e.target.value))} className={inputStyles} />
        </div>
        <div>
          <label className={typography.body}>Water Quantity (lb/hr)</label>
          <input type="number" value={waterQuantity} onChange={(e) => setWaterQuantity(Number(e.target.value))} className={inputStyles} />
        </div>
        <div>
          <label className={typography.body}>Water Temp (°C)</label>
          <input type="number" value={waterTemp} onChange={(e) => setWaterTemp(Number(e.target.value))} className={inputStyles} />
        </div>
        <div>
          <label className={typography.body}>Air Quantity (ft³/hr)</label>
          <input type="number" value={airQuantity} onChange={(e) => setAirQuantity(Number(e.target.value))} className={inputStyles} />
        </div>
        <div>
          <label className={typography.body}>Air Temp (°C)</label>
          <input type="number" value={airTemp} onChange={(e) => setAirTemp(Number(e.target.value))} className={inputStyles} />
        </div>
        <div>
          <label className={typography.body}>Electricity (kW)</label>
          <input type="number" value={electricity} onChange={(e) => setElectricity(Number(e.target.value))} className={inputStyles} />
        </div>
        <div>
          <label className={typography.body}>Pressure (PSIG)</label>
          <input type="number" value={pressure} onChange={(e) => setPressure(Number(e.target.value))} className={inputStyles} />
        </div>
        <div>
          <label className={typography.body}>Temperature (°F)</label>
          <input type="number" value={temperature} onChange={(e) => setTemperature(Number(e.target.value))} className={inputStyles} />
        </div>
      </Grid>
      <TouchButton type="submit">Simulate Boiler</TouchButton>
    </form>
  );
}
"@ | Out-File -FilePath src/components/BoilerInputForm.tsx -Encoding utf8

# Create components/BoilerVisualization.tsx - Simplified visualization dashboard
@"
'use client';

import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import { Grid } from '@/components/Grid';
import { typography } from '@/lib/typography';
import { BoilerOutput } from '@/lib/boilerModel';

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

  const containerStyles = `
    \${typography.body}
    container-type: inline-size;
    padding: clamp(1rem, 3vw, 2rem);
  `;

  const cardStyles = `
    background-color: white;
    border-radius: var(--border-radius);
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
    padding: 1rem;
    @container (min-width: 300px) {
      padding: 1.5rem;
    }
  `;

  return (
    <div style={{ cssText: containerStyles }}>
      <Grid columns={{ xs: '1fr', md: 'repeat(2, 1fr)' }} gap="1.5rem">
        <div style={{ cssText: cardStyles }}>
          <h2 className={typography.h2}>Steam Output</h2>
          <p className={typography.body}>Flow Rate: {output.steam.flowRate.toFixed(2)} PPH</p>
          <p className={typography.body}>Pressure: {output.steam.pressure} PSIG</p>
          <p className={typography.body}>Temperature: {output.steam.temperature} °F</p>
        </div>
        <div style={{ cssText: cardStyles }}>
          <h2 className={typography.h2}>Energy Distribution</h2>
          <ResponsiveContainer width="100%" height={200}>
            <BarChart data={energyData}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="name" />
              <YAxis />
              <Tooltip />
              <Bar dataKey="value" fill="#3b82f6" />
            </BarChart>
          </ResponsiveContainer>
        </div>
        <div style={{ cssText: cardStyles }}>
          <h2 className={typography.h2}>Flue Gas Composition (%)</h2>
          <ResponsiveContainer width="100%" height={200}>
            <BarChart data={flueGasCompositionData}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="name" />
              <YAxis />
              <Tooltip />
              <Bar dataKey="value" fill="#10b981" />
            </BarChart>
          </ResponsiveContainer>
        </div>
        <div style={{ cssText: cardStyles }}>
          <h2 className={typography.h2}>Emissions</h2>
          <ResponsiveContainer width="100%" height={200}>
            <BarChart data={emissionsData}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="name" />
              <YAxis />
              <Tooltip />
              <Bar dataKey="value" fill="#f97316" />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </Grid>
    </div>
  );
}
"@ | Out-File -FilePath src/components/BoilerVisualization.tsx -Encoding utf8

# Create app/page.tsx - Main dashboard page
@"
import { useState } from 'react';
import BoilerInputForm from '@/components/BoilerInputForm';
import BoilerVisualization from '@/components/BoilerVisualization';
import { boiler, BoilerOutput } from '@/lib/boilerModel';
import { typography } from '@/lib/typography';
import { createResponsiveStyles } from '@/lib/responsiveUtils';

export default function Home() {
  const [output, setOutput] = useState<BoilerOutput | null>(null);

  const handleSubmit = (inputs: Parameters<typeof boiler>[0] & Parameters<typeof boiler>[1] & Parameters<typeof boiler>[2] & Parameters<typeof boiler>[3] & Parameters<typeof boiler>[4]) => {
    const result = boiler(inputs.fuel, inputs.water, inputs.air, inputs.electricity, inputs.controlSettings);
    setOutput(result);
  };

  const containerStyles = `
    \${typography.body}
    \${createResponsiveStyles('padding', { xs: '1rem', md: '2rem', lg: '3rem' })}
    max-width: var(--container-max-width);
    margin: 0 auto;
  `;

  return (
    <main style={{ cssText: containerStyles }}>
      <h1 className={typography.h1}>Boiler Visualization Dashboard</h1>
      <BoilerInputForm onSubmit={handleSubmit} />
      {output && <BoilerVisualization output={output} />}
    </main>
  );
}
"@ | Out-File -FilePath src/app/page.tsx -Encoding utf8

# Create styles/globals.css - Global styles with CSS variables
@"
:root {
  --container-max-width: 1200px;
  --container-padding: clamp(1rem, 5vw, 3rem);
  --grid-gap: clamp(1rem, 3vw, 2rem);
  --border-radius: clamp(4px, 1vw, 8px);
}

body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
  background-color: #f9fafb;
}

* {
  box-sizing: border-box;
}
"@ | Out-File -FilePath src/styles/globals.css -Encoding utf8

# Update app/layout.tsx - Include viewport meta tag
@"
import './styles/globals.css';
import { Inter } from 'next/font/google';

const inter = Inter({ subsets: ['latin'] });

export const metadata = {
  title: 'Boiler Visualization Dashboard',
  description: 'A responsive dashboard for boiler simulation',
  viewport: 'width=device-width, initial-scale=1',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className={inter.className}>{children}</body>
    </html>
  );
}
"@ | Out-File -FilePath src/app/layout.tsx -Encoding utf8

# Output success message
Write-Host "Improved Boiler Dashboard project created successfully. Navigate to $projectName and run 'npm run dev' to start."