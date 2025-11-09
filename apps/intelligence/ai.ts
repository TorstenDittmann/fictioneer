import { createOpenRouter } from '@openrouter/ai-sdk-provider';

const OPENROUTER_API_KEY = Bun.env.OPENROUTER_API_KEY;

if (!OPENROUTER_API_KEY) {
	throw new Error('OPENROUTER_API_KEY environment variable is required');
}

export const openrouter = createOpenRouter({
	apiKey: OPENROUTER_API_KEY,
	headers: {
		'HTTP-Referer': 'https://fictioneer.app',
		'X-Title': 'Fictioneer'
	}
});
