import { Router, Response } from 'express';
import { prisma } from '../db.ts';
import { authMiddleware, AuthenticatedRequest } from '../middlewares/auth.middleware.ts';
import { runSimulations } from '../utils/simulation.ts';

const router = Router();

// POST /api/simulations/:id/share
router.post('/:id/share', authMiddleware, async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const simulationId = req.params.id;
    const userId = req.user?.id;
    const userRole = req.user?.role;

    if (!userId) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    // 1. Buscar a simulação no banco
    const simulation = await prisma.simulationHistory.findUnique({
      where: { id: simulationId },
      include: { institution: true },
    });

    if (!simulation) {
      res.status(404).json({ error: 'Simulation not found' });
      return;
    }

    // 2. Validar se o usuário é o dono da simulação ou é corretor (broker)
    const isOwner = simulation.userId === userId;
    const isBroker = userRole === 'broker';

    if (!isOwner && !isBroker) {
      res.status(403).json({ error: 'Forbidden: You do not have permission to share this simulation' });
      return;
    }

    // 3. Buscar taxas da instituição para recalcular o resumo das parcelas SAC e Price
    const interestRates = await prisma.interestRate.findMany({
      where: {
        institutionId: simulation.selectedInstitutionId,
      },
      include: {
        institution: true,
      },
    });

    // 4. Executar cálculo de simulação
    const simulationResults = runSimulations(
      {
        propertyValue: simulation.propertyValue,
        downPayment: simulation.downPayment,
        monthlyIncome: simulation.monthlyIncome,
        age: simulation.age,
        term: simulation.term,
      },
      interestRates
    );

    const resultDetails = simulationResults.find(r => r.institutionId === simulation.selectedInstitutionId);

    // 5. Formatar o resumo da simulação
    const summary = {
      propertyValue: simulation.propertyValue,
      downPayment: simulation.downPayment,
      financedAmount: simulation.propertyValue - simulation.downPayment,
      term: simulation.term,
      institution: simulation.institution.name,
      sac: resultDetails?.sac ? {
        firstPayment: resultDetails.sac.firstPayment,
        lastPayment: resultDetails.sac.lastPayment,
        totalCost: resultDetails.sac.totalCost,
        rateValue: resultDetails.sac.rateValue,
        warnings: resultDetails.sac.warnings,
      } : null,
      price: resultDetails?.price ? {
        firstPayment: resultDetails.price.firstPayment,
        lastPayment: resultDetails.price.lastPayment,
        totalCost: resultDetails.price.totalCost,
        rateValue: resultDetails.price.rateValue,
        warnings: resultDetails.price.warnings,
      } : null,
    };

    // 6. Gerar a URL pública única mockada
    const shareUrl = `https://meu-correspondente.com.br/shared-simulations/${simulation.id}`;

    res.status(200).json({
      summary,
      shareUrl,
    });
  } catch (error) {
    console.error('Error sharing simulation:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
