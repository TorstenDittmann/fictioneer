import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { logger } from 'hono/logger';
import { PostHog } from 'posthog-node';
import marketing_api from './marketing_api';
import production_api from './production_api';

const client = new PostHog('phc_Rnfc8HPFJ1Duqo23ykhIYTivNNB8Mn5v6NqbVUxLJkS', {
	host: 'https://eu.i.posthog.com',
	flushInterval: 10000
});

const app = new Hono()
	.use(logger())
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

process.on('exit', async (code) => {
	await client.shutdown();
	console.log(`Process exited with code ${code}`);
});

const port = Bun.env.PORT ? parseInt(Bun.env.PORT, 10) : 3001;

export type AppType = typeof app;
export default {
	port: port,
	idleTimeout: 30,
	fetch: app.fetch,
	error(error) {
		client.captureException(error);
		return Response.json({ error: error.message }, { status: 500 });
	}
} satisfies Bun.Serve.Options<never>;
