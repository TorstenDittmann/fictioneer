import type { PageLoad } from './$types';

export const load: PageLoad = async () => {
	// No longer loading projects from localStorage
	// Projects are now loaded on-demand from .fictioneer files
	return {};
};
