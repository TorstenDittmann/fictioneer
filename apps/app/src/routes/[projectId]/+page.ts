import type { PageLoad } from './$types';

export const load: PageLoad = async ({ parent }) => {
	// Wait for parent layout data
	const { project } = await parent();

	return {
		project
	};
};
