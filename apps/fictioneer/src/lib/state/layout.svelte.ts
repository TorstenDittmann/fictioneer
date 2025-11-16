// Shared layout state using Svelte runes
export const layout_state = (() => {
	let is_sidebar_visible = $state(true);
	let command_menu_open = $state(false);
	let is_distraction_free = $state(false);
	let focus_hint_visible = $state(false);
	let focus_hint_timeout: ReturnType<typeof setTimeout> | null = null;

	function show_focus_hint() {
		focus_hint_visible = true;
		if (focus_hint_timeout) {
			clearTimeout(focus_hint_timeout);
		}
		focus_hint_timeout = setTimeout(() => {
			focus_hint_visible = false;
			focus_hint_timeout = null;
		}, 4000);
	}

	function hide_focus_hint() {
		focus_hint_visible = false;
		if (focus_hint_timeout) {
			clearTimeout(focus_hint_timeout);
			focus_hint_timeout = null;
		}
	}

	function update_distraction_free(value: boolean) {
		is_distraction_free = value;
		if (value) {
			show_focus_hint();
		} else {
			hide_focus_hint();
		}
	}

	return {
		get is_sidebar_visible() {
			return is_sidebar_visible;
		},
		set is_sidebar_visible(value: boolean) {
			is_sidebar_visible = value;
		},
		get command_menu_open() {
			return command_menu_open;
		},
		set command_menu_open(value: boolean) {
			command_menu_open = value;
		},
		get is_distraction_free() {
			return is_distraction_free;
		},
		set is_distraction_free(value: boolean) {
			update_distraction_free(value);
		},
		get focus_hint_visible() {
			return focus_hint_visible;
		},
		toggle_sidebar() {
			is_sidebar_visible = !is_sidebar_visible;
		},
		open_command_menu() {
			command_menu_open = true;
		},
		close_command_menu() {
			command_menu_open = false;
		},
		toggle_distraction_free() {
			update_distraction_free(!is_distraction_free);
		}
	};
})();
