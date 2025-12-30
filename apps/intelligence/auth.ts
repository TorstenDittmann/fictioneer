import { bearerAuth } from 'hono/bearer-auth';
import DodoPayments from 'dodopayments';

const DODO_API_KEY = Bun.env.DODO_API_KEY;

if (!DODO_API_KEY) {
	throw new Error('DODO_API_KEY is not set');
}

const client = new DodoPayments({ bearerToken: DODO_API_KEY });

const license_cache = new Map<string, { valid: boolean; expires_at: number }>();
const CACHE_TTL_MS = 5 * 60 * 1000; // 5 minutes

async function validate_license(license_key: string): Promise<boolean> {
	const cached = license_cache.get(license_key);
	if (cached && cached.expires_at > Date.now()) {
		return cached.valid;
	}

	try {
		const { valid } = await client.licenses.validate({ license_key });

		license_cache.set(license_key, {
			valid,
			expires_at: Date.now() + CACHE_TTL_MS
		});

		return valid;
	} catch (error) {
		console.error('License validation error:', error);
		return false;
	}
}

export const auth = bearerAuth({
	verifyToken: async (token) => {
		return validate_license(token);
	}
});
