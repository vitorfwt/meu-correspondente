import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import request from 'supertest';
import app from './app.ts';
import { prisma } from './db.ts';
import { generateToken } from './utils/jwt.ts';

describe('New Endpoints Integration Tests', () => {
  let clientUser: any;
  let clientToken: string;
  let otherClientUser: any;
  let otherClientToken: string;
  let brokerUser: any;
  let brokerToken: string;
  let testInstitution: any;
  let testInterestRate: any;
  let testSimulation: any;

  const emailsToClean: string[] = [];
  const instIdsToClean: string[] = [];

  beforeAll(async () => {
    await prisma.$connect();

    // 1. Criar usuários de teste
    const clientEmail = `client-${Date.now()}@example.com`;
    const otherEmail = `other-${Date.now()}@example.com`;
    const brokerEmail = `broker-${Date.now()}@example.com`;
    emailsToClean.push(clientEmail, otherEmail, brokerEmail);

    clientUser = await prisma.user.create({
      data: {
        name: 'Client User',
        email: clientEmail,
        role: 'client',
      },
    });
    clientToken = generateToken({ id: clientUser.id, email: clientUser.email, role: clientUser.role });

    otherClientUser = await prisma.user.create({
      data: {
        name: 'Other Client User',
        email: otherEmail,
        role: 'client',
      },
    });
    otherClientToken = generateToken({ id: otherClientUser.id, email: otherClientUser.email, role: otherClientUser.role });

    brokerUser = await prisma.user.create({
      data: {
        name: 'Broker User',
        email: brokerEmail,
        role: 'broker',
        creci: '123456',
        creciState: 'SP',
      },
    });
    brokerToken = generateToken({ id: brokerUser.id, email: brokerUser.email, role: brokerUser.role });

    // 2. Criar Instituição e Taxa de Juros para a simulação
    testInstitution = await prisma.financialInstitution.create({
      data: {
        name: 'Test Bank',
        isActive: true,
        logoUrl: '/public/logos/test.png',
      },
    });
    instIdsToClean.push(testInstitution.id);

    testInterestRate = await prisma.interestRate.create({
      data: {
        institutionId: testInstitution.id,
        type: 'SAC',
        rateValue: 0.10,
        maxLTV: 0.80,
        minTerm: 120,
        maxTerm: 360,
        maxAge: 80,
      },
    });

    // 3. Criar uma Simulação vinculada ao clientUser
    testSimulation = await prisma.simulationHistory.create({
      data: {
        userId: clientUser.id,
        propertyValue: 300000,
        downPayment: 60000,
        monthlyIncome: 10000,
        age: 35,
        term: 240,
        selectedInstitutionId: testInstitution.id,
        resultMonthlyPayment: 2500,
        status: 'completed',
      },
    });
  });

  afterAll(async () => {
    // Limpar simulações
    if (testSimulation) {
      await prisma.simulationHistory.deleteMany({
        where: {
          id: testSimulation.id,
        },
      });
    }

    // Limpar taxas e instituições
    await prisma.interestRate.deleteMany({
      where: {
        institutionId: {
          in: instIdsToClean,
        },
      },
    });

    await prisma.financialInstitution.deleteMany({
      where: {
        id: {
          in: instIdsToClean,
        },
      },
    });

    // Limpar usuários
    await prisma.user.deleteMany({
      where: {
        email: {
          in: emailsToClean,
        },
      },
    });

    await prisma.$disconnect();
  });

  describe('Profile Endpoints', () => {
    it('GET /api/profile should return 401 when unauthorized', async () => {
      const response = await request(app).get('/api/profile');
      expect(response.status).toBe(401);
    });

    it('GET /api/profile should return user profile data when authorized', async () => {
      const response = await request(app)
        .get('/api/profile')
        .set('Authorization', `Bearer ${clientToken}`);
      
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('id', clientUser.id);
      expect(response.body).toHaveProperty('email', clientUser.email);
      expect(response.body).toHaveProperty('role', 'client');
    });

    it('PUT /api/profile should return 401 when unauthorized', async () => {
      const response = await request(app).put('/api/profile').send({ name: 'New Name' });
      expect(response.status).toBe(401);
    });

    it('PUT /api/profile should update client profile data successfully', async () => {
      const response = await request(app)
        .put('/api/profile')
        .set('Authorization', `Bearer ${clientToken}`)
        .send({
          name: 'Updated Name',
        });
      
      expect(response.status).toBe(200);
      expect(response.body.name).toBe('Updated Name');
    });

    it('PUT /api/profile should fail to set role to broker without CRECI or CRECI State', async () => {
      const response = await request(app)
        .put('/api/profile')
        .set('Authorization', `Bearer ${clientToken}`)
        .send({
          role: 'broker',
        });
      
      expect(response.status).toBe(400);
      expect(response.body.error).toContain('CRECI and CRECI State are required');
    });

    it('PUT /api/profile should fail to set role to broker with invalid CRECI format', async () => {
      const response = await request(app)
        .put('/api/profile')
        .set('Authorization', `Bearer ${clientToken}`)
        .send({
          role: 'broker',
          creci: '123', // less than 4 chars
          creciState: 'SP',
        });
      
      expect(response.status).toBe(400);
      expect(response.body.error).toContain('CRECI must be between 4 and 15 characters');

      const response2 = await request(app)
        .put('/api/profile')
        .set('Authorization', `Bearer ${clientToken}`)
        .send({
          role: 'broker',
          creci: '1234567890123456', // more than 15 chars
          creciState: 'SP',
        });
      
      expect(response2.status).toBe(400);
      expect(response2.body.error).toContain('CRECI must be between 4 and 15 characters');
    });

    it('PUT /api/profile should fail to set role to broker with invalid CRECI State format', async () => {
      const response = await request(app)
        .put('/api/profile')
        .set('Authorization', `Bearer ${clientToken}`)
        .send({
          role: 'broker',
          creci: '12345',
          creciState: 'S', // not exactly 2 chars
        });
      
      expect(response.status).toBe(400);
      expect(response.body.error).toContain('CRECI State must be exactly 2 characters');
    });

    it('PUT /api/profile should successfully update profile to broker with valid inputs', async () => {
      const response = await request(app)
        .put('/api/profile')
        .set('Authorization', `Bearer ${clientToken}`)
        .send({
          role: 'broker',
          creci: '98765-F',
          creciState: 'RJ',
        });
      
      expect(response.status).toBe(200);
      expect(response.body.role).toBe('broker');
      expect(response.body.creci).toBe('98765-F');
      expect(response.body.creciState).toBe('RJ');
    });
  });

  describe('Partners Endpoint', () => {
    it('GET /api/partners should return 401 when unauthorized', async () => {
      const response = await request(app).get('/api/partners');
      expect(response.status).toBe(401);
    });

    it('GET /api/partners should return 200 with list of active partners ordered by name', async () => {
      const response = await request(app)
        .get('/api/partners')
        .set('Authorization', `Bearer ${clientToken}`);
      
      expect(response.status).toBe(200);
      expect(Array.isArray(response.body)).toBe(true);
      expect(response.body.length).toBeGreaterThan(0);
      
      // Validar ordenação alfabética
      const names = response.body.map((p: any) => p.name);
      const sortedNames = [...names].sort((a, b) => a.localeCompare(b));
      expect(names).toEqual(sortedNames);

      // Validar que possui photoUrl
      const partner = response.body[0];
      expect(partner).toHaveProperty('photoUrl');
    });
  });

  describe('Indicators Endpoint', () => {
    it('GET /api/indicators should return 401 when unauthorized', async () => {
      const response = await request(app).get('/api/indicators');
      expect(response.status).toBe(401);
    });

    it('GET /api/indicators should return 200 with list of macroeconomic indicators', async () => {
      const response = await request(app)
        .get('/api/indicators')
        .set('Authorization', `Bearer ${clientToken}`);
      
      expect(response.status).toBe(200);
      expect(Array.isArray(response.body)).toBe(true);
      expect(response.body.length).toBeGreaterThan(0);
      
      const names = response.body.map((i: any) => i.name);
      expect(names).toContain('SELIC');
      expect(names).toContain('IPCA');
      expect(names).toContain('TR');
      expect(names).toContain('POUPANCA');
    });
  });

  describe('Simulation Share Endpoint', () => {
    it('POST /api/simulations/:id/share should return 401 when unauthorized', async () => {
      const response = await request(app).post(`/api/simulations/${testSimulation.id}/share`);
      expect(response.status).toBe(401);
    });

    it('POST /api/simulations/:id/share should return 404 for nonexistent simulation', async () => {
      const response = await request(app)
        .post('/api/simulations/00000000-0000-0000-0000-000000000000/share')
        .set('Authorization', `Bearer ${clientToken}`);
      
      expect(response.status).toBe(404);
    });

    it('POST /api/simulations/:id/share should return 403 when user is not owner and not broker', async () => {
      const response = await request(app)
        .post(`/api/simulations/${testSimulation.id}/share`)
        .set('Authorization', `Bearer ${otherClientToken}`);
      
      expect(response.status).toBe(403);
    });

    it('POST /api/simulations/:id/share should return 200 with formatted summary and mock URL for owner', async () => {
      const response = await request(app)
        .post(`/api/simulations/${testSimulation.id}/share`)
        .set('Authorization', `Bearer ${clientToken}`);
      
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('shareUrl');
      expect(response.body.shareUrl).toContain(testSimulation.id);
      expect(response.body).toHaveProperty('summary');
      
      const summary = response.body.summary;
      expect(summary.propertyValue).toBe(300000);
      expect(summary.downPayment).toBe(60000);
      expect(summary.financedAmount).toBe(240000);
      expect(summary.term).toBe(240);
      expect(summary.institution).toBe(testInstitution.name);
      expect(summary.sac).not.toBeNull();
      expect(summary.sac.firstPayment).toBeGreaterThan(0);
    });

    it('POST /api/simulations/:id/share should return 200 with formatted summary and mock URL for broker', async () => {
      const response = await request(app)
        .post(`/api/simulations/${testSimulation.id}/share`)
        .set('Authorization', `Bearer ${brokerToken}`);
      
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('shareUrl');
      expect(response.body.shareUrl).toContain(testSimulation.id);
      expect(response.body).toHaveProperty('summary');
    });
  });
});
