import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import request from 'supertest';
import app from './app.ts';
import { prisma } from './db.ts';
import { generateToken } from './utils/jwt.ts';

describe('Simulation Routes Integration Tests', () => {
  let testUserId: string;
  const testEmailsToClean: string[] = [];

  beforeAll(async () => {
    await prisma.$connect();

    // Criar um usuário de teste para validações de persistência
    const email = `integration-user-${Date.now()}@example.com`;
    testEmailsToClean.push(email);

    const user = await prisma.user.create({
      data: {
        name: 'Integration User',
        email,
        role: 'client',
      },
    });
    testUserId = user.id;
  });

  afterAll(async () => {
    // Limpar simulações vinculadas ao usuário de teste
    await prisma.simulationHistory.deleteMany({
      where: {
        userId: testUserId,
      },
    });

    // Limpar os usuários criados
    if (testEmailsToClean.length > 0) {
      await prisma.user.deleteMany({
        where: {
          email: {
            in: testEmailsToClean,
          },
        },
      });
    }
    await prisma.$disconnect();
  });

  describe('POST /api/simulate', () => {
    it('should successfully run simulation without restrictions (Happy Path)', async () => {
      const response = await request(app)
        .post('/api/simulate')
        .send({
          propertyValue: 200000.0,
          downPayment: 50000.0, // Financed: 150000
          monthlyIncome: 12000.0, // High income to avoid income warnings
          age: 30,
          term: 120, // 10 years (30 + 10 = 40 <= 80)
        });

      expect(response.status).toBe(200);
      expect(Array.isArray(response.body)).toBe(true);
      expect(response.body.length).toBeGreaterThan(0);

      const firstResult = response.body[0];
      expect(firstResult).toHaveProperty('institutionId');
      expect(firstResult).toHaveProperty('institutionName');
      expect(firstResult.financedAmount).toBe(150000);
      expect(firstResult.term).toBe(120);
      expect(firstResult.warnings).toHaveLength(0);

      // Verificações das modalidades
      if (firstResult.sac) {
        expect(firstResult.sac.firstPayment).toBeGreaterThan(0);
        expect(firstResult.sac.lastPayment).toBeGreaterThan(0);
        expect(firstResult.sac.totalCost).toBeGreaterThan(150000);
        expect(firstResult.sac.warnings).toHaveLength(0);
      }
      if (firstResult.price) {
        expect(firstResult.price.firstPayment).toBeGreaterThan(0);
        expect(firstResult.price.totalCost).toBeGreaterThan(150000);
        expect(firstResult.price.warnings).toHaveLength(0);
      }
    });

    it('should return warnings when income commitment limit is exceeded', async () => {
      const response = await request(app)
        .post('/api/simulate')
        .send({
          propertyValue: 300000.0,
          downPayment: 30000.0, // Financed: 270000
          monthlyIncome: 1500.0, // 30% is 450 (very low, payments will easily exceed this)
          age: 30,
          term: 120,
        });

      expect(response.status).toBe(200);
      expect(Array.isArray(response.body)).toBe(true);

      const firstResult = response.body[0];
      // Pelo menos um das modalidades deve acusar comprometimento de renda
      const hasIncomeWarning = 
        (firstResult.sac && firstResult.sac.warnings.some((w: string) => w.includes('Comprometimento'))) ||
        (firstResult.price && firstResult.price.warnings.some((w: string) => w.includes('Comprometimento')));

      expect(hasIncomeWarning).toBe(true);
    });

    it('should return age warning when age + term/12 > 80', async () => {
      const response = await request(app)
        .post('/api/simulate')
        .send({
          propertyValue: 200000.0,
          downPayment: 50000.0,
          monthlyIncome: 10000.0,
          age: 72,
          term: 120, // 72 + 10 = 82 > 80
        });

      expect(response.status).toBe(200);
      expect(Array.isArray(response.body)).toBe(true);

      const firstResult = response.body[0];
      expect(firstResult.warnings).toContain('A idade do proponente somada ao prazo de financiamento ultrapassa o limite de 80 anos');
    });

    it('should return 400 Bad Request when mandatory fields are missing', async () => {
      const response = await request(app)
        .post('/api/simulate')
        .send({
          propertyValue: 200000.0,
          downPayment: 50000.0,
          // monthlyIncome, age, term are missing
        });

      expect(response.status).toBe(400);
      expect(response.body.error).toBe('All fields (propertyValue, downPayment, monthlyIncome, age, term) are required');
    });

    it('should return 400 Bad Request when inputs are invalid types or negative', async () => {
      const response = await request(app)
        .post('/api/simulate')
        .send({
          propertyValue: 'two hundred thousand', // invalid
          downPayment: -50000.0, // negative
          monthlyIncome: 10000.0,
          age: 30,
          term: 120,
        });

      expect(response.status).toBe(400);
    });

    it('should return 400 Bad Request when downPayment is greater than propertyValue', async () => {
      const response = await request(app)
        .post('/api/simulate')
        .send({
          propertyValue: 100000.0,
          downPayment: 120000.0, // Downpayment > property value
          monthlyIncome: 5000.0,
          age: 30,
          term: 120,
        });

      expect(response.status).toBe(400);
      expect(response.body.error).toBe('Down payment cannot be equal to or greater than property value');
    });

    it('should save simulation history when user is authenticated via Bearer token', async () => {
      const token = generateToken({
        id: testUserId,
        email: `integration-user@example.com`,
        role: 'client',
      });

      // Contar registros antes da chamada
      const initialCount = await prisma.simulationHistory.count({
        where: { userId: testUserId },
      });

      const response = await request(app)
        .post('/api/simulate')
        .set('Authorization', `Bearer ${token}`)
        .send({
          propertyValue: 200000.0,
          downPayment: 50000.0,
          monthlyIncome: 10000.0,
          age: 30,
          term: 120,
        });

      expect(response.status).toBe(200);

      // Contar registros depois da chamada
      const finalCount = await prisma.simulationHistory.count({
        where: { userId: testUserId },
      });

      expect(finalCount).toBeGreaterThan(initialCount);

      // Validar os registros inseridos
      const history = await prisma.simulationHistory.findMany({
        where: { userId: testUserId },
      });

      expect(history[0].propertyValue).toBe(200000.0);
      expect(history[0].downPayment).toBe(50000.0);
    });

    it('should save simulation history when userId is explicitly provided in payload', async () => {
      // Limpar histórico para isolar este teste
      await prisma.simulationHistory.deleteMany({
        where: { userId: testUserId },
      });

      const response = await request(app)
        .post('/api/simulate')
        .send({
          propertyValue: 250000.0,
          downPayment: 60000.0,
          monthlyIncome: 11000.0,
          age: 32,
          term: 180,
          userId: testUserId, // Passado explicitamente no payload
        });

      expect(response.status).toBe(200);

      const history = await prisma.simulationHistory.findMany({
        where: { userId: testUserId },
      });

      expect(history.length).toBeGreaterThan(0);
      expect(history[0].propertyValue).toBe(250000.0);
      expect(history[0].downPayment).toBe(60000.0);
      expect(history[0].term).toBe(180);
    });
  });
});
