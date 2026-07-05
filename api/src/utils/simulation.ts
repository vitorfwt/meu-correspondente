import { InterestRate, FinancialInstitution } from '@prisma/client';

export interface SimulationParams {
  propertyValue: number;
  downPayment: number;
  monthlyIncome: number;
  age: number;
  term: number;
}

export interface SimulationDetails {
  rateValue: number;
  monthlyRate: number;
  firstPayment: number;
  lastPayment: number;
  totalCost: number;
  warnings: string[];
}

export interface InstitutionSimulationResult {
  institutionId: string;
  institutionName: string;
  logoUrl: string | null;
  propertyValue: number;
  downPayment: number;
  financedAmount: number;
  term: number;
  sac: SimulationDetails | null;
  price: SimulationDetails | null;
  warnings: string[];
}

/**
 * Converte a taxa de juros anual para taxa mensal equivalente.
 * Formula: taxaMensal = (1 + rateValue)^(1/12) - 1
 */
export function convertAnnualToMonthlyRate(annualRate: number): number {
  return Math.pow(1 + annualRate, 1 / 12) - 1;
}

/**
 * Calcula a simulação na modalidade SAC.
 */
export function calculateSAC(
  financedAmount: number,
  monthlyRate: number,
  term: number,
  rateValue: number,
  monthlyIncome: number
): SimulationDetails {
  const warnings: string[] = [];
  const A = financedAmount / term;
  const firstPayment = A + financedAmount * monthlyRate;
  const lastPayment = A + A * monthlyRate;
  const totalCost = (term * (firstPayment + lastPayment)) / 2;

  if (firstPayment > monthlyIncome * 0.3) {
    warnings.push('Comprometimento de renda superior a 30% da renda familiar');
  }

  return {
    rateValue,
    monthlyRate,
    firstPayment: Number(firstPayment.toFixed(2)),
    lastPayment: Number(lastPayment.toFixed(2)),
    totalCost: Number(totalCost.toFixed(2)),
    warnings,
  };
}

/**
 * Calcula a simulação na modalidade PRICE.
 */
export function calculatePrice(
  financedAmount: number,
  monthlyRate: number,
  term: number,
  rateValue: number,
  monthlyIncome: number
): SimulationDetails {
  const warnings: string[] = [];
  let monthlyPayment = 0;

  if (monthlyRate === 0) {
    monthlyPayment = financedAmount / term;
  } else {
    const compoundFactor = Math.pow(1 + monthlyRate, term);
    monthlyPayment =
      (financedAmount * (monthlyRate * compoundFactor)) / (compoundFactor - 1);
  }

  const totalCost = monthlyPayment * term;

  if (monthlyPayment > monthlyIncome * 0.3) {
    warnings.push('Comprometimento de renda superior a 30% da renda familiar');
  }

  return {
    rateValue,
    monthlyRate,
    firstPayment: Number(monthlyPayment.toFixed(2)),
    lastPayment: Number(monthlyPayment.toFixed(2)),
    totalCost: Number(totalCost.toFixed(2)),
    warnings,
  };
}

/**
 * Executa as simulações para todas as taxas de juros ativas fornecidas,
 * agrupando os resultados por instituição.
 */
export function runSimulations(
  params: SimulationParams,
  interestRates: (InterestRate & { institution: FinancialInstitution })[]
): InstitutionSimulationResult[] {
  const { propertyValue, downPayment, monthlyIncome, age, term } = params;
  const financedAmount = propertyValue - downPayment;

  // Agrupar as taxas por instituição
  const institutionMap = new Map<
    string,
    {
      institution: FinancialInstitution;
      rates: InterestRate[];
    }
  >();

  for (const rate of interestRates) {
    const instId = rate.institutionId;
    if (!institutionMap.has(instId)) {
      institutionMap.set(instId, {
        institution: rate.institution,
        rates: [],
      });
    }
    institutionMap.get(instId)!.rates.push(rate);
  }

  const results: InstitutionSimulationResult[] = [];

  for (const [instId, data] of institutionMap.entries()) {
    const { institution, rates } = data;
    const institutionWarnings: string[] = [];

    // Validar idade limite: idade + prazo em anos > 80
    if (age + term / 12 > 80) {
      institutionWarnings.push(
        'A idade do proponente somada ao prazo de financiamento ultrapassa o limite de 80 anos'
      );
    }

    // Achar taxas cadastradas para SAC e Price
    const sacRate = rates.find((r) => r.type.toUpperCase() === 'SAC');
    const priceRate = rates.find((r) => r.type.toUpperCase() === 'PRICE');

    let sacResult: SimulationDetails | null = null;
    let priceResult: SimulationDetails | null = null;

    if (sacRate) {
      // Validar limites específicos da taxa do banco
      const ltv = financedAmount / propertyValue;
      if (ltv > sacRate.maxLTV) {
        institutionWarnings.push(
          `Valor financiado excede o limite máximo de LTV do banco (${(sacRate.maxLTV * 100).toFixed(0)}%) para a modalidade SAC`
        );
      }
      if (term < sacRate.minTerm || term > sacRate.maxTerm) {
        institutionWarnings.push(
          `Prazo solicitado fora dos limites aceitos pelo banco para a modalidade SAC (${sacRate.minTerm} a ${sacRate.maxTerm} meses)`
        );
      }

      const monthlyRate = convertAnnualToMonthlyRate(sacRate.rateValue);
      sacResult = calculateSAC(
        financedAmount,
        monthlyRate,
        term,
        sacRate.rateValue,
        monthlyIncome
      );
    }

    if (priceRate) {
      // Validar limites específicos da taxa do banco
      const ltv = financedAmount / propertyValue;
      if (ltv > priceRate.maxLTV) {
        institutionWarnings.push(
          `Valor financiado excede o limite máximo de LTV do banco (${(priceRate.maxLTV * 100).toFixed(0)}%) para a modalidade PRICE`
        );
      }
      if (term < priceRate.minTerm || term > priceRate.maxTerm) {
        institutionWarnings.push(
          `Prazo solicitado fora dos limites aceitos pelo banco para a modalidade PRICE (${priceRate.minTerm} a ${priceRate.maxTerm} meses)`
        );
      }

      const monthlyRate = convertAnnualToMonthlyRate(priceRate.rateValue);
      priceResult = calculatePrice(
        financedAmount,
        monthlyRate,
        term,
        priceRate.rateValue,
        monthlyIncome
      );
    }

    results.push({
      institutionId: instId,
      institutionName: institution.name,
      logoUrl: institution.logoUrl,
      propertyValue,
      downPayment,
      financedAmount,
      term,
      sac: sacResult,
      price: priceResult,
      warnings: Array.from(new Set(institutionWarnings)), // Remove duplicatas de avisos gerais
    });
  }

  return results;
}
