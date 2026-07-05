import express from 'express';
import type { Request, Response, NextFunction } from 'express';
import authRouter from './routes/auth.routes.ts';
import simulationRouter from './routes/simulation.routes.ts';
import { authMiddleware, AuthenticatedRequest } from './middlewares/auth.middleware.ts';

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

// Registro das rotas públicas de autenticação
app.use('/api/auth', authRouter);

// Registro das rotas de simulação
app.use('/api/simulate', simulationRouter);

// Rota protegida de teste para validar o middleware
app.get('/api/protected-route', authMiddleware, (req: AuthenticatedRequest, res: Response) => {
  res.status(200).json({
    message: 'Access granted to protected route',
    user: req.user,
  });
});

export default app;
