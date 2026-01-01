import { MARBLE_API_KEY } from '$env/static/private';
import type { Post } from '@usemarble/core';

const MARBLE_API_URL = 'https://api.marblecms.com/v1';

export async function get_posts(): Promise<Post[]> {
	const response = await fetch(`${MARBLE_API_URL}/posts`, {
		headers: {
			Authorization: `Bearer ${MARBLE_API_KEY}`
		}
	});

	if (!response.ok) {
		throw new Error(`Failed to fetch posts: ${response.statusText}`);
	}

	const data = await response.json();

	return data.posts;
}

export async function get_post_by_slug(slug: string): Promise<Post | null> {
	const response = await fetch(`${MARBLE_API_URL}/posts?slug=${slug}`, {
		headers: {
			Authorization: `Bearer ${MARBLE_API_KEY}`
		}
	});

	if (!response.ok) {
		throw new Error(`Failed to fetch post: ${response.statusText}`);
	}

	const data = await response.json();

	if (data.posts.length === 0) {
		return null;
	}

	return data.posts[0];
}

export function calculate_read_time(content: string): number {
	const words_per_minute = 238;
	const plain_text = content.replace(/<[^>]*>/g, '').trim();
	const word_count = plain_text.split(/\s+/).length;
	const reading_time = Math.ceil(word_count / words_per_minute);
	return reading_time;
}
