import { env } from '$env/dynamic/public';

const DEFAULT_INTELLIGENCE_URL = 'https://intelligence.fictioneer.app';

export const config = {
	intelligence_api: {
		base_url: env.PUBLIC_INTELLIGENCE_SERVER_URL ?? DEFAULT_INTELLIGENCE_URL
	}
};

export const api_endpoints = {
	story_generator: {
		generate: '/api/marketing/generate-story'
	}
};
