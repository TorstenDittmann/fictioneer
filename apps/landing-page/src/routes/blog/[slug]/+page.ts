import type { PageLoad } from './$types';
import { error } from '@sveltejs/kit';
import { get_blog_post } from '$lib/blog/posts';

export const load = (({ params }) => {
        const post = get_blog_post(params.slug);

        if (!post) {
                        throw error(404, 'Blog post not found');
        }

        return {
                post
        };
}) satisfies PageLoad;
