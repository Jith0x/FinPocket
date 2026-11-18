import { Router, Response } from 'express';
import { AuthRequest, authMiddleware } from '../middleware/auth.middleware.js';
import { AccountsService } from '../services/accounts.service.js';
import { config } from '../config/app_config.js';

const router = Router();

router.get('/', authMiddleware, async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const accounts = await AccountsService.listAccounts(req.user!.id);
    res.json({ accounts });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/:id/sync', authMiddleware, async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const updatedBalance = await AccountsService.syncAccount(req.user!.id, req.params.id);
    res.json({ success: true, updatedBalance, message: 'Account synchronized via Financial Data Provider.' });
  } catch (err: any) {
    // An unknown account is a data-level 404, not a server fault.
    const notFound = typeof err?.message === 'string' && /not found/i.test(err.message);
    res.status(notFound ? 404 : 500).json({ error: err.message });
  }
});

router.post('/instant-link', authMiddleware, async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { institutionName, institutionCode, maskedAccountNumber, initialBalance, accountType } = req.body;

    if (typeof initialBalance !== 'number' || isNaN(initialBalance) || initialBalance < 0) {
      res.status(400).json({ error: 'Please enter a valid account balance (₹0 or greater).' });
      return;
    }

    if (!maskedAccountNumber || typeof maskedAccountNumber !== 'string') {
      res.status(400).json({ error: 'Please enter the 4 digits of your account number.' });
      return;
    }

    const cleanDigits = maskedAccountNumber.replace(/[^\d]/g, '');
    if (cleanDigits.length !== 4) {
      res.status(400).json({ error: 'Account number must contain exactly 4 digits.' });
      return;
    }

    const account = await AccountsService.createSelfDeclaredAccount(req.user!.id, {
      institutionName: institutionName || 'Primary Bank Account',
      institutionCode: institutionCode || 'INSTANT',
      maskedAccountNumber: `•••• ${cleanDigits}`,
      accountType: accountType || 'SAVINGS',
      initialBalance: Number(initialBalance),
    });
    res.status(201).json({ success: true, account });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/connect-mock', authMiddleware, async (req: AuthRequest, res: Response): Promise<void> => {
  res.status(403).json({ error: 'Mock bank account connections are permanently disabled. Only real, verified accounts may be connected.' });
});

router.post('/:id/disconnect', authMiddleware, async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    await AccountsService.disconnectAccount(req.user!.id, req.params.id);
    res.json({ success: true, message: 'Bank account disconnected and consent revoked.' });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

export default router;
