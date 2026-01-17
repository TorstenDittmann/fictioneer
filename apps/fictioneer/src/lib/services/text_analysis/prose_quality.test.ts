import { describe, it, expect } from 'bun:test';
import {
	detect_adverbs,
	detect_passive_voice,
	detect_filter_words,
	detect_cliches,
	detect_vague_words
} from './prose_quality.js';

describe('detect_adverbs', () => {
	describe('-ly adverbs', () => {
		it('should detect "quickly"', () => {
			const text = 'She ran quickly.';
			const adverbs = detect_adverbs(text);

			expect(adverbs.some((a) => a.word.toLowerCase() === 'quickly')).toBe(true);
		});

		it('should detect "slowly"', () => {
			const text = 'He walked slowly.';
			const adverbs = detect_adverbs(text);

			expect(adverbs.some((a) => a.word.toLowerCase() === 'slowly')).toBe(true);
		});

		it('should detect "carefully"', () => {
			const text = 'She carefully opened the door.';
			const adverbs = detect_adverbs(text);

			expect(adverbs.some((a) => a.word.toLowerCase() === 'carefully')).toBe(true);
		});
	});

	describe('exceptions (words ending in -ly that are not adverbs)', () => {
		it('should not flag "only"', () => {
			const text = 'She was the only one.';
			const adverbs = detect_adverbs(text);

			const only_matches = adverbs.filter((a) => a.word.toLowerCase() === 'only');
			expect(only_matches.length).toBe(0);
		});

		it('should not flag "early"', () => {
			const text = 'He arrived early.';
			const adverbs = detect_adverbs(text);

			const early_matches = adverbs.filter((a) => a.word.toLowerCase() === 'early');
			expect(early_matches.length).toBe(0);
		});

		it('should not flag "friendly"', () => {
			const text = 'She was friendly.';
			const adverbs = detect_adverbs(text);

			const friendly_matches = adverbs.filter((a) => a.word.toLowerCase() === 'friendly');
			expect(friendly_matches.length).toBe(0);
		});

		it('should not flag "lonely"', () => {
			const text = 'He felt lonely.';
			const adverbs = detect_adverbs(text);

			const lonely_matches = adverbs.filter((a) => a.word.toLowerCase() === 'lonely');
			expect(lonely_matches.length).toBe(0);
		});

		it('should not flag "lovely"', () => {
			const text = 'What a lovely day.';
			const adverbs = detect_adverbs(text);

			const lovely_matches = adverbs.filter((a) => a.word.toLowerCase() === 'lovely');
			expect(lovely_matches.length).toBe(0);
		});
	});

	describe('non-ly adverbs', () => {
		it('should detect "very"', () => {
			const text = 'She was very happy.';
			const adverbs = detect_adverbs(text);

			expect(adverbs.some((a) => a.word.toLowerCase() === 'very')).toBe(true);
		});

		it('should detect "quite"', () => {
			const text = 'He was quite tall.';
			const adverbs = detect_adverbs(text);

			expect(adverbs.some((a) => a.word.toLowerCase() === 'quite')).toBe(true);
		});

		it('should detect "always"', () => {
			const text = 'She always smiled.';
			const adverbs = detect_adverbs(text);

			expect(adverbs.some((a) => a.word.toLowerCase() === 'always')).toBe(true);
		});

		it('should detect "never"', () => {
			const text = 'He never complained.';
			const adverbs = detect_adverbs(text);

			expect(adverbs.some((a) => a.word.toLowerCase() === 'never')).toBe(true);
		});
	});

	it('should include position', () => {
		const text = 'She walked slowly home.';
		const adverbs = detect_adverbs(text);

		const slowly = adverbs.find((a) => a.word.toLowerCase() === 'slowly');
		expect(slowly?.position).toBeDefined();
		expect(slowly?.position).toBeGreaterThanOrEqual(0);
	});

	it('should include sentence', () => {
		const text = 'She walked slowly home.';
		const adverbs = detect_adverbs(text);

		const slowly = adverbs.find((a) => a.word.toLowerCase() === 'slowly');
		expect(slowly?.sentence).toBeDefined();
		expect(slowly?.sentence.length).toBeGreaterThan(0);
	});

	it('should return empty array for no adverbs', () => {
		const text = 'The cat sat on the mat.';
		const adverbs = detect_adverbs(text);

		expect(adverbs.length).toBe(0);
	});

	it('should handle empty text', () => {
		const adverbs = detect_adverbs('');
		expect(adverbs).toEqual([]);
	});
});

