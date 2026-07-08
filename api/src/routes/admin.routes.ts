import { Router, Request, Response } from 'express';
import { prisma } from '../db.ts';

const router = Router();

// ── Financial Institutions CRUD ──────────────────────────────────────────────

// GET /api/admin/institutions
router.get('/institutions', async (req: Request, res: Response): Promise<void> => {
  try {
    const institutions = await prisma.financialInstitution.findMany({
      orderBy: { name: 'asc' },
    });
    res.status(200).json(institutions);
  } catch (error) {
    res.status(500).json({ error: (error as Error).message });
  }
});

// POST /api/admin/institutions
router.post('/institutions', async (req: Request, res: Response): Promise<void> => {
  const { name, logoUrl, isActive, validateLTV, validateTerm, validateAge } = req.body;

  if (!name) {
    res.status(400).json({ error: 'Name is required' });
    return;
  }

  try {
    const institution = await prisma.financialInstitution.create({
      data: {
        name,
        logoUrl,
        isActive: isActive !== undefined ? isActive : true,
        validateLTV: validateLTV !== undefined ? validateLTV : true,
        validateTerm: validateTerm !== undefined ? validateTerm : true,
        validateAge: validateAge !== undefined ? validateAge : true,
      },
    });
    res.status(201).json(institution);
  } catch (error) {
    res.status(500).json({ error: (error as Error).message });
  }
});

// PUT /api/admin/institutions/:id
router.put('/institutions/:id', async (req: Request, res: Response): Promise<void> => {
  const { id } = req.params;
  const { name, logoUrl, isActive, validateLTV, validateTerm, validateAge } = req.body;

  try {
    const existing = await prisma.financialInstitution.findUnique({
      where: { id },
    });

    if (!existing) {
      res.status(404).json({ error: 'Financial institution not found' });
      return;
    }

    const updated = await prisma.financialInstitution.update({
      where: { id },
      data: {
        name: name !== undefined ? name : existing.name,
        logoUrl: logoUrl !== undefined ? logoUrl : existing.logoUrl,
        isActive: isActive !== undefined ? isActive : existing.isActive,
        validateLTV: validateLTV !== undefined ? validateLTV : existing.validateLTV,
        validateTerm: validateTerm !== undefined ? validateTerm : existing.validateTerm,
        validateAge: validateAge !== undefined ? validateAge : existing.validateAge,
      },
    });

    res.status(200).json(updated);
  } catch (error) {
    res.status(500).json({ error: (error as Error).message });
  }
});

// DELETE /api/admin/institutions/:id
router.delete('/institutions/:id', async (req: Request, res: Response): Promise<void> => {
  const { id } = req.params;

  try {
    const existing = await prisma.financialInstitution.findUnique({
      where: { id },
    });

    if (!existing) {
      res.status(404).json({ error: 'Financial institution not found' });
      return;
    }

    await prisma.financialInstitution.delete({
      where: { id },
    });

    res.sendStatus(204);
  } catch (error) {
    res.status(500).json({ error: (error as Error).message });
  }
});

// ── Interest Rates CRUD ──────────────────────────────────────────────────────

// GET /api/admin/interest-rates
router.get('/interest-rates', async (req: Request, res: Response): Promise<void> => {
  try {
    const rates = await prisma.interestRate.findMany({
      include: {
        institution: true,
      },
    });
    res.status(200).json(rates);
  } catch (error) {
    res.status(500).json({ error: (error as Error).message });
  }
});

