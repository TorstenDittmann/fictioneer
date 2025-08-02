import { error } from '@sveltejs/kit';
import type { LayoutLoad } from './$types';
import { projects_service } from '$lib/services/projects.js';

export const load: LayoutLoad = async ({ params }) => {
	const { projectId, chapterId } = params;

	// Find the chapter using the service
	const chapter = projects_service.get_chapter(projectId, chapterId);

	if (!chapter) {
		// Chapter not found, throw error
		throw error(404, `Chapter with id "${chapterId}" not found in project "${projectId}"`);
	}

	return {
		chapter
	};
};
