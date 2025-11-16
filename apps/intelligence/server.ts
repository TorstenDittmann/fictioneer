import { Hono } from 'hono';
import { cors } from 'hono/cors';
import marketing_api from './marketing_api';
import production_api from './production_api';

const app = new Hono()
	.use(
		'*',
		cors({
			origin: '*',
			allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
			allowHeaders: ['Content-Type', 'Authorization', 'Cache-Control', 'X-Requested-With'],
			exposeHeaders: ['Content-Type', 'Cache-Control'],
			maxAge: 86400
		})
	)
	.get('/health', (c) => {
		return c.json({
			status: 'ok',
			timestamp: new Date().toISOString()
		});
	})
	.route('/', marketing_api)
	.route('/', production_api);

// Start the server
const port = Bun.env.PORT ? parseInt(Bun.env.PORT, 10) : 3001;

export type AppType = typeof app;
export default {
	port: port,
	idleTimeout: 30,
	fetch: app.fetch
} satisfies Bun.Serve.Options<never>;
