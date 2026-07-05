import express from 'express';
import type { Request, Response, NextFunction } from 'express';
import authRouter from './routes/auth.routes.ts';
import simulationRouter from './routes/simulation.routes.ts';
import profileRouter from './routes/profile.routes.ts';
import partnerRouter from './routes/partner.routes.ts';
import indicatorRouter from './routes/indicator.routes.ts';
import simulationsRouter from './routes/simulations.routes.ts';
import { authMiddleware, AuthenticatedRequest } from './middlewares/auth.middleware.ts';
import { prisma } from './db.ts';

const app = express();

app.use(express.json());

// ── CORS ─────────────────────────────────────────────────────────────────────
// Permite requisições de qualquer origem local (Flutter Web, emulador, desktop)
app.use((req: Request, res: Response, next: NextFunction) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  if (req.method === 'OPTIONS') {
    res.sendStatus(204);
    return;
  }
  next();
});

// Servir arquivos estáticos da pasta public (como logos dos bancos)
app.use('/public', express.static('public'));

// Registro das rotas públicas de autenticação
app.use('/api/auth', authRouter);

// Registro das rotas de simulação
app.use('/api/simulate', simulationRouter);

// Registro das novas rotas protegidas
app.use('/api/profile', profileRouter);
app.use('/api/partners', partnerRouter);
app.use('/api/indicators', indicatorRouter);
app.use('/api/simulations', simulationsRouter);

// Rota protegida de teste para validar o middleware
app.get('/api/protected-route', authMiddleware, (req: AuthenticatedRequest, res: Response) => {
  res.status(200).json({
    message: 'Access granted to protected route',
    user: req.user,
  });
});

export default app;
