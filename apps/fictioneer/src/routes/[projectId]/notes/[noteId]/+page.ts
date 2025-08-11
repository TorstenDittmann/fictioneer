import type { PageLoad } from './$types';

export const load: PageLoad = async ({ params }) => {
	return {
		noteId: params.noteId,
		projectId: params.projectId
	};
};
