import { client } from './ai_writing_backend';

const LICENSE_KEY_STORAGE_KEY = 'fictioneer_license_key';

export interface LicenseKeyVerificationResult {
	is_valid: boolean;
	error?: string;
}

export class LicenseKeyService {
	private cached_key: string | null = null;

	/**
	 * Load license key from localStorage
	 */
	load_license_key(): string | null {
		if (this.cached_key) return this.cached_key;

		if (typeof localStorage === 'undefined') return null;

		try {
			const stored_key = localStorage.getItem(LICENSE_KEY_STORAGE_KEY);
			this.cached_key = stored_key;
			return stored_key;
		} catch (error) {
			console.error('Failed to load license key from localStorage:', error);
			return null;
		}
	}

	/**
	 * Save license key to localStorage
	 */
	save_license_key(key: string | null): void {
		this.cached_key = key;

		if (typeof localStorage === 'undefined') return;

		try {
			if (key) {
				localStorage.setItem(LICENSE_KEY_STORAGE_KEY, key);
			} else {
				localStorage.removeItem(LICENSE_KEY_STORAGE_KEY);
			}
		} catch (error) {
			console.error('Failed to save license key to localStorage:', error);
		}
	}

	/**
	 * Verify license key with the backend
	 */
	async verify_license_key(key: string): Promise<LicenseKeyVerificationResult> {
		if (!key || key.trim() === '') {
			return { is_valid: false, error: 'License key is required' };
		}

		try {
			const response = await client.api.verify.$post(undefined, {
				headers: {
					'Content-Type': 'application/json',
					Authorization: `Bearer ${key}`
				}
			});

			const is_valid = response.ok;

			if (!is_valid) {
				return {
					is_valid: false,
					error: response.status === 401 ? 'Invalid license key' : 'Verification failed'
				};
			}

			return { is_valid: true };
		} catch (error) {
			console.error('License key verification failed:', error);
			return {
				is_valid: false,
				error: 'Unable to verify license key. Please check your connection.'
			};
		}
	}

	/**
	 * Remove license key from storage
	 */
	remove_license_key(): void {
		this.save_license_key(null);
	}
}

export const license_key_service = new LicenseKeyService();
