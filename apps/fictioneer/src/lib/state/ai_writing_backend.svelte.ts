import { ai_writing_backend_service } from '$lib/services/ai_writing_backend.js';

function create_ai_writing_backend_state() {
	const state = $state({
		is_loading: false,
		error: null as string | null,
		current_suggestion: null as string | null,
		is_cancelled: false
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
		},

		cancel_current_request() {
			ai_writing_backend_service.cancel_current_request();
			state.is_cancelled = true;
			state.is_loading = false;
		},

		get is_request_active() {
			return ai_writing_backend_service.is_request_active();
		}
	};
}

export const ai_writing_backend = create_ai_writing_backend_state();