describe('detect_passive_voice', () => {
	it('should detect "was taken"', () => {
		const text = 'The book was taken from the shelf.';
		const passives = detect_passive_voice(text);

		expect(passives.some((p) => p.phrase.includes('was') && p.phrase.includes('taken'))).toBe(true);
	});

	it('should detect "were seen"', () => {
		const text = 'They were seen at the park.';
		const passives = detect_passive_voice(text);

		expect(passives.some((p) => p.phrase.includes('were') && p.phrase.includes('seen'))).toBe(true);
	});

	it('should detect "is known"', () => {
		const text = 'He is known for his work.';
		const passives = detect_passive_voice(text);

		expect(passives.some((p) => p.phrase.includes('is') && p.phrase.includes('known'))).toBe(true);
	});

	it('should detect "been done"', () => {
		const text = 'The work has been done already.';
		const passives = detect_passive_voice(text);

		expect(passives.some((p) => p.phrase.includes('been') && p.phrase.includes('done'))).toBe(true);
	});

	it('should detect irregular past participles', () => {
		const text = 'The window was broken by the ball.';
		const passives = detect_passive_voice(text);

		expect(passives.some((p) => p.phrase.includes('broken'))).toBe(true);
	});

	it('should include position', () => {
		const text = 'The book was taken.';
		const passives = detect_passive_voice(text);

		if (passives.length > 0) {
			expect(passives[0].position).toBeDefined();
			expect(passives[0].position).toBeGreaterThanOrEqual(0);
		}
	});

	it('should include suggestion', () => {
		const text = 'The letter was written by John.';
		const passives = detect_passive_voice(text);

		if (passives.length > 0) {
			expect(passives[0].suggestion).toBeDefined();
			expect(passives[0].suggestion.length).toBeGreaterThan(0);
		}
	});

	it('should handle empty text', () => {
		const passives = detect_passive_voice('');
		expect(passives).toEqual([]);
	});

	it('should not flag active voice', () => {
		const text = 'John wrote the letter.';
		const passives = detect_passive_voice(text);

		expect(passives.length).toBe(0);
	});
});

describe('detect_filter_words', () => {
	it('should detect "just"', () => {
		const text = 'I just wanted to say hello.';
		const filters = detect_filter_words(text);

		expect(filters.some((f) => f.word === 'just')).toBe(true);
	});

	it('should detect "really"', () => {
		const text = 'It was really nice.';
		const filters = detect_filter_words(text);

		expect(filters.some((f) => f.word === 'really')).toBe(true);
	});

	it('should detect "very"', () => {
		const text = 'She was very happy.';
		const filters = detect_filter_words(text);

		expect(filters.some((f) => f.word === 'very')).toBe(true);
	});

	it('should detect "actually"', () => {
		const text = 'I actually think it works.';
		const filters = detect_filter_words(text);

		expect(filters.some((f) => f.word === 'actually')).toBe(true);
	});

	it('should detect "basically"', () => {
		const text = 'It basically means nothing.';
		const filters = detect_filter_words(text);

		expect(filters.some((f) => f.word === 'basically')).toBe(true);
	});

	it('should detect multi-word filters like "kind of"', () => {
		const text = 'It was kind of nice.';
		const filters = detect_filter_words(text);

		expect(filters.some((f) => f.word === 'kind of')).toBe(true);
	});

	it('should include position', () => {
		const text = 'I just wanted to help.';
		const filters = detect_filter_words(text);

		const just = filters.find((f) => f.word === 'just');
		expect(just?.position).toBeDefined();
		expect(just?.position).toBeGreaterThanOrEqual(0);
	});

	it('should sort by position', () => {
		const text = 'I really just wanted to basically say hello.';
		const filters = detect_filter_words(text);

		for (let i = 1; i < filters.length; i++) {
			expect(filters[i].position).toBeGreaterThanOrEqual(filters[i - 1].position);
		}
	});

	it('should handle empty text', () => {
		const filters = detect_filter_words('');
		expect(filters).toEqual([]);
	});

	it('should return empty for text without filter words', () => {
		const text = 'The cat sat on the mat.';
		const filters = detect_filter_words(text);

		expect(filters.length).toBe(0);
	});
});

