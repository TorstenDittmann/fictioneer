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
				serif: ['Quattrocento', 'Georgia', 'Times New Roman', 'serif'],
				mono: ['iA Writer Duo', 'SF Mono', 'Fira Code', 'Monaco', 'monospace']
			}
		}
	},
	plugins: []
};
