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
			},
			colors: {
				gray: {
					50: '#f9fafb',
					100: '#f3f4f6',
					200: '#e5e7eb',
					300: '#d1d5db',
					400: '#9ca3af',
					500: '#6b7280',
					600: '#4b5563',
					700: '#374151',
					800: '#1f2937',
					900: '#111827'
				}
			},
			typography: {
				DEFAULT: {
					css: {
						maxWidth: 'none',
						color: '#374151',
						lineHeight: '1.8',
						fontSize: '18px',
						fontFamily: 'Libre Baskerville, Georgia, Times New Roman, serif',
						h1: {
							fontSize: '2.25rem',
							fontWeight: '700',
							lineHeight: '1.2',
							margin: '3rem 0 1.5rem 0',
							color: '#111827'
						},
						h2: {
							fontSize: '1.875rem',
							fontWeight: '700',
							lineHeight: '1.3',
							margin: '2.5rem 0 1rem 0',
							color: '#1f2937'
						},
						h3: {
							fontSize: '1.5rem',
							fontWeight: '700',
							lineHeight: '1.4',
							margin: '2rem 0 0.75rem 0',
							color: '#374151'
						},
						p: {
							margin: '1.25rem 0',
							lineHeight: '1.8'
						},
						blockquote: {
							borderLeftWidth: '4px',
							borderLeftColor: '#e5e7eb',
							paddingLeft: '1.5rem',
							margin: '2rem 0',
							fontStyle: 'italic',
							color: '#6b7280'
						},
						'ul, ol': {
							margin: '1.5rem 0',
							paddingLeft: '2rem'
						},
						li: {
							margin: '0.5rem 0',
							lineHeight: '1.7'
						},
						code: {
							backgroundColor: '#f3f4f6',
							padding: '0.25rem 0.5rem',
							borderRadius: '0.375rem',
							fontFamily: 'Monaco, Menlo, Ubuntu Mono, monospace',
							fontSize: '0.875rem'
						},
						pre: {
							backgroundColor: '#f8fafc',
							border: '1px solid #e2e8f0',
							borderRadius: '0.5rem',
							padding: '1.5rem',
							margin: '2rem 0',
							overflow: 'auto',
							fontFamily: 'Monaco, Menlo, Ubuntu Mono, monospace',
							fontSize: '0.875rem',
							lineHeight: '1.5'
						},
						hr: {
							border: 'none',
							borderTop: '2px solid #e5e7eb',
							margin: '3rem 0'
						}
					}
				},
				invert: {
					css: {
						color: '#d1d5db',
						h1: {
							color: '#f9fafb'
						},
						h2: {
							color: '#f3f4f6'
						},
						h3: {
							color: '#e5e7eb'
						},
						blockquote: {
							borderLeftColor: '#4b5563',
							color: '#9ca3af'
						},
						code: {
							backgroundColor: '#374151',
							color: '#d1d5db'
						},
						pre: {
							backgroundColor: '#1f2937',
							borderColor: '#374151',
							color: '#d1d5db'
						},
						hr: {
							borderTopColor: '#4b5563'
						}
					}
				}
			}
		}
	},
	plugins: []
};
