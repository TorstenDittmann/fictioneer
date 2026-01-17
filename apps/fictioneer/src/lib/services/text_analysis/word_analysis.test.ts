import { describe, it, expect } from 'bun:test';
import {
	detect_repetitions,
	detect_weak_verbs,
	get_word_frequency,
	get_overused_words
} from './word_analysis.js';
import type { AnalysisConfig } from '../../types/analysis.js';

const default_config: AnalysisConfig = {
	min_sentence_length: 5,
	max_sentence_length: 30,
	max_adverb_percentage: 5,
	max_passive_percentage: 10,
	repetition_distance: 50,
	repetition_min_word_length: 4,
	enable_cliche_detection: true,
	enable_vague_word_detection: true
};

describe('detect_repetitions', () => {
	it('should detect repeated words within distance', () => {
		const text = 'The beautiful sunset was beautiful to watch.';
		const repetitions = detect_repetitions(text, default_config);

		expect(repetitions.length).toBeGreaterThan(0);
		expect(repetitions[0].word).toBe('beautiful');
	});

	it('should not flag common words', () => {
		const text = 'The the the cat sat on the mat.';
		const repetitions = detect_repetitions(text, default_config);

		const the_repetitions = repetitions.filter((r) => r.word === 'the');
		expect(the_repetitions.length).toBe(0);
	});

	it('should respect minimum word length', () => {
		const config = { ...default_config, repetition_min_word_length: 6 };
		const text = 'The bird flew and the bird sang.';
		const repetitions = detect_repetitions(text, config);

		// "bird" is only 4 characters, should be ignored with min_length 6
		const bird_repetitions = repetitions.filter((r) => r.word === 'bird');
		expect(bird_repetitions.length).toBe(0);
	});

	it('should respect distance configuration', () => {
		const config = { ...default_config, repetition_distance: 5 };
		const text = 'The beautiful sunset. Many words here to separate. The beautiful scene.';
		const repetitions = detect_repetitions(text, config);

		// Words are more than 5 words apart, should not be flagged
		const beautiful_repetitions = repetitions.filter((r) => r.word === 'beautiful');
		expect(beautiful_repetitions.length).toBe(0);
	});

	it('should include distance in result', () => {
		const text = 'The castle stood tall. The ancient castle was magnificent.';
		const repetitions = detect_repetitions(text, default_config);

		const castle_rep = repetitions.find((r) => r.word === 'castle');
		if (castle_rep) {
			expect(castle_rep.distance).toBeDefined();
			expect(castle_rep.distance).toBeGreaterThan(0);
		}
	});

	it('should include positions in result', () => {
		const text = 'The tower is old. The tower is tall.';
		const repetitions = detect_repetitions(text, default_config);

		const tower_rep = repetitions.find((r) => r.word === 'tower');
		if (tower_rep) {
			expect(tower_rep.positions.length).toBeGreaterThanOrEqual(2);
		}
	});

	it('should return empty array for no repetitions', () => {
		const text = 'The quick brown fox jumps over the lazy dog.';
		const repetitions = detect_repetitions(text, default_config);

		expect(repetitions.length).toBe(0);
	});

	it('should handle empty text', () => {
		const repetitions = detect_repetitions('', default_config);
		expect(repetitions).toEqual([]);
	});
});

