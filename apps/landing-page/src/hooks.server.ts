import type { Handle } from '@sveltejs/kit';

export const handle: Handle = async ({ event, resolve }) => {
	const theme = event.cookies.get('theme') as 'light' | 'dark' | undefined;

	return resolve(event, {
		transformPageChunk: ({ html }) => {
			if (theme) {
				return html.replace('<html lang="en">', `<html lang="en" data-theme="${theme}">`);
			}
			return html;
		}
	});
};
