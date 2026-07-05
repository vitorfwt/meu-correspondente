import { Router, Request, Response } from 'express';
import { prisma } from '../db.ts';
import { generateToken } from '../utils/jwt.ts';
import { OAuth2Client } from 'google-auth-library';

const router = Router();
const googleClient = new OAuth2Client();

// Função para validar o token social (com suporte a mock para testes/dev)
async function verifySocialToken(provider: string, idToken: string): Promise<{ email: string; name: string }> {
  if (provider !== 'google' && provider !== 'apple') {
    throw new Error(`Unsupported social provider: ${provider}`);
  }

  if (process.env.NODE_ENV === 'test' || idToken.startsWith('mock-')) {
    // Modo de teste / mock
    if (idToken.startsWith('{')) {
      try {
        const parsed = JSON.parse(idToken);
        if (!parsed.email) {
          throw new Error('Email is required in mock token JSON');
        }
        return {
          email: parsed.email,
          name: parsed.name || 'Social User',
        };
      } catch (e) {
        throw new Error('Invalid mock JSON token format');
      }
    }
    
    // Fallback simples para tokens mock como 'mock-user-123'
    return {
      email: `${idToken}@example.com`,
      name: idToken.split('-').map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(' '),
    };
  }

  if (provider === 'google') {
    try {
      const ticket = await googleClient.verifyIdToken({
        idToken: idToken,
        audience: process.env.GOOGLE_CLIENT_ID,
      });
      const payload = ticket.getPayload();
      if (!payload || !payload.email) {
        throw new Error('Invalid token payload or missing email');
      }
      return {
        email: payload.email,
        name: payload.name || 'Google User',
      };
    } catch (error) {
      throw new Error(`Google token verification failed: ${(error as Error).message}`);
    }
  } else if (provider === 'apple') {
    // Apple verification mock/stub for now since it usually requires complex client secrets/certificates
    // or if we have a mock token we use it.
    throw new Error('Apple Sign-In real validation not implemented. Use mock tokens in development.');
  }

  throw new Error(`Unsupported social provider: ${provider}`);
}

// POST /api/auth/social-login
router.post('/social-login', async (req: Request, res: Response): Promise<void> => {
  const { provider, idToken } = req.body;

  if (!provider || !idToken) {
    res.status(400).json({ error: 'Provider and idToken are required' });
    return;
  }

  try {
    const { email, name } = await verifySocialToken(provider, idToken);

    // Buscar ou criar o usuário no banco
    let user = await prisma.user.findUnique({
      where: { email },
    });

    if (!user) {
      user = await prisma.user.create({
        data: {
          email,
          name,
          role: 'client', // Papel inicial conforme especificado no plano de execução
        },
      });
    }

    // Assinar o token JWT
    const token = generateToken({
      id: user.id,
      email: user.email,
      role: user.role,
    });

    res.status(200).json({
      token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
      },
    });
  } catch (error) {
    res.status(401).json({ error: (error as Error).message });
  }
});

export default router;
