import { Router, Response } from 'express';
import { Request } from 'express';
import { prisma } from '../db.ts';
import { runSimulations } from '../utils/simulation.ts';
import { verifyToken } from '../utils/jwt.ts';

interface AuthenticatedRequest extends Request {
  user?: {
    id: string;
    email: string;
    role: string;
  };
}

const router = Router();

// Endpoint POST /api/simulate
router.post('/', async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  const { propertyValue, downPayment, monthlyIncome, age, term } = req.body;

  // 1. Validação de campos obrigatórios
  if (
    propertyValue === undefined ||
    downPayment === undefined ||
    monthlyIncome === undefined ||
    age === undefined ||
    term === undefined
  ) {
    res.status(400).json({ error: 'All fields (propertyValue, downPayment, monthlyIncome, age, term) are required' });
    return;
  }

  // 2. Validação de tipos e lógica simples
  if (
    typeof propertyValue !== 'number' ||
    typeof downPayment !== 'number' ||
    typeof monthlyIncome !== 'number' ||
    typeof age !== 'number' ||
    typeof term !== 'number'
  ) {
    res.status(400).json({ error: 'All fields must be numbers' });
    return;
  }

  if (propertyValue <= 0 || downPayment < 0 || monthlyIncome <= 0 || age <= 0 || term <= 0) {
    res.status(400).json({ error: 'Numeric fields must be positive values' });
    return;
  }

  if (downPayment >= propertyValue) {
    res.status(400).json({ error: 'Down payment cannot be equal to or greater than property value' });
    return;
  }

  try {
    // 3. Buscar taxas de juros ativas no banco de dados
    const interestRates = await prisma.interestRate.findMany({
      where: {
        institution: {
          isActive: true,
        },
      },
      include: {
        institution: true,
      },
    });

    if (interestRates.length === 0) {
      res.status(404).json({ error: 'No active financial institutions or interest rates found' });
      return;
    }

    // 4. Calcular a simulação nas modalidades SAC e Price
    const simulationResults = runSimulations(
      { propertyValue, downPayment, monthlyIncome, age, term },
      interestRates
    );

    // 5. Determinar o ID do usuário (autenticação opcional)
    let userId: string | undefined = undefined;

    // Verificar se existe token na requisição (Authorization Bearer Header)
    const authHeader = req.headers.authorization;
    if (authHeader) {
      const [type, token] = authHeader.split(' ');
      if (type === 'Bearer' && token) {
        try {
          const decoded = verifyToken(token);
          userId = decoded.id;
        } catch (err) {
          // Se enviou um token mas é inválido, falhamos a requisição
          res.status(401).json({ error: 'Invalid or expired authorization token' });
          return;
        }
      }
    }

    // Opcionalmente aceita userId no payload (se fornecido)
    if (!userId && req.body.userId) {
      userId = String(req.body.userId);
    }

    // 6. Gravar histórico no banco se houver userId e ele existir
    if (userId) {
      const userExists = await prisma.user.findUnique({
        where: { id: userId },
      });

      if (userExists) {
        // Criar histórico para cada instituição que retornou resultados simulados
        for (const result of simulationResults) {
          // Determina a parcela mensal para guardar no banco (preferência PRICE, se não SAC, se não 0)
          const resultPayment = result.price
            ? result.price.firstPayment
            : result.sac
            ? result.sac.firstPayment
            : 0;

          await prisma.simulationHistory.create({
            data: {
              userId: userExists.id,
              propertyValue,
              downPayment,
              monthlyIncome,
              age,
              term,
              selectedInstitutionId: result.institutionId,
              resultMonthlyPayment: resultPayment,
              status: 'completed',
            },
          });
        }
      }
    }

    // 7. Retornar os resultados simulados estruturados
    res.status(200).json(simulationResults);
  } catch (error) {
    console.error('Error calculating simulation:', error);
    res.status(500).json({ error: 'Internal server error while simulating' });
  }
});

export default router;
