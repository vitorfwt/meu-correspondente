import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { prisma } from './db.ts';

describe('Database Integration Tests', () => {
  beforeAll(async () => {
    await prisma.$connect();
  });

  afterAll(async () => {
    await prisma.$disconnect();
  });

  it('should successfully insert and retrieve a user', async () => {
    const testEmail = `test-user-${Date.now()}@example.com`;
    const createdUser = await prisma.user.create({
      data: {
        name: 'Test User',
        email: testEmail,
        role: 'client',
      },
    });

    expect(createdUser.id).toBeDefined();
    expect(createdUser.name).toBe('Test User');
    expect(createdUser.email).toBe(testEmail);
    expect(createdUser.role).toBe('client');

    const fetchedUser = await prisma.user.findUnique({
      where: { id: createdUser.id },
    });

    expect(fetchedUser).not.toBeNull();
    expect(fetchedUser?.email).toBe(testEmail);

    // Clean up
    await prisma.user.delete({ where: { id: createdUser.id } });
  });

  it('should retrieve active financial institutions and their interest rates', async () => {
    const institutions = await prisma.financialInstitution.findMany({
      include: {
        interestRates: true,
      },
    });

    expect(institutions.length).toBeGreaterThanOrEqual(3);
    
    const caixas = institutions.filter(i => i.name.includes('Caixa'));
    expect(caixas.length).toBeGreaterThan(0);
    expect(caixas[0].interestRates.length).toBeGreaterThan(0);
  });

  it('should successfully save and retrieve simulation history', async () => {
    // 1. Create a temporary user and institution for this simulation
    const testEmail = `sim-user-${Date.now()}@example.com`;
    const user = await prisma.user.create({
      data: {
        name: 'Sim User',
        email: testEmail,
        role: 'client',
      },
    });

    const institution = await prisma.financialInstitution.create({
      data: {
        name: 'Sim Bank',
        isActive: true,
      },
    });

    // 2. Save the simulation
    const simulation = await prisma.simulationHistory.create({
      data: {
        userId: user.id,
        propertyValue: 300000.0,
        downPayment: 60000.0,
        monthlyIncome: 8000.0,
        age: 35,
        term: 360,
        selectedInstitutionId: institution.id,
        resultMonthlyPayment: 2200.0,
        status: 'completed',
      },
    });

    expect(simulation.id).toBeDefined();
    expect(simulation.propertyValue).toBe(300000.0);
    expect(simulation.downPayment).toBe(60000.0);
    expect(simulation.selectedInstitutionId).toBe(institution.id);

    // 3. Fetch from history
    const history = await prisma.simulationHistory.findUnique({
      where: { id: simulation.id },
      include: {
        user: true,
        institution: true,
      },
    });

    expect(history).not.toBeNull();
    expect(history?.user?.email).toBe(testEmail);
    expect(history?.institution?.name).toBe('Sim Bank');

    // 4. Clean up
    await prisma.simulationHistory.delete({ where: { id: simulation.id } });
    await prisma.financialInstitution.delete({ where: { id: institution.id } });
    await prisma.user.delete({ where: { id: user.id } });
  });
});
