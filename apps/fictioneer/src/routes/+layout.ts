import posthog from 'posthog-js';
import { browser } from '$app/environment';
import type { LayoutLoad } from './$types';

export const ssr = false;
export const prerender = false;

export const load: LayoutLoad = async () => {
	if (browser) {
		posthog.init('phc_Rnfc8HPFJ1Duqo23ykhIYTivNNB8Mn5v6NqbVUxLJkS', {
			api_host: 'https://eu.i.posthog.com',
			defaults: '2025-05-24'
		});
	}

	return {};
};
