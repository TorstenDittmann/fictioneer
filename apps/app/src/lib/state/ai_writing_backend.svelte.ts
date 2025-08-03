import { ai_writing_backend_service } from '$lib/services/ai_writing_backend.js';

function create_ai_writing_backend_state() {
	const state = $state({
		is_loading: false,
		error: null as string | null,
		current_suggestion: null as string | null
	});

	return {
		get is_loading() {
			return state.is_loading;
		},
		get error() {
			return state.error;
		},
		get current_suggestion() {
			return state.current_suggestion;
		},

		async continue_writing(content: string, context: unknown = {}, word_count: number = 100) {
			state.is_loading = true;
			state.error = null;

			try {
				const result = await ai_writing_backend_service.continue_writing(
					content,
					context,
					word_count
				);
				state.current_suggestion = result;
				return result;
			} catch (error) {
				state.error = error instanceof Error ? error.message : 'Failed to generate continuation';
				return null;
			} finally {
				state.is_loading = false;
			}
		},

		async check_health() {
			try {
				return await ai_writing_backend_service.check_health();
			} catch {
				state.error = 'Backend service is not available';
				return false;
			}
		},

		clear_suggestion() {
			state.current_suggestion = null;
		},

		clear_error() {
			state.error = null;
		}
	};
}

export const ai_writing_backend = create_ai_writing_backend_state();
