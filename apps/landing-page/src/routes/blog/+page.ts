import type { PageLoad } from './$types';
import { blog_posts } from '$lib/blog/posts';

export const load = (() => {
        return {
                posts: blog_posts
        };
}) satisfies PageLoad;