describe('detect_weak_verbs', () => {
	it('should detect "was"', () => {
		const text = 'The cat was sleeping.';
		const weak_verbs = detect_weak_verbs(text);

		expect(weak_verbs.some((wv) => wv.verb === 'was')).toBe(true);
	});

	it('should detect "were"', () => {
		const text = 'They were happy.';
		const weak_verbs = detect_weak_verbs(text);

		expect(weak_verbs.some((wv) => wv.verb === 'were')).toBe(true);
	});

	it('should detect "is"', () => {
		const text = 'The dog is running.';
		const weak_verbs = detect_weak_verbs(text);

		expect(weak_verbs.some((wv) => wv.verb === 'is')).toBe(true);
	});

	it('should detect "felt"', () => {
		const text = 'She felt happy about it.';
		const weak_verbs = detect_weak_verbs(text);

		expect(weak_verbs.some((wv) => wv.verb === 'felt')).toBe(true);
	});

	it('should detect "seemed"', () => {
		const text = 'He seemed tired after work.';
		const weak_verbs = detect_weak_verbs(text);

		expect(weak_verbs.some((wv) => wv.verb === 'seemed')).toBe(true);
	});

	it('should detect "looked"', () => {
		const text = 'The house looked old.';
		const weak_verbs = detect_weak_verbs(text);

		expect(weak_verbs.some((wv) => wv.verb === 'looked')).toBe(true);
	});

	it('should include context', () => {
		const text = 'The old house was very large and imposing.';
		const weak_verbs = detect_weak_verbs(text);

		const was_verb = weak_verbs.find((wv) => wv.verb === 'was');
		expect(was_verb?.context).toBeDefined();
		expect(was_verb?.context.length).toBeGreaterThan(0);
	});

	it('should include position', () => {
		const text = 'He was happy.';
		const weak_verbs = detect_weak_verbs(text);

		const was_verb = weak_verbs.find((wv) => wv.verb === 'was');
		expect(was_verb?.position).toBeDefined();
		expect(was_verb?.position).toBeGreaterThanOrEqual(0);
	});

	it('should return empty array for no weak verbs', () => {
		const text = 'The cat ran quickly across the yard.';
		const weak_verbs = detect_weak_verbs(text);

		expect(weak_verbs.length).toBe(0);
	});

	it('should handle empty text', () => {
		const weak_verbs = detect_weak_verbs('');
		expect(weak_verbs).toEqual([]);
	});

	it('should detect multiple weak verbs', () => {
		const text = 'He was tired and she was hungry. They were both sad.';
		const weak_verbs = detect_weak_verbs(text);

		expect(weak_verbs.length).toBeGreaterThanOrEqual(3);
	});
});

describe('get_word_frequency', () => {
	it('should count word occurrences accurately', () => {
		const text = 'the cat and the dog and the bird';
		const frequency = get_word_frequency(text);

		expect(frequency.get('the')).toBe(3);
		expect(frequency.get('and')).toBe(2);
		expect(frequency.get('cat')).toBe(1);
	});

	it('should be case insensitive', () => {
		const text = 'The THE the';
		const frequency = get_word_frequency(text);

		expect(frequency.get('the')).toBe(3);
	});

	it('should return empty map for empty text', () => {
		const frequency = get_word_frequency('');
		expect(frequency.size).toBe(0);
	});

	it('should handle single word', () => {
		const frequency = get_word_frequency('hello');
		expect(frequency.get('hello')).toBe(1);
	});

	it('should handle punctuation', () => {
		const text = 'Hello, hello! Hello?';
		const frequency = get_word_frequency(text);

		expect(frequency.get('hello')).toBe(3);
	});
});

describe('get_overused_words', () => {
	it('should return words used more than twice', () => {
		const text = 'The castle stood tall. The castle was old. The castle had towers.';
		const overused = get_overused_words(text);

		expect(overused.some((w) => w.word === 'castle')).toBe(true);
	});

	it('should not include common words', () => {
		const text = 'The the the and and and but but but.';
		const overused = get_overused_words(text);

		expect(overused.find((w) => w.word === 'the')).toBeUndefined();
		expect(overused.find((w) => w.word === 'and')).toBeUndefined();
	});

	it('should not include short words', () => {
		const text = 'The cat cat cat cat sat.';
		const overused = get_overused_words(text);

		// "cat" is only 3 characters
		expect(overused.find((w) => w.word === 'cat')).toBeUndefined();
	});

	it('should include count', () => {
		const text = 'The tower tower tower tower.';
		const overused = get_overused_words(text);

		const tower = overused.find((w) => w.word === 'tower');
		if (tower) {
			expect(tower.count).toBe(4);
		}
	});

	it('should include percentage', () => {
		const text = 'The beautiful beautiful beautiful day.';
		const overused = get_overused_words(text);

		const beautiful = overused.find((w) => w.word === 'beautiful');
		if (beautiful) {
			expect(beautiful.percentage).toBeDefined();
			expect(beautiful.percentage).toBeGreaterThan(0);
		}
	});

	it('should sort by count descending', () => {
		const text = 'alpha alpha alpha beta beta beta beta gamma gamma gamma gamma gamma.';
		const overused = get_overused_words(text);

		if (overused.length >= 2) {
			expect(overused[0].count).toBeGreaterThanOrEqual(overused[1].count);
		}
	});

	it('should respect limit parameter', () => {
		const text = 'one one one two two two three three three four four four five five five.';
		const overused = get_overused_words(text, 3);

		expect(overused.length).toBeLessThanOrEqual(3);
	});

	it('should return empty array for no overused words', () => {
		const text = 'The quick brown fox.';
		const overused = get_overused_words(text);

		expect(overused.length).toBe(0);
	});
});
