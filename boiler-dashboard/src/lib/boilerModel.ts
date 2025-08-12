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
