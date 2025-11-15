import { env } from '$env/dynamic/public';

const public_intelligence_url = env.PUBLIC_INTELLIGENCE_SERVER_URL ?? '';

export const config = {
	intelligence_api: {
		base_url: public_intelligence_url
	}
};

export const api_endpoints = {
	story_generator: {
		generate: '/api/marketing/generate-story'
	}
};
