import { prisma } from '../src/db.ts';

async function main() {
  console.log('Seeding database...');

  // Clean existing data to prevent duplicates
  await prisma.interestRate.deleteMany({});
  await prisma.simulationHistory.deleteMany({});
  await prisma.financialInstitution.deleteMany({});
  await prisma.partner.deleteMany({});
  await prisma.macroeconomicIndicator.deleteMany({});
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
      logoUrl: '/public/logos/caixa.png',
      isActive: true,
      rates: [
        { type: 'SAC', rateValue: 0.0999, maxLTV: 0.80, minTerm: 120, maxTerm: 420, maxAge: 80 },
        { type: 'Price', rateValue: 0.1025, maxLTV: 0.80, minTerm: 120, maxTerm: 360, maxAge: 80 },
      ],
    },

    {
      name: 'Itaú Unibanco',
      logoUrl: '/public/logos/itau.png',
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

  // 3. Create Partners (Correspondentes Bancários)
  const partnersData = [
    {
      name: 'Roberto Souza',
      email: 'roberto.souza@correspondentecaixa.com.br',
      phone: '(11) 98765-4321',
      company: 'Roberto Caixa Correspondente',
      photoUrl: 'https://images.unsplash.com/photo-1560250097-0b93528c311a?auto=format&fit=crop&q=80&w=200',
    },
    {
      name: 'Mariana Costa',
      email: 'mariana.costa@itauparceiros.com.br',
      phone: '(21) 99888-7766',
      company: 'Mariana Assessoria Imobiliária (Itaú)',
      photoUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&q=80&w=200',
    },
    {
      name: 'Pedro Oliveira',
      email: 'pedro.oliveira@correspondentecredito.com.br',
      phone: '(31) 99111-2233',
      company: 'Oliveira Crédito e Financiamento (Multibancos)',
      photoUrl: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?auto=format&fit=crop&q=80&w=200',
    },
  ];

  for (const partner of partnersData) {
    const createdPartner = await prisma.partner.create({
      data: partner,
    });
    console.log(`Partner created: ${createdPartner.name} (${createdPartner.company})`);
  }

  // 4. Create Macroeconomic Indicators
  const indicatorsData = [
    { name: 'SELIC', value: 0.105 },
    { name: 'IPCA', value: 0.045 },
    { name: 'TR', value: 0.0012 },
    { name: 'POUPANCA', value: 0.0617 },
  ];

  for (const indicator of indicatorsData) {
    const createdIndicator = await prisma.macroeconomicIndicator.create({
      data: indicator,
    });
    console.log(`Indicator created: ${createdIndicator.name} (${createdIndicator.value})`);
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
