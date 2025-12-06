import posthog from 'posthog-js';
import { browser } from '$app/environment';
import { type } from '@tauri-apps/plugin-os';
import type { LayoutLoad } from './$types';

export const ssr = false;
export const prerender = false;

export const load: LayoutLoad = async () => {
	let os_type = 'unknown';

	try {
		os_type = await type();
	} catch (error) {
		console.warn('Unable to determine OS type', error);
	}

	if (browser) {
		posthog.init('phc_Rnfc8HPFJ1Duqo23ykhIYTivNNB8Mn5v6NqbVUxLJkS', {
			api_host: 'https://eu.i.posthog.com',
			defaults: '2025-05-24'
		});
	}

	return { os_type };
};
