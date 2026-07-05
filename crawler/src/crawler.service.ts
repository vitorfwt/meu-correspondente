import { prisma } from './db.ts';
import { parseRatesCSV } from './parser.ts';

export class RateCrawlerService {
  async importRatesFromCSV(filePath: string): Promise<void> {
    const rawRates = parseRatesCSV(filePath);

    for (const rawRate of rawRates) {
      // 1. Find or create the financial institution
      let institution = await prisma.financialInstitution.findFirst({
        where: {
          name: {
            equals: rawRate.institutionName,
            mode: 'insensitive',
          },
        },
      });

      if (!institution) {
        institution = await prisma.financialInstitution.create({
          data: {
            name: rawRate.institutionName,
            isActive: true,
          },
        });
      }

      // 2. Perform upsert on InterestRate
      const existingRate = await prisma.interestRate.findFirst({
        where: {
          institutionId: institution.id,
          type: rawRate.rateType,
        },
      });

      if (existingRate) {
        await prisma.interestRate.update({
          where: { id: existingRate.id },
          data: {
            rateValue: rawRate.rateValue,
            maxLTV: rawRate.maxLTV,
            minTerm: rawRate.minTerm,
            maxTerm: rawRate.maxTerm,
            maxAge: rawRate.maxAge,
          },
        });
      } else {
        await prisma.interestRate.create({
          data: {
            institutionId: institution.id,
            type: rawRate.rateType,
            rateValue: rawRate.rateValue,
            maxLTV: rawRate.maxLTV,
            minTerm: rawRate.minTerm,
            maxTerm: rawRate.maxTerm,
            maxAge: rawRate.maxAge,
          },
        });
      }
    }
  }
}
