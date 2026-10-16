import { Router, Request, Response } from 'express';
import { getQuery } from '../config/database.js';
import { config } from '../config/app_config.js';

const router = Router();

/**
 * 1. GET /health/live (Kubernetes / container liveness check)
 */
router.get('/live', (_req: Request, res: Response) => {
  res.json({
    status: 'UP',
    timestamp: new Date().toISOString(),
    uptimeSeconds: Math.floor(process.uptime()),
    environment: config.environment,
  });
});

/**
 * 2. GET /health/ready (Readiness probe verifying DB & config)
 */
router.get('/ready', async (_req: Request, res: Response) => {
  try {
    const dbTest = await getQuery<{ val: number }>('SELECT 1 as val');
    const isDbConnected = dbTest?.val === 1;

    if (!isDbConnected) {
      res.status(503).json({
        status: 'UNHEALTHY',
        database: 'DISCONNECTED',
        timestamp: new Date().toISOString()
      });
      return;
    }

    res.json({
      status: 'READY',
      database: 'CONNECTED',
      environment: config.environment,
      isDemoMode: config.isDemoMode,
      // Account Aggregator availability — lets the mobile app choose between
      // the real AA consent flow and the on-device SMS importer instead of guessing.
      aaEnabled: config.aaProvider.enabled === true &&
          !['MOCK', 'FAKE_TEST_PROVIDER'].includes(config.aaProvider.providerName),
      aaProvider: config.aaProvider.providerName,
      timestamp: new Date().toISOString()
    });
  } catch (err: any) {
    res.status(503).json({
      status: 'UNHEALTHY',
      error: config.environment === 'PRODUCTION' ? 'Dependency check failed' : err.message,
      timestamp: new Date().toISOString()
    });
  }
});

export default router;
