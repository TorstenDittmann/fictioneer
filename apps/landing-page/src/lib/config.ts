import { PUBLIC_INTELLIGENCE_API_URL } from '$env/static/public';

export const config = {
	intelligence_api: {
		base_url: PUBLIC_INTELLIGENCE_API_URL
	}
};

export const api_endpoints = {
	story_generator: {
		generate: '/api/marketing/generate-story'
	}
};
