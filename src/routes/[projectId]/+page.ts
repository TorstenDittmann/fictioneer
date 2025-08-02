import { redirect } from '@sveltejs/kit';
import type { PageLoad } from './$types';

export const load: PageLoad = async ({ params, parent }) => {
	const { projectId } = params;

	// Wait for parent layout data
	const { project } = await parent();

	// If project has chapters and scenes, redirect to first scene
	if (project.chapters.length > 0) {
		const firstChapter = project.chapters[0];
		if (firstChapter.scenes.length > 0) {
			const firstScene = firstChapter.scenes[0];
			throw redirect(302, `/${projectId}/${firstChapter.id}/${firstScene.id}`);
		}
	}

	return {
		project
	};
};