// POST /api/admin/interest-rates
router.post('/interest-rates', async (req: Request, res: Response): Promise<void> => {
  const {
    institutionId,
    type,
    rateValue,
    maxLTV,
    minTerm,
    maxTerm,
    maxAge,
  } = req.body;

  if (
    !institutionId ||
    !type ||
    rateValue === undefined ||
    maxLTV === undefined ||
    minTerm === undefined ||
    maxTerm === undefined ||
    maxAge === undefined
  ) {
    res.status(400).json({ error: 'All fields (institutionId, type, rateValue, maxLTV, minTerm, maxTerm, maxAge) are required' });
    return;
  }

  if (type !== 'SAC' && type !== 'Price') {
    res.status(400).json({ error: 'Type must be either SAC or Price' });
    return;
  }

  try {
    const institution = await prisma.financialInstitution.findUnique({
      where: { id: institutionId },
    });

    if (!institution) {
      res.status(400).json({ error: 'Financial institution not found' });
      return;
    }

    const rate = await prisma.interestRate.create({
      data: {
        institutionId,
        type,
        rateValue: Number(rateValue),
        maxLTV: Number(maxLTV),
        minTerm: Number(minTerm),
        maxTerm: Number(maxTerm),
        maxAge: Number(maxAge),
      },
    });

    res.status(201).json(rate);
  } catch (error) {
    res.status(500).json({ error: (error as Error).message });
  }
});

// PUT /api/admin/interest-rates/:id
router.put('/interest-rates/:id', async (req: Request, res: Response): Promise<void> => {
  const { id } = req.params;
  const {
    institutionId,
    type,
    rateValue,
    maxLTV,
    minTerm,
    maxTerm,
    maxAge,
  } = req.body;

  try {
    const existing = await prisma.interestRate.findUnique({
      where: { id },
    });

    if (!existing) {
      res.status(404).json({ error: 'Interest rate not found' });
      return;
    }

    if (institutionId) {
      const institution = await prisma.financialInstitution.findUnique({
        where: { id: institutionId },
      });
      if (!institution) {
        res.status(400).json({ error: 'Financial institution not found' });
        return;
      }
    }

    if (type && type !== 'SAC' && type !== 'Price') {
      res.status(400).json({ error: 'Type must be either SAC or Price' });
      return;
    }

    const updated = await prisma.interestRate.update({
      where: { id },
      data: {
        institutionId: institutionId !== undefined ? institutionId : existing.institutionId,
        type: type !== undefined ? type : existing.type,
        rateValue: rateValue !== undefined ? Number(rateValue) : existing.rateValue,
        maxLTV: maxLTV !== undefined ? Number(maxLTV) : existing.maxLTV,
        minTerm: minTerm !== undefined ? Number(minTerm) : existing.minTerm,
        maxTerm: maxTerm !== undefined ? Number(maxTerm) : existing.maxTerm,
        maxAge: maxAge !== undefined ? Number(maxAge) : existing.maxAge,
      },
    });

    res.status(200).json(updated);
  } catch (error) {
    res.status(500).json({ error: (error as Error).message });
  }
});

// DELETE /api/admin/interest-rates/:id
router.delete('/interest-rates/:id', async (req: Request, res: Response): Promise<void> => {
  const { id } = req.params;

  try {
    const existing = await prisma.interestRate.findUnique({
      where: { id },
    });

    if (!existing) {
      res.status(404).json({ error: 'Interest rate not found' });
      return;
    }

    await prisma.interestRate.delete({
      where: { id },
    });

    res.sendStatus(204);
  } catch (error) {
    res.status(500).json({ error: (error as Error).message });
  }
});

// ── Macroeconomic Indicators CRUD ───────────────────────────────────────────

// GET /api/admin/indicators
router.get('/indicators', async (req: Request, res: Response): Promise<void> => {
  try {
    const indicators = await prisma.macroeconomicIndicator.findMany({
      orderBy: { name: 'asc' },
    });
    res.status(200).json(indicators);
  } catch (error) {
    res.status(500).json({ error: (error as Error).message });
  }
});

// PUT /api/admin/indicators/:id
router.put('/indicators/:id', async (req: Request, res: Response): Promise<void> => {
  const { id } = req.params;
  const { value } = req.body;

  if (value === undefined) {
    res.status(400).json({ error: 'Value is required' });
    return;
  }

  try {
    const existing = await prisma.macroeconomicIndicator.findUnique({
      where: { id },
    });

    if (!existing) {
      res.status(404).json({ error: 'Macroeconomic indicator not found' });
      return;
    }

    const updated = await prisma.macroeconomicIndicator.update({
      where: { id },
      data: {
        value: Number(value),
      },
    });

    res.status(200).json(updated);
  } catch (error) {
    res.status(500).json({ error: (error as Error).message });
  }
});

export default router;
