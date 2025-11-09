import arcjet, { tokenBucket, shield } from '@arcjet/bun';

export const aj = arcjet({
	key: Bun.env.ARCJET_KEY!,
	rules: [
		shield({ mode: 'LIVE' }),
		tokenBucket({
			mode: 'LIVE',
			refillRate: 5,
			interval: 10,
			capacity: 10
		})
	]
});
