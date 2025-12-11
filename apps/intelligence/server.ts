import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { logger } from 'hono/logger';
import { CORS_CONFIG } from './constants';
import marketing_api from './marketing_api';
import production_api from './production_api';
import { posthog } from './tracking';

const app = new Hono()
	.use(logger())
	.use('*', cors(CORS_CONFIG))
	.get('/health', (c) => {
		return c.json({
			status: 'ok',
			timestamp: new Date().toISOString()
		});
	})
	.route('/', marketing_api)
	.route('/', production_api);

process.on('exit', async (code) => {
	await posthog.shutdown();
	console.log(`Process exited with code ${code}`);
});

const port = Bun.env.PORT ? parseInt(Bun.env.PORT, 10) : 3001;

export type AppType = typeof app;
export default {
	port: port,
	idleTimeout: 30,
	fetch: app.fetch,
	error(error) {
		posthog.captureException(error);
		return Response.json({ error: error.message }, { status: 500 });
	}
} satisfies Bun.Serve.Options<never>;
