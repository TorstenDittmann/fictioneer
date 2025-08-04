import { redirect } from '@sveltejs/kit';
import type { LayoutLoad } from './$types';
import { projects_service } from '$lib/services/projects.svelte.js';

export const load: LayoutLoad = async ({ params }) => {
	const { projectId } = params;

	// Get the current project from the file service
	const project = projects_service.get_current_project();

	if (!project) {
		// No project loaded, redirect to home
		throw redirect(302, '/');
	}

	// Check if the projectId in the URL matches the current project
	if (project.id !== projectId) {
		// Project ID mismatch, redirect to correct URL
		const urls = projects_service.get_project_urls();
		if (urls) {
			throw redirect(302, urls.scene_url);
		} else {
			throw redirect(302, '/');
		}
	}

	return {
		project
	};
};
