import { prisma } from '../src/db.ts';

async function main() {
  console.log('Seeding database...');

  // Clean existing data to prevent duplicates
  await prisma.interestRate.deleteMany({});
  await prisma.simulationHistory.deleteMany({});
  await prisma.financialInstitution.deleteMany({});
  await prisma.user.deleteMany({});

  // 1. Create a dummy user
  const user = await prisma.user.create({
    data: {
      name: 'João Silva',
      email: 'joao.silva@example.com',
      role: 'client',
    },
  });
  console.log(`User created: ${user.name}`);

  // 2. Create Institutions and Rates
  const institutionsData = [
    {
      name: 'Caixa Econômica Federal',
      logoUrl: 'https://example.com/logos/caixa.png',
      isActive: true,
      rates: [
        { type: 'SAC', rateValue: 0.0999, maxLTV: 0.80, minTerm: 120, maxTerm: 420, maxAge: 80 },
        { type: 'Price', rateValue: 0.1025, maxLTV: 0.80, minTerm: 120, maxTerm: 360, maxAge: 80 },
      ],
    },

    {
      name: 'Itaú Unibanco',
      logoUrl: 'https://example.com/logos/itau.png',
      isActive: true,
      rates: [
        { type: 'SAC', rateValue: 0.1099, maxLTV: 0.82, minTerm: 120, maxTerm: 420, maxAge: 80 },
        { type: 'Price', rateValue: 0.1125, maxLTV: 0.82, minTerm: 120, maxTerm: 360, maxAge: 80 },
      ],
    },
  ];

  for (const inst of institutionsData) {
    const createdInstitution = await prisma.financialInstitution.create({
      data: {
        name: inst.name,
        logoUrl: inst.logoUrl,
        isActive: inst.isActive,
      },
    });

    console.log(`Institution created: ${createdInstitution.name}`);

    for (const rate of inst.rates) {
      await prisma.interestRate.create({
        data: {
          institutionId: createdInstitution.id,
          type: rate.type,
          rateValue: rate.rateValue,
          maxLTV: rate.maxLTV,
          minTerm: rate.minTerm,
          maxTerm: rate.maxTerm,
          maxAge: rate.maxAge,
        },
      });
    }
    console.log(`Rates created for ${createdInstitution.name}`);
  }

  console.log('Database seeding finished successfully.');
}

main()
  .catch((e) => {
    console.error('Error seeding database:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
