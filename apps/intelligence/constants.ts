export const POSTHOG_KEY = 'phc_Rnfc8HPFJ1Duqo23ykhIYTivNNB8Mn5v6NqbVUxLJkS';
export const POSTHOG_HOST = 'https://eu.i.posthog.com';

export const CORS_CONFIG = {
	origin: '*',
	allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
	allowHeaders: ['Content-Type', 'Authorization', 'Cache-Control', 'X-Requested-With'],
	exposeHeaders: ['Content-Type', 'Cache-Control'],
	maxAge: 86400
};

export const AI_DEFAULTS = {
	temperature: 0.8,
	topP: 0.9
} as const;
