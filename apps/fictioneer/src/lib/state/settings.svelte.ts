export interface EditorSettings {
	font_family: string;
	font_size_px: number;
	line_height: number;
	page_margin_px: number;
	spellcheck: boolean;
}

export interface ExportDefaults {
	include_title: boolean;
	include_chapter_titles: boolean;
	include_scene_titles: boolean;
	include_word_count: boolean;
	format: 'rtf' | 'txt' | 'epub';
}

export interface AppSettings {
	theme: 'system' | 'light' | 'dark';
	autosave_interval_ms: number;
	shortcut_profile: 'default';
	intelligence_server_url: string | null;
	editor: EditorSettings;
	export_defaults: ExportDefaults;
}

const SETTINGS_STORAGE_KEY = 'fictioneer_settings';

function get_default_settings(): AppSettings {
	return {
		theme: 'system',
		autosave_interval_ms: 3000,
		shortcut_profile: 'default',
		intelligence_server_url: null,
		editor: {
			font_family: 'Libre Baskerville, serif',
			font_size_px: 18,
			line_height: 1.75,
			page_margin_px: 32,
			spellcheck: true
		},
		export_defaults: {
			include_title: true,
			include_chapter_titles: true,
			include_scene_titles: true,
			include_word_count: false,
			format: 'rtf'
		}
	};
}

function create_settings_state() {
	const internal = $state<{ settings: AppSettings; initialized: boolean }>({
		settings: get_default_settings(),
		initialized: false
	});

	function load_from_storage(): AppSettings | null {
		if (typeof localStorage === 'undefined') return null;

		try {
			const raw = localStorage.getItem(SETTINGS_STORAGE_KEY);
			if (!raw) return null;
			const parsed = JSON.parse(raw) as Partial<AppSettings>;
			return {
				...get_default_settings(),
				...parsed,
				editor: { ...get_default_settings().editor, ...(parsed.editor || {}) },
				export_defaults: {
					...get_default_settings().export_defaults,
					...(parsed.export_defaults || {})
				}
			};
		} catch {
			return null;
		}
	}

	function save_to_storage(settings: AppSettings): void {
		if (typeof localStorage === 'undefined') return;
		try {
			localStorage.setItem(SETTINGS_STORAGE_KEY, JSON.stringify(settings));
		} catch {
			// ignore write errors
		}
	}

	return {
		get settings(): AppSettings {
			return internal.settings;
		},

		get initialized(): boolean {
			return internal.initialized;
		},

		async initialize() {
			if (internal.initialized) return;
			const loaded = load_from_storage();
			if (loaded) internal.settings = loaded;
			internal.initialized = true;
		},

		update(partial: Partial<AppSettings>) {
			internal.settings = {
				...internal.settings,
				...partial,
				editor: {
					...internal.settings.editor,
					...(partial.editor || {})
				},
				export_defaults: {
					...internal.settings.export_defaults,
					...(partial.export_defaults || {})
				}
			};
			save_to_storage(internal.settings);
		},

		set_editor(editor: Partial<EditorSettings>) {
			this.update({ editor: { ...internal.settings.editor, ...editor } });
		},

		set_export_defaults(export_defaults: Partial<ExportDefaults>) {
			this.update({
				export_defaults: { ...internal.settings.export_defaults, ...export_defaults }
			});
		}
	};
}

export const settings_state = create_settings_state();
