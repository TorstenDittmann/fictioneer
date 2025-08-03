import type { PageLoad } from './$types';

export const load: PageLoad = async ({ parent }) => {
	// Get project data from parent layout
	const { project } = await parent();

	return {
		project
	};
};
