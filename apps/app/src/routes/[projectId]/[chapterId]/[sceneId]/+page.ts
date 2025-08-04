import { error } from '@sveltejs/kit';
import type { PageLoad } from './$types';
import { projects_service } from '$lib/services/projects.svelte.js';

export const load: PageLoad = async ({ params, parent }) => {
	const { sceneId } = params;

	// Wait for parent layout data
	const { chapter } = await parent();

	// Find the scene using the service
	const scene = projects_service.get_scene(chapter.id, sceneId);

	if (!scene) {
		// Scene not found, throw error
		throw error(404, `Scene with id "${sceneId}" not found in chapter "${chapter.id}"`);
	}

	// Update last opened scene
	projects_service.update_last_opened_scene(sceneId);

	return {
		scene
	};
};
