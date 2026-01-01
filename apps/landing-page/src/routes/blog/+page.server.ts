import type { PageServerLoad } from './$types';
import { get_posts } from '$lib/marble';

export const prerender = true;

export const load: PageServerLoad = async () => {
	try {
		const posts = await get_posts();
		return {
			posts
		};
	} catch (error) {
		console.error('Error loading blog posts:', error);
		return {
			posts: []
		};
	}
};
