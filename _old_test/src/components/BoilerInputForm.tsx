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
    addActivity(`Ran simulation: ${fuelType}, ${fuelQuantity} lb/hr, ${pressure} PSIG`);
  };

  const inputStyles = `
    width: 100%;
    padding: 0.5rem;
    border: 1px solid #e2e8f0;
    border-radius: 8px;
    font-size: clamp(0.875rem, 2.5vw, 0.95rem);
    color: #1e293b;
    &:focus {
      outline: 2px solid #3b82f6;
      outline-offset: 2px;
    }
  `;

  const buttonStyles = `
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
      box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
    }
    &:focus {
      outline: 2px solid #3b82f6;
      outline-offset: 2px;
    }
  `;

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
