import express from 'express';
import authRouter from './routes/auth.routes.ts';
import simulationRouter from './routes/simulation.routes.ts';
import { authMiddleware, AuthenticatedRequest } from './middlewares/auth.middleware.ts';
import { Response } from 'express';

const app = express();

app.use(express.json());

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
