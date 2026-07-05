import { describe, it, expect } from 'vitest';
import {
  convertAnnualToMonthlyRate,
  calculateSAC,
  calculatePrice,
  runSimulations,
  SimulationParams,
} from './utils/simulation.ts';
import { InterestRate, FinancialInstitution } from '@prisma/client';

describe('Simulation Business Logic Unit Tests', () => {
  describe('convertAnnualToMonthlyRate', () => {
    it('should correctly convert a 12% annual rate to its monthly equivalent', () => {
      const monthlyRate = convertAnnualToMonthlyRate(0.12);
      // (1 + 0.12)^(1/12) - 1 ≈ 0.0094887929
      expect(monthlyRate).toBeCloseTo(0.0094887929, 8);
    });

    it('should return 0 when the annual rate is 0', () => {
      const monthlyRate = convertAnnualToMonthlyRate(0);
      expect(monthlyRate).toBe(0);
    });
  });

  describe('calculateSAC', () => {
    it('should calculate SAC simulation payments and total cost accurately', () => {
      const financedAmount = 150000;
      const rateValue = 0.12;
      const monthlyRate = convertAnnualToMonthlyRate(rateValue); // ~0.00948879
      const term = 120;
      const monthlyIncome = 10000;

      const result = calculateSAC(financedAmount, monthlyRate, term, rateValue, monthlyIncome);

      // Amortization (A) = 150000 / 120 = 1250
      // First Interest = 150000 * 0.00948879 ≈ 1423.32
      // First Payment = 1250 + 1423.32 = 2673.32
      // Last Interest = 1250 * 0.00948879 ≈ 11.86
      // Last Payment = 1250 + 11.86 = 1261.86
      // Total Cost = 120 * (2673.32 + 1261.86) / 2 = 236110.80
      
      expect(result.firstPayment).toBeCloseTo(2673.32, 1);
      expect(result.lastPayment).toBeCloseTo(1261.86, 1);
      expect(result.totalCost).toBeCloseTo(236110.80, 0);
      expect(result.warnings).toHaveLength(0); // 2673.32 is <= 3000 (30% of 10000)
    });

    it('should add a warning if SAC first payment exceeds 30% of monthly income', () => {
      const financedAmount = 150000;
      const rateValue = 0.12;
      const monthlyRate = convertAnnualToMonthlyRate(rateValue);
      const term = 120;
      const monthlyIncome = 5000; // 30% is 1500

      const result = calculateSAC(financedAmount, monthlyRate, term, rateValue, monthlyIncome);

      expect(result.warnings).toContain('Comprometimento de renda superior a 30% da renda familiar');
    });
  });

  describe('calculatePrice', () => {
    it('should calculate Price simulation payments and total cost accurately', () => {
      const financedAmount = 150000;
      const rateValue = 0.12;
      const monthlyRate = convertAnnualToMonthlyRate(rateValue); // ~0.00948879
      const term = 120;
      const monthlyIncome = 10000;

      const result = calculatePrice(financedAmount, monthlyRate, term, rateValue, monthlyIncome);

      // P = 150000 * (i * (1+i)^120) / ((1+i)^120 - 1) ≈ 2099.21
      // Total Cost = P * 120 ≈ 251905.20
      
      expect(result.firstPayment).toBeCloseTo(2099.21, 1);
      expect(result.lastPayment).toBeCloseTo(2099.21, 1);
      expect(result.totalCost).toBeCloseTo(251905.20, 0);
      expect(result.warnings).toHaveLength(0); // 2099.21 <= 3000
    });

    it('should add a warning if Price payment exceeds 30% of monthly income', () => {
      const financedAmount = 150000;
      const rateValue = 0.12;
      const monthlyRate = convertAnnualToMonthlyRate(rateValue);
      const term = 120;
      const monthlyIncome = 5000; // 30% is 1500

      const result = calculatePrice(financedAmount, monthlyRate, term, rateValue, monthlyIncome);

      expect(result.warnings).toContain('Comprometimento de renda superior a 30% da renda familiar');
    });
  });

  describe('runSimulations', () => {
    const mockInstitution: FinancialInstitution = {
      id: 'inst-1',
      name: 'Banco Alfa',
      logoUrl: 'http://logo.com',
      isActive: true,
    };

    const mockRates: (InterestRate & { institution: FinancialInstitution })[] = [
      {
        id: 'rate-1',
        institutionId: 'inst-1',
        type: 'SAC',
        rateValue: 0.10,
        maxLTV: 0.80,
        minTerm: 120,
        maxTerm: 360,
        maxAge: 80,
        institution: mockInstitution,
      },
      {
        id: 'rate-2',
        institutionId: 'inst-1',
        type: 'Price',
        rateValue: 0.105,
        maxLTV: 0.80,
        minTerm: 120,
        maxTerm: 360,
        maxAge: 80,
        institution: mockInstitution,
      },
    ];

    it('should process both SAC and Price rates for an institution and group them', () => {
      const params: SimulationParams = {
        propertyValue: 200000,
        downPayment: 50000, // Financed: 150000 (LTV = 75%)
        monthlyIncome: 10000,
        age: 35,
        term: 240, // 20 years (35 + 20 = 55 <= 80)
      };

      const results = runSimulations(params, mockRates);

      expect(results).toHaveLength(1);
      const res = results[0];
      expect(res.institutionName).toBe('Banco Alfa');
      expect(res.financedAmount).toBe(150000);
      expect(res.sac).not.toBeNull();
      expect(res.price).not.toBeNull();
      expect(res.warnings).toHaveLength(0);
    });

    it('should add age warning if age + term/12 > 80', () => {
      const params: SimulationParams = {
        propertyValue: 200000,
        downPayment: 50000,
        monthlyIncome: 10000,
        age: 65,
        term: 240, // 20 years (65 + 20 = 85 > 80)
      };

      const results = runSimulations(params, mockRates);
      const res = results[0];
      expect(res.warnings).toContain('A idade do proponente somada ao prazo de financiamento ultrapassa o limite de 80 anos');
    });

    it('should add LTV warning if LTV exceeds maxLTV', () => {
      const params: SimulationParams = {
        propertyValue: 200000,
        downPayment: 20000, // Financed: 180000 (LTV = 90% > 80%)
        monthlyIncome: 10000,
        age: 35,
        term: 240,
      };

      const results = runSimulations(params, mockRates);
      const res = results[0];
      expect(res.warnings.some(w => w.includes('LTV'))).toBe(true);
    });

    it('should add Term warning if term is out of bounds', () => {
      const params: SimulationParams = {
        propertyValue: 200000,
        downPayment: 50000,
        monthlyIncome: 10000,
        age: 35,
        term: 60, // Less than minTerm 120
      };

      const results = runSimulations(params, mockRates);
      const res = results[0];
      expect(res.warnings.some(w => w.includes('Prazo'))).toBe(true);
    });
  });
});
