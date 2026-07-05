import { Router, Response } from 'express';
import { prisma } from '../db.ts';
import { authMiddleware, AuthenticatedRequest } from '../middlewares/auth.middleware.ts';

const router = Router();

// GET /api/profile
router.get('/', authMiddleware, async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user?.id;

    if (!userId) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        name: true,
        email: true,
        role: true,
        creci: true,
        creciState: true,
        createdAt: true,
      },
    });

    if (!user) {
      res.status(404).json({ error: 'User not found' });
      return;
    }

    res.status(200).json(user);
  } catch (error) {
    console.error('Error fetching profile:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// PUT /api/profile
router.put('/', authMiddleware, async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user?.id;

    if (!userId) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    const { name, email, role, creci, creciState } = req.body;

    // Buscar usuário atual para comparar mudanças de role
    const currentUser = await prisma.user.findUnique({
      where: { id: userId },
    });

    if (!currentUser) {
      res.status(404).json({ error: 'User not found' });
      return;
    }

    // Verificar se o role está sendo alterado para broker ou se o novo role é broker
    const newRole = role !== undefined ? role : currentUser.role;

    if (newRole === 'broker') {
      // creci e creciState são obrigatórios
      if (!creci || !creciState) {
        res.status(400).json({ error: 'CRECI and CRECI State are required for broker role' });
        return;
      }

      if (typeof creci !== 'string' || creci.length < 4 || creci.length > 15) {
        res.status(400).json({ error: 'CRECI must be between 4 and 15 characters' });
        return;
      }

      if (typeof creciState !== 'string' || creciState.length !== 2) {
        res.status(400).json({ error: 'CRECI State must be exactly 2 characters' });
        return;
      }
    }

    // Preparar dados para atualização
    const updateData: any = {};
    if (name !== undefined) updateData.name = name;
    if (email !== undefined) updateData.email = email;
    if (role !== undefined) updateData.role = role;
    if (creci !== undefined) updateData.creci = creci;
    if (creciState !== undefined) updateData.creciState = creciState;

    const updatedUser = await prisma.user.update({
      where: { id: userId },
      data: updateData,
      select: {
        id: true,
        name: true,
        email: true,
        role: true,
        creci: true,
        creciState: true,
        createdAt: true,
      },
    });

    res.status(200).json(updatedUser);
  } catch (error) {
    console.error('Error updating profile:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
