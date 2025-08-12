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
            value={`${output.steam.flowRate.toFixed(2)} PPH`}
            change="+0.0%"
            changeType="positive"
          />
          <StatCard
            icon={Thermometer}
            title="Steam Pressure"
            value={`${output.steam.pressure} PSIG`}
            change="+0.0%"
            changeType="positive"
          />
          <StatCard
            icon={Thermometer}
            title="Steam Temperature"
            value={`${output.steam.temperature} °F`}
            change="+0.0%"
            changeType="positive"
          />
          <StatCard
            icon={Factory}
            title="Efficiency"
            value={`${((output.steam.flowRate * 1000) / (output.steam.flowRate * 1000 + output.wasteHeat) * 100).toFixed(1)}%`}
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
