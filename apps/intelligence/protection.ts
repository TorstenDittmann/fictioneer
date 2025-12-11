import arcjet, { tokenBucket, shield } from '@arcjet/bun';

const ARCJET_KEY = Bun.env.ARCJET_KEY;

if (!ARCJET_KEY) {
	throw new Error('ARCJET_KEY environment variable is required');
}

export const aj = arcjet({
	key: ARCJET_KEY,
	rules: [
		shield({ mode: 'LIVE' }),
		tokenBucket({
			mode: 'LIVE',
			refillRate: 2,
			interval: 15,
			capacity: 8
		})
	]
});
