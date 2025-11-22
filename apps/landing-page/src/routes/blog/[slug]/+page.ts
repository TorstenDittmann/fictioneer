import { error } from '@sveltejs/kit';
import type { PageLoad } from './$types';
import { find_blog_post } from '$lib/data/blog_posts';

export const load: PageLoad = ({ params }) => {
        const post = find_blog_post(params.slug);

        if (!post) {
                error(404, 'Post not found');
        }

        return { post };
};
