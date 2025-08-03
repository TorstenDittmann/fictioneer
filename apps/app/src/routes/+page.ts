import type { PageLoad } from './$types';
import { projects_service } from '$lib/services/projects.js';

export const load: PageLoad = async () => {
	const projects = projects_service.get_projects();

	return {
		projects
	};
};
