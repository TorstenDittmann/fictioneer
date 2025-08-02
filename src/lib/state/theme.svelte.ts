import { MediaQuery } from 'svelte/reactivity';

type Theme = 'light' | 'dark' | 'system';

class ThemeStore {
	private theme_preference = $state<Theme>('system');
	private system_prefers_dark = new MediaQuery('(prefers-color-scheme: dark)');

	constructor() {
		this.load_theme_preference();
		this.apply_theme();

		// Note: reactive effects will be handled by components that use this store
	}

	private load_theme_preference() {
		const saved = localStorage.getItem('theme-preference');
		if (saved === 'light' || saved === 'dark' || saved === 'system') {
			this.theme_preference = saved;
		}
	}

	private save_theme_preference() {
		localStorage.setItem('theme-preference', this.theme_preference);
	}

	private apply_theme() {
		const should_be_dark = this.should_be_dark;

		if (should_be_dark) {
			document.documentElement.classList.add('dark');
		} else {
			document.documentElement.classList.remove('dark');
		}
	}

	get current_preference(): Theme {
		return this.theme_preference;
	}

	get should_be_dark(): boolean {
		switch (this.theme_preference) {
			case 'dark':
				return true;
			case 'light':
				return false;
			case 'system':
				return this.system_prefers_dark.current;
		}
	}

	get current_theme(): 'light' | 'dark' {
		return this.should_be_dark ? 'dark' : 'light';
	}

	get system_prefers_dark_mode(): boolean {
		return this.system_prefers_dark.current;
	}

	set_theme(theme: Theme) {
		this.theme_preference = theme;
		this.save_theme_preference();
		this.apply_theme();
	}

	// Call this in components to set up reactive theme watching
	setup_reactivity() {
		$effect(() => {
			// This effect runs when system_prefers_dark or theme_preference changes
			// Access the values to track them reactively
			void this.system_prefers_dark.current;
			void this.theme_preference;
			this.apply_theme();
		});
	}

	toggle_theme() {
		switch (this.theme_preference) {
			case 'light':
				this.set_theme('dark');
				break;
			case 'dark':
				this.set_theme('system');
				break;
			case 'system':
				this.set_theme('light');
				break;
		}
	}

	get next_theme_label(): string {
		switch (this.theme_preference) {
			case 'light':
				return 'Dark';
			case 'dark':
				return 'System';
			case 'system':
				return 'Light';
		}
	}

	get current_theme_label(): string {
		switch (this.theme_preference) {
			case 'light':
				return 'Light';
			case 'dark':
				return 'Dark';
			case 'system':
				return `System (${this.system_prefers_dark_mode ? 'Dark' : 'Light'})`;
		}
	}
}

export const theme = new ThemeStore();
