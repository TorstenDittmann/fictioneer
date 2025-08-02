import { error } from '@sveltejs/kit';
import type { LayoutLoad } from './$types';
import { projects_service } from '$lib/services/projects.js';

export const load: LayoutLoad = async ({ params }) => {
	const { projectId } = params;

	// Find the project using the service
	const project = projects_service.get_project(projectId);

	if (!project) {
		// Project not found, throw error instead of redirect
		throw error(404, `Project with id "${projectId}" not found`);
	}

	return {
		project
	};
};
