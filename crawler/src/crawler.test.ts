import { describe, it, expect, beforeAll, afterAll, afterEach } from 'vitest';
import fs from 'fs';
import path from 'path';
import { parseRatesCSV } from './parser.ts';
import { RateCrawlerService } from './crawler.service.ts';
import { prisma } from './db.ts';

describe('Crawler Service & Parser Tests', () => {
  const tempCsvPath = path.resolve(process.cwd(), 'temp_test_rates.csv');

  beforeAll(async () => {
    await prisma.$connect();
  });

  afterAll(async () => {
    // Clean up temporary files
    if (fs.existsSync(tempCsvPath)) {
      fs.unlinkSync(tempCsvPath);
    }
    await prisma.$disconnect();
  });

  describe('CSV Parser Unit Tests', () => {
    it('should successfully parse a valid CSV file', () => {
      const csvContent = [
        'institutionName,rateType,rateValue,maxLTV,minTerm,maxTerm,maxAge',
        'Test Bank,SAC,0.0825,0.80,120,420,80',
        'Test Bank,Price,0.0875,0.80,120,360,80',
      ].join('\n');

      fs.writeFileSync(tempCsvPath, csvContent, 'utf-8');

      const parsed = parseRatesCSV(tempCsvPath);
      expect(parsed).toHaveLength(2);
      expect(parsed[0]).toEqual({
        institutionName: 'Test Bank',
        rateType: 'SAC',
        rateValue: 0.0825,
        maxLTV: 0.8,
        minTerm: 120,
        maxTerm: 420,
        maxAge: 80,
      });
      expect(parsed[1]).toEqual({
        institutionName: 'Test Bank',
        rateType: 'Price',
        rateValue: 0.0875,
        maxLTV: 0.8,
        minTerm: 120,
        maxTerm: 360,
        maxAge: 80,
      });
    });

    it('should throw an error if file does not exist', () => {
      expect(() => parseRatesCSV('non_existent_file.csv')).toThrow();
    });
  });

  describe('RateCrawlerService Integration Tests', () => {
    const testInstName = 'Integration Test Bank';

    afterEach(async () => {
      // Clean up database records created for integration tests
      const institution = await prisma.financialInstitution.findFirst({
        where: { name: { equals: testInstName, mode: 'insensitive' } },
      });
      if (institution) {
        // Cascade delete will delete associated interest rates
        await prisma.financialInstitution.delete({
          where: { id: institution.id },
        });
      }
    });

    it('should insert new institution and interest rates if they do not exist', async () => {
      const csvContent = [
        'institutionName,rateType,rateValue,maxLTV,minTerm,maxTerm,maxAge',
        `${testInstName},SAC,0.0950,0.80,120,420,80`,
        `${testInstName},Price,0.0980,0.80,120,360,80`,
      ].join('\n');

      fs.writeFileSync(tempCsvPath, csvContent, 'utf-8');

      const crawlerService = new RateCrawlerService();
      await crawlerService.importRatesFromCSV(tempCsvPath);

      // Verify insertion
      const inst = await prisma.financialInstitution.findFirst({
        where: { name: testInstName },
        include: { interestRates: true },
      });

      expect(inst).not.toBeNull();
      expect(inst?.isActive).toBe(true);
      expect(inst?.interestRates).toHaveLength(2);

      const sacRate = inst?.interestRates.find(r => r.type === 'SAC');
      expect(sacRate).toBeDefined();
      expect(sacRate?.rateValue).toBe(0.0950);
      expect(sacRate?.maxLTV).toBe(0.80);
      expect(sacRate?.minTerm).toBe(120);
      expect(sacRate?.maxTerm).toBe(420);
      expect(sacRate?.maxAge).toBe(80);

      const priceRate = inst?.interestRates.find(r => r.type === 'Price');
      expect(priceRate).toBeDefined();
      expect(priceRate?.rateValue).toBe(0.0980);
    });

    it('should update (upsert) interest rates if institution and rate type already exist', async () => {
      // 1. Initial insert
      const initialCsv = [
        'institutionName,rateType,rateValue,maxLTV,minTerm,maxTerm,maxAge',
        `${testInstName},SAC,0.0950,0.80,120,420,80`,
      ].join('\n');

      fs.writeFileSync(tempCsvPath, initialCsv, 'utf-8');

      const crawlerService = new RateCrawlerService();
      await crawlerService.importRatesFromCSV(tempCsvPath);

      // Verify initial setup
      let inst = await prisma.financialInstitution.findFirst({
        where: { name: testInstName },
        include: { interestRates: true },
      });
      expect(inst?.interestRates).toHaveLength(1);
      expect(inst?.interestRates[0].rateValue).toBe(0.0950);

      // 2. Perform updates
      const updatedCsv = [
        'institutionName,rateType,rateValue,maxLTV,minTerm,maxTerm,maxAge',
        `${testInstName},SAC,0.0899,0.85,180,480,75`,
      ].join('\n');

      fs.writeFileSync(tempCsvPath, updatedCsv, 'utf-8');
      await crawlerService.importRatesFromCSV(tempCsvPath);

      // Verify update (upsert)
      inst = await prisma.financialInstitution.findFirst({
        where: { name: testInstName },
        include: { interestRates: true },
      });
      expect(inst?.interestRates).toHaveLength(1);
      expect(inst?.interestRates[0].rateValue).toBe(0.0899);
      expect(inst?.interestRates[0].maxLTV).toBe(0.85);
      expect(inst?.interestRates[0].minTerm).toBe(180);
      expect(inst?.interestRates[0].maxTerm).toBe(480);
      expect(inst?.interestRates[0].maxAge).toBe(75);
    });
  });
});
