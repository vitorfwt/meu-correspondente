import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import request from 'supertest';
import app from './app.ts';
import { prisma } from './db.ts';
import { generateToken } from './utils/jwt.ts';
import bcrypt from 'bcryptjs';

describe('Admin Endpoints and Middleware Integration Tests', () => {
  let adminUser: any;
  let adminToken: string;
  let clientUser: any;
  let clientToken: string;
  let createdInstitutionId: string;
  let createdInterestRateId: string;

  const emailsToClean: string[] = [];
  const instIdsToClean: string[] = [];

  beforeAll(async () => {
    await prisma.$connect();

    // Criar um admin com passwordHash para testar o login
    const adminEmail = `admin-${Date.now()}@example.com`;
    const passwordHash = await bcrypt.hash('secretAdminPassword', 10);
    adminUser = await prisma.user.create({
      data: {
        name: 'Test Admin',
        email: adminEmail,
        role: 'admin',
        passwordHash,
      },
    });
    adminToken = generateToken({ id: adminUser.id, email: adminUser.email, role: adminUser.role });
    emailsToClean.push(adminEmail);

    // Criar um usuário client normal
    const clientEmail = `client-${Date.now()}@example.com`;
    clientUser = await prisma.user.create({
      data: {
        name: 'Test Client',
        email: clientEmail,
        role: 'client',
      },
    });
    clientToken = generateToken({ id: clientUser.id, email: clientUser.email, role: clientUser.role });
    emailsToClean.push(clientEmail);
  });

  afterAll(async () => {
    // Excluir taxas de juros criadas
    if (createdInterestRateId) {
      await prisma.interestRate.deleteMany({
        where: { id: createdInterestRateId },
      });
    }

    // Excluir instituições criadas
    await prisma.interestRate.deleteMany({
      where: { institutionId: { in: instIdsToClean } },
    });
    await prisma.financialInstitution.deleteMany({
      where: { id: { in: instIdsToClean } },
    });

    // Excluir usuários de teste
    await prisma.user.deleteMany({
      where: { email: { in: emailsToClean } },
    });

    await prisma.$disconnect();
  });

  describe('POST /api/auth/admin-login', () => {
    it('should login successfully with valid admin credentials', async () => {
      const response = await request(app)
        .post('/api/auth/admin-login')
        .send({
          email: adminUser.email,
          password: 'secretAdminPassword',
        });

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('token');
      expect(response.body.user).toHaveProperty('role', 'admin');
      expect(response.body.user.email).toBe(adminUser.email);
    });

    it('should fail with invalid password', async () => {
      const response = await request(app)
        .post('/api/auth/admin-login')
        .send({
          email: adminUser.email,
          password: 'wrongPassword',
        });

      expect(response.status).toBe(401);
      expect(response.body.error).toContain('Invalid credentials');
    });

    it('should fail when user is not an admin', async () => {
      const response = await request(app)
        .post('/api/auth/admin-login')
        .send({
          email: clientUser.email,
          password: 'somePassword',
        });

      expect(response.status).toBe(401);
      expect(response.body.error).toContain('Invalid credentials');
    });
  });

  describe('Route Security (authMiddleware & adminMiddleware)', () => {
    it('should return 401 when accessing admin routes without token', async () => {
      const response = await request(app).get('/api/admin/institutions');
      expect(response.status).toBe(401);
    });

    it('should return 403 when accessing admin routes as a non-admin client', async () => {
      const response = await request(app)
        .get('/api/admin/institutions')
        .set('Authorization', `Bearer ${clientToken}`);
      expect(response.status).toBe(403);
      expect(response.body.error).toContain('Acesso negado');
    });

    it('should allow access when user is admin', async () => {
      const response = await request(app)
        .get('/api/admin/institutions')
        .set('Authorization', `Bearer ${adminToken}`);
      expect(response.status).toBe(200);
    });
  });

  describe('Financial Institution CRUD', () => {
    it('should create a new financial institution', async () => {
      const response = await request(app)
        .post('/api/admin/institutions')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          name: 'Banco Antigravity',
          logoUrl: '/public/logos/antigravity.png',
          isActive: true,
        });

      expect(response.status).toBe(201);
      expect(response.body).toHaveProperty('id');
      expect(response.body.name).toBe('Banco Antigravity');
      expect(response.body.isActive).toBe(true);

      createdInstitutionId = response.body.id;
      instIdsToClean.push(createdInstitutionId);
    });

    it('should return 400 when name is missing', async () => {
      const response = await request(app)
        .post('/api/admin/institutions')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          logoUrl: '/public/logos/missing.png',
        });

      expect(response.status).toBe(400);
      expect(response.body.error).toContain('Name is required');
    });

    it('should list all financial institutions', async () => {
      const response = await request(app)
        .get('/api/admin/institutions')
        .set('Authorization', `Bearer ${adminToken}`);

      expect(response.status).toBe(200);
      expect(Array.isArray(response.body)).toBe(true);
      const names = response.body.map((i: any) => i.name);
      expect(names).toContain('Banco Antigravity');
    });

    it('should update a financial institution', async () => {
      const response = await request(app)
        .put(`/api/admin/institutions/${createdInstitutionId}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          name: 'Banco Antigravity Atualizado',
          isActive: false,
        });

      expect(response.status).toBe(200);
      expect(response.body.name).toBe('Banco Antigravity Atualizado');
      expect(response.body.isActive).toBe(false);
    });

    it('should return 404 when updating non-existent institution', async () => {
      const response = await request(app)
        .put('/api/admin/institutions/00000000-0000-0000-0000-000000000000')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          name: 'Banco Inexistente',
        });

      expect(response.status).toBe(404);
    });
  });

  describe('Interest Rate CRUD', () => {
    it('should create an interest rate rule', async () => {
      const response = await request(app)
        .post('/api/admin/interest-rates')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          institutionId: createdInstitutionId,
          type: 'SAC',
          rateValue: 0.085,
          maxLTV: 0.80,
          minTerm: 120,
          maxTerm: 420,
          maxAge: 80,
        });

      expect(response.status).toBe(201);
      expect(response.body).toHaveProperty('id');
      expect(response.body.institutionId).toBe(createdInstitutionId);
      expect(response.body.type).toBe('SAC');
      expect(response.body.rateValue).toBe(0.085);

      createdInterestRateId = response.body.id;
    });

    it('should return 400 when fields are missing', async () => {
      const response = await request(app)
        .post('/api/admin/interest-rates')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          institutionId: createdInstitutionId,
          type: 'SAC',
        });

      expect(response.status).toBe(400);
      expect(response.body.error).toContain('All fields');
    });

    it('should return 400 when interest rate type is invalid', async () => {
      const response = await request(app)
        .post('/api/admin/interest-rates')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          institutionId: createdInstitutionId,
          type: 'INVALID',
          rateValue: 0.085,
          maxLTV: 0.80,
          minTerm: 120,
          maxTerm: 420,
          maxAge: 80,
        });

      expect(response.status).toBe(400);
      expect(response.body.error).toContain('Type must be either SAC or Price');
    });

    it('should list all interest rates with institutions included', async () => {
      const response = await request(app)
        .get('/api/admin/interest-rates')
        .set('Authorization', `Bearer ${adminToken}`);

      expect(response.status).toBe(200);
      expect(Array.isArray(response.body)).toBe(true);
      const rates = response.body;
      const testRate = rates.find((r: any) => r.id === createdInterestRateId);
      expect(testRate).toBeDefined();
      expect(testRate.institution).toBeDefined();
      expect(testRate.institution.name).toBe('Banco Antigravity Atualizado');
    });

    it('should update an interest rate rule', async () => {
      const response = await request(app)
        .put(`/api/admin/interest-rates/${createdInterestRateId}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          rateValue: 0.092,
          type: 'Price',
        });

      expect(response.status).toBe(200);
      expect(response.body.rateValue).toBe(0.092);
      expect(response.body.type).toBe('Price');
    });

    it('should delete the interest rate rule', async () => {
      const deleteResponse = await request(app)
        .delete(`/api/admin/interest-rates/${createdInterestRateId}`)
        .set('Authorization', `Bearer ${adminToken}`);

      expect(deleteResponse.status).toBe(204);

      // Verificar se foi realmente deletado
      const getResponse = await request(app)
        .get('/api/admin/interest-rates')
        .set('Authorization', `Bearer ${adminToken}`);
      
      const rates = getResponse.body;
      const testRate = rates.find((r: any) => r.id === createdInterestRateId);
      expect(testRate).toBeUndefined();

      // Resetar id para não tentar apagar novamente no afterAll
      createdInterestRateId = '';
    });
  });

  describe('Cascade delete tests', () => {
    it('should cascade delete interest rates when the institution is deleted', async () => {
      // 1. Criar instituição
      const instResponse = await request(app)
        .post('/api/admin/institutions')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          name: 'Banco Cascata',
        });
      const instId = instResponse.body.id;
      instIdsToClean.push(instId);

      // 2. Criar taxa de juros associada
      const rateResponse = await request(app)
        .post('/api/admin/interest-rates')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          institutionId: instId,
          type: 'SAC',
          rateValue: 0.11,
          maxLTV: 0.80,
          minTerm: 120,
          maxTerm: 360,
          maxAge: 80,
        });
      const rateId = rateResponse.body.id;

      // 3. Deletar instituição
      const deleteInstResponse = await request(app)
        .delete(`/api/admin/institutions/${instId}`)
        .set('Authorization', `Bearer ${adminToken}`);
      expect(deleteInstResponse.status).toBe(204);

      // 4. Verificar se a taxa de juros foi removida automaticamente do banco
      const checkRate = await prisma.interestRate.findUnique({
        where: { id: rateId },
      });
      expect(checkRate).toBeNull();
    });
  });
});
