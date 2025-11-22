import type { PageLoad } from './$types';
import { blog_posts } from '$lib/data/blog_posts';

export const load: PageLoad = () => {
        const posts = [...blog_posts]
                .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime())
                .map(({ content, ...metadata }) => metadata);

        return { posts };
};
