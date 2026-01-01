import type { PageServerLoad } from './$types';
import { get_post_by_slug, calculate_read_time } from '$lib/marble';
import { error } from '@sveltejs/kit';

export const prerender = true;

export const load: PageServerLoad = async ({ params }) => {
	const post = await get_post_by_slug(params.slug);

	if (!post) {
		error(404);
	}

	const readTime = calculate_read_time(post.content);

	return {
		post,
		readTime
	};
};
