import {
	license_key_service,
	type LicenseKeyVerificationResult
} from '$lib/services/license_key.js';

function create_license_key_state() {
	const state = $state({
		license_key: null as string | null,
		is_verifying: false,
		verification_result: null as LicenseKeyVerificationResult | null,
		is_initialized: false
	});

	return {
		get license_key() {
			return state.license_key;
		},

		get is_verifying() {
			return state.is_verifying;
		},

		get verification_result() {
			return state.verification_result;
		},

		get is_valid() {
			return state.verification_result?.is_valid ?? false;
		},

		get has_license_key() {
			return state.license_key !== null && state.license_key.trim() !== '';
		},

		get is_initialized() {
			return state.is_initialized;
		},

		/**
		 * Initialize license key state by loading from storage
		 */
		async initialize() {
			if (state.is_initialized) return;

			const stored_key = license_key_service.load_license_key();
			if (stored_key) {
				state.license_key = stored_key;
				await this.verify_current_key();
			}
			state.is_initialized = true;
		},

		/**
		 * Set and verify a new license key
		 */
		async set_license_key(key: string | null) {
			state.license_key = key;
			state.verification_result = null;

			if (key) {
				license_key_service.save_license_key(key);
				await this.verify_current_key();
			} else {
				license_key_service.remove_license_key();
				state.verification_result = null;
			}
		},

		/**
		 * Verify the current license key
		 */
		async verify_current_key() {
			if (!state.license_key) {
				state.verification_result = { is_valid: false, error: 'No license key provided' };
				return;
			}

			state.is_verifying = true;
			try {
				const result = await license_key_service.verify_license_key(state.license_key);
				state.verification_result = result;
			} catch {
				state.verification_result = {
					is_valid: false,
					error: 'Verification failed'
				};
			} finally {
				state.is_verifying = false;
			}
		},

		/**
		 * Remove the current license key
		 */
		remove_license_key() {
			this.set_license_key(null);
		},

		/**
		 * Re-verify the current license key
		 */
		async refresh_verification() {
			await this.verify_current_key();
		}
	};
}

export const license_key_state = create_license_key_state();
