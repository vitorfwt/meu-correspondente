import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import request from 'supertest';
import app from './app.ts';
import { prisma } from './db.ts';
import { generateToken } from './utils/jwt.ts';

describe('Auth Integration Tests', () => {
  const testEmailsToClean: string[] = [];

  beforeAll(async () => {
    await prisma.$connect();
  });

  afterAll(async () => {
    // Limpar todos os usuários de teste criados no banco
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

  describe('POST /api/auth/social-login', () => {
    it('should create a new user with role "client" and return a JWT when user does not exist', async () => {
      const email = `new-social-user-${Date.now()}@example.com`;
      const name = 'New Social User';
      const idToken = JSON.stringify({ email, name });
      testEmailsToClean.push(email);

      const response = await request(app)
        .post('/api/auth/social-login')
        .send({
          provider: 'google',
          idToken,
        });

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('token');
      expect(response.body).toHaveProperty('user');
      expect(response.body.user.email).toBe(email);
      expect(response.body.user.name).toBe(name);
      expect(response.body.user.role).toBe('client');

      // Verificar se o usuário realmente foi criado no banco
      const userInDb = await prisma.user.findUnique({
        where: { email },
      });
      expect(userInDb).not.toBeNull();
      expect(userInDb?.role).toBe('client');
    });

    it('should return a JWT and re-use the existing user details when user already exists', async () => {
      const email = `existing-social-user-${Date.now()}@example.com`;
      const name = 'Existing Social User';
      testEmailsToClean.push(email);

      // Criar o usuário previamente com a role 'broker'
      const existingUser = await prisma.user.create({
        data: {
          email,
          name,
          role: 'broker',
        },
      });

      const idToken = JSON.stringify({ email, name });

      const response = await request(app)
        .post('/api/auth/social-login')
        .send({
          provider: 'google',
          idToken,
        });

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('token');
      expect(response.body.user.id).toBe(existingUser.id);
      expect(response.body.user.email).toBe(email);
      expect(response.body.user.role).toBe('broker'); // Deve manter a role existente
    });

    it('should return 400 Bad Request when provider or idToken is missing', async () => {
      const response1 = await request(app)
        .post('/api/auth/social-login')
        .send({
          provider: 'google',
        });
      expect(response1.status).toBe(400);
      expect(response1.body.error).toBe('Provider and idToken are required');

      const response2 = await request(app)
        .post('/api/auth/social-login')
        .send({
          idToken: 'mock-token',
        });
      expect(response2.status).toBe(400);
      expect(response2.body.error).toBe('Provider and idToken are required');
    });

    it('should return 401 Unauthorized for unsupported providers or invalid token formats', async () => {
      const response = await request(app)
        .post('/api/auth/social-login')
        .send({
          provider: 'invalid-provider',
          idToken: 'mock-token',
        });

      expect(response.status).toBe(401);
      expect(response.body).toHaveProperty('error');
    });
  });

  describe('GET /api/protected-route (Auth Middleware)', () => {
    it('should return 401 Unauthorized if Authorization header is missing', async () => {
      const response = await request(app)
        .get('/api/protected-route');

      expect(response.status).toBe(401);
      expect(response.body.error).toBe('Authorization header is missing');
    });

    it('should return 401 Unauthorized if Authorization format is invalid (not Bearer)', async () => {
      const response = await request(app)
        .get('/api/protected-route')
        .set('Authorization', 'Basic c29tZXRva2Vu');

      expect(response.status).toBe(401);
      expect(response.body.error).toBe('Invalid authorization format');
    });

    it('should return 401 Unauthorized if JWT token is invalid', async () => {
      const response = await request(app)
        .get('/api/protected-route')
        .set('Authorization', 'Bearer invalid-token-string');

      expect(response.status).toBe(401);
      expect(response.body.error).toBe('Invalid or expired token');
    });

    it('should return 200 OK and decoded user data if JWT is valid', async () => {
      const payload = {
        id: 'some-user-id',
        email: 'middleware-test@example.com',
        role: 'client',
      };
      const token = generateToken(payload);

      const response = await request(app)
        .get('/api/protected-route')
        .set('Authorization', `Bearer ${token}`);

      expect(response.status).toBe(200);
      expect(response.body.message).toBe('Access granted to protected route');
      expect(response.body.user).toBeDefined();
      expect(response.body.user.id).toBe(payload.id);
      expect(response.body.user.email).toBe(payload.email);
      expect(response.body.user.role).toBe(payload.role);
    });
  });
});
