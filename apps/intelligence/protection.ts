import arcjet, { tokenBucket, shield } from '@arcjet/bun';

export const aj = arcjet({
	key: Bun.env.ARCJET_KEY!,
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
