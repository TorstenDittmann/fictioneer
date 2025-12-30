import { browser } from '$app/environment';

type Theme = 'light' | 'dark';

function createThemeStore() {
	let current = $state<Theme>('light');

	function set(theme: Theme) {
		current = theme;
		if (browser) {
			document.documentElement.setAttribute('data-theme', theme);
			document.cookie = `theme=${theme};path=/;max-age=${60 * 60 * 24 * 365};SameSite=Lax`;
		}
	}

	function toggle() {
		set(current === 'light' ? 'dark' : 'light');
	}

	return {
		get current() {
			return current;
		},
		set,
		toggle
	};
}

export const theme = createThemeStore();
