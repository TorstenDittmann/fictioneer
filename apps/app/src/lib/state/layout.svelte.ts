// Shared layout state using Svelte runes
export const layout_state = (() => {
	let is_sidebar_visible = $state(true);
	let command_menu_open = $state(false);
	let is_distraction_free = $state(false);

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
			is_distraction_free = value;
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
			is_distraction_free = !is_distraction_free;
		}
	};
})();
