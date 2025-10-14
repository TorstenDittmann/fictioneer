import { Hono } from 'hono';
import { cors } from 'hono/cors';
import marketing_api from './marketing_api';
import production_api from './production_api';

const app = new Hono();

// Global CORS middleware
app.use(
	'*',
	cors({
		origin: '*',
		allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
		allowHeaders: ['Content-Type', 'Authorization', 'Cache-Control', 'X-Requested-With'],
		exposeHeaders: ['Content-Type', 'Cache-Control'],
		maxAge: 86400
	})
);

// Health check endpoint
app.get('/health', (c) => {
	return c.json({
		status: 'ok',
		timestamp: new Date().toISOString()
	});
});

// Mount marketing routes (public, rate-limited)
app.route('/', marketing_api);

// Mount production routes (authenticated)
app.route('/', production_api);

// Start the server
const port = process.env.PORT ? parseInt(process.env.PORT, 10) : 3001;

export default {
	port: port,
	fetch: app.fetch
};
