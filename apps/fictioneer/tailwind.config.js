/** @type {import('tailwindcss').Config} */
export default {
	content: ['./src/**/*.{html,js,svelte,ts}'],
	darkMode: 'class',
	theme: {
		extend: {
			fontFamily: {
				sans: [
					'-apple-system',
					'BlinkMacSystemFont',
					'Segoe UI',
					'Roboto',
					'Oxygen',
					'Ubuntu',
					'Cantarell',
					'sans-serif'
				],
				serif: ['Libre Baskerville', 'Georgia', 'Times New Roman', 'serif'],
				mono: ['Monaco', 'Menlo', 'Ubuntu Mono', 'monospace']
			}
		}
	},
	plugins: []
};
