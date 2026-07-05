import { Router, Response } from 'express';
import { prisma } from '../db.ts';
import { authMiddleware, AuthenticatedRequest } from '../middlewares/auth.middleware.ts';

const router = Router();

// GET /api/indicators
router.get('/', authMiddleware, async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const indicators = await prisma.macroeconomicIndicator.findMany();
    res.status(200).json(indicators);
  } catch (error) {
    console.error('Error fetching macroeconomic indicators:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