describe('detect_cliches', () => {
	it('should detect "once upon a time"', () => {
		const text = 'Once upon a time, there was a princess.';
		const cliches = detect_cliches(text);

		expect(cliches.some((c) => c.phrase === 'once upon a time')).toBe(true);
	});

	it('should detect "in the nick of time"', () => {
		const text = 'He arrived in the nick of time.';
		const cliches = detect_cliches(text);

		expect(cliches.some((c) => c.phrase === 'in the nick of time')).toBe(true);
	});

	it('should detect "crystal clear"', () => {
		const text = 'The water was crystal clear.';
		const cliches = detect_cliches(text);

		expect(cliches.some((c) => c.phrase === 'crystal clear')).toBe(true);
	});

	it('should detect "at the end of the day"', () => {
		const text = 'At the end of the day, it did not matter.';
		const cliches = detect_cliches(text);

		expect(cliches.some((c) => c.phrase === 'at the end of the day')).toBe(true);
	});

	it('should detect "heart of gold"', () => {
		const text = 'She had a heart of gold.';
		const cliches = detect_cliches(text);

		expect(cliches.some((c) => c.phrase === 'heart of gold')).toBe(true);
	});

	it('should include position', () => {
		const text = 'He arrived in the nick of time.';
		const cliches = detect_cliches(text);

		if (cliches.length > 0) {
			expect(cliches[0].position).toBeDefined();
			expect(cliches[0].position).toBeGreaterThanOrEqual(0);
		}
	});

	it('should sort by position', () => {
		const text = 'Once upon a time, it was crystal clear, at the end of the day.';
		const cliches = detect_cliches(text);

		for (let i = 1; i < cliches.length; i++) {
			expect(cliches[i].position).toBeGreaterThanOrEqual(cliches[i - 1].position);
		}
	});

	it('should handle empty text', () => {
		const cliches = detect_cliches('');
		expect(cliches).toEqual([]);
	});

	it('should return empty for text without cliches', () => {
		const text = 'The scientist conducted a thorough experiment.';
		const cliches = detect_cliches(text);

		expect(cliches.length).toBe(0);
	});
});

describe('detect_vague_words', () => {
	it('should detect "thing"', () => {
		const text = 'The thing was on the table.';
		const vagues = detect_vague_words(text);

		expect(vagues.some((v) => v.word.toLowerCase() === 'thing')).toBe(true);
	});

	it('should detect "stuff"', () => {
		const text = 'He packed his stuff.';
		const vagues = detect_vague_words(text);

		expect(vagues.some((v) => v.word.toLowerCase() === 'stuff')).toBe(true);
	});

	it('should detect "something"', () => {
		const text = 'Something happened.';
		const vagues = detect_vague_words(text);

		expect(vagues.some((v) => v.word.toLowerCase() === 'something')).toBe(true);
	});

	it('should detect "nice"', () => {
		const text = 'It was a nice day.';
		const vagues = detect_vague_words(text);

		expect(vagues.some((v) => v.word.toLowerCase() === 'nice')).toBe(true);
	});

	it('should detect "good"', () => {
		const text = 'The food was good.';
		const vagues = detect_vague_words(text);

		expect(vagues.some((v) => v.word.toLowerCase() === 'good')).toBe(true);
	});

	it('should detect "bad"', () => {
		const text = 'The weather was bad.';
		const vagues = detect_vague_words(text);

		expect(vagues.some((v) => v.word.toLowerCase() === 'bad')).toBe(true);
	});

	it('should detect "interesting"', () => {
		const text = 'The book was interesting.';
		const vagues = detect_vague_words(text);

		expect(vagues.some((v) => v.word.toLowerCase() === 'interesting')).toBe(true);
	});

	it('should include position', () => {
		const text = 'The thing was there.';
		const vagues = detect_vague_words(text);

		const thing = vagues.find((v) => v.word.toLowerCase() === 'thing');
		expect(thing?.position).toBeDefined();
		expect(thing?.position).toBeGreaterThanOrEqual(0);
	});

	it('should sort by position', () => {
		const text = 'Something nice happened to someone.';
		const vagues = detect_vague_words(text);

		for (let i = 1; i < vagues.length; i++) {
			expect(vagues[i].position).toBeGreaterThanOrEqual(vagues[i - 1].position);
		}
	});

	it('should handle empty text', () => {
		const vagues = detect_vague_words('');
		expect(vagues).toEqual([]);
	});

	it('should return empty for text without vague words', () => {
		const text = 'The crimson sunset painted the horizon.';
		const vagues = detect_vague_words(text);

		expect(vagues.length).toBe(0);
	});
});
