import { describe, it, expect } from 'bun:test';
import {
	parse_sentences,
	analyze_sentences,
	analyze_sentence_starters,
	calculate_dialogue_percentage
} from './sentence_analysis.js';

describe('parse_sentences', () => {
	it('should parse basic sentences with position tracking', () => {
		const text = 'Hello world. How are you.';
		const sentences = parse_sentences(text);

		expect(sentences.length).toBe(2);
		expect(sentences[0].text).toBe('Hello world');
		expect(sentences[0].start).toBe(0);
	});

	it('should track word counts', () => {
		const text = 'The quick brown fox jumps.';
		const sentences = parse_sentences(text);

		expect(sentences[0].word_count).toBe(5);
	});

	it('should track first word', () => {
		const text = 'The cat sat. A dog ran.';
		const sentences = parse_sentences(text);

		expect(sentences[0].first_word).toBe('the');
		expect(sentences[1].first_word).toBe('a');
	});

	it('should handle empty text', () => {
		const sentences = parse_sentences('');
		expect(sentences).toEqual([]);
	});

	it('should track end position', () => {
		const text = 'Hello. World.';
		const sentences = parse_sentences(text);

		expect(sentences[0].end).toBe(sentences[0].start + sentences[0].text.length);
	});

	it('should handle multiple sentences', () => {
		const text = 'First sentence. Second sentence. Third sentence.';
		const sentences = parse_sentences(text);

		expect(sentences.length).toBe(3);
	});
});

describe('analyze_sentences', () => {
	it('should calculate count correctly', () => {
		const text = 'One. Two. Three.';
		const stats = analyze_sentences(text);

		expect(stats.count).toBe(3);
	});

	it('should calculate average length', () => {
		const text = 'One two. Three four.'; // 2 words each
		const stats = analyze_sentences(text);

		expect(stats.avg_length).toBe(2);
	});

	it('should find min length', () => {
		const text = 'Short. A longer sentence here.';
		const stats = analyze_sentences(text);

		expect(stats.min_length).toBe(1);
	});

	it('should find max length', () => {
		const text = 'Short. A much longer sentence with more words here.';
		const stats = analyze_sentences(text);

		expect(stats.max_length).toBeGreaterThan(1);
	});

	it('should calculate standard deviation', () => {
		const text = 'Short. A very long sentence with many words indeed.';
		const stats = analyze_sentences(text);

		expect(stats.std_deviation).toBeGreaterThan(0);
	});

	it('should track longest sentence', () => {
		const text = 'Short one. This is a much longer sentence with more words.';
		const stats = analyze_sentences(text);

		expect(stats.longest.length).toBeGreaterThan(2);
		expect(stats.longest.text.length).toBeGreaterThan(0);
	});

	it('should track shortest sentence', () => {
		const text = 'Hi. This is a longer sentence.';
		const stats = analyze_sentences(text);

		expect(stats.shortest.length).toBeLessThanOrEqual(stats.longest.length);
	});

	it('should count too long sentences', () => {
		// Create a sentence with more than 30 words
		const long_sentence = Array(35).fill('word').join(' ') + '.';
		const text = 'Short sentence. ' + long_sentence;
		const stats = analyze_sentences(text);

		expect(stats.too_long_count).toBeGreaterThanOrEqual(1);
	});

	it('should count too short sentences', () => {
		const text = 'Hi. Hello. A longer sentence here.';
		const stats = analyze_sentences(text);

		// "Hi" and "Hello" are less than 5 words
		expect(stats.too_short_count).toBeGreaterThanOrEqual(2);
	});

	it('should handle empty text', () => {
		const stats = analyze_sentences('');

		expect(stats.count).toBe(0);
		expect(stats.avg_length).toBe(0);
	});

	it('should calculate variety score', () => {
		const text = 'Short one. Medium length here. A very long sentence with many words.';
		const stats = analyze_sentences(text);

		expect(stats.variety_score).toBeGreaterThanOrEqual(0);
		expect(stats.variety_score).toBeLessThanOrEqual(100);
	});
});

describe('analyze_sentence_starters', () => {
	it('should count sentence starters', () => {
		const text = 'The cat sat. The dog ran. A bird flew.';
		const stats = analyze_sentence_starters(text);

		expect(stats.starters['the']).toBe(2);
		expect(stats.starters['a']).toBe(1);
	});

	it('should find most common starter', () => {
		const text = 'The cat sat. The dog ran. The bird flew.';
		const stats = analyze_sentence_starters(text);

		expect(stats.most_common.word).toBe('the');
		expect(stats.most_common.count).toBe(3);
	});

	it('should detect overused starters', () => {
		const text = 'He walked. He ran. He jumped. He swam. He flew. He danced. He sang.';
		const stats = analyze_sentence_starters(text);

		expect(stats.overused.some((o) => o.word === 'he')).toBe(true);
	});

	it('should calculate variety score', () => {
		const text = 'The cat. A dog. One bird. Some fish. Many bees.';
		const stats = analyze_sentence_starters(text);

		expect(stats.variety_score).toBeGreaterThan(0);
	});

	it('should include percentage in overused', () => {
		const text = 'She walked. She ran. She jumped. She danced. She sang.';
		const stats = analyze_sentence_starters(text);

		if (stats.overused.length > 0) {
			expect(stats.overused[0].percentage).toBeDefined();
		}
	});

	it('should sort overused by count descending', () => {
		const text = 'A one. A two. A three. B one. B two. C one.';
		const stats = analyze_sentence_starters(text);

		if (stats.overused.length >= 2) {
			expect(stats.overused[0].count).toBeGreaterThanOrEqual(stats.overused[1].count);
		}
	});

	it('should handle empty text', () => {
		const stats = analyze_sentence_starters('');

		expect(stats.starters).toEqual({});
		expect(stats.most_common.word).toBe('');
		expect(stats.most_common.count).toBe(0);
	});
});

describe('calculate_dialogue_percentage', () => {
	it('should detect standard double quotes', () => {
		const text = 'He said "Hello there" to her.';
		const percentage = calculate_dialogue_percentage(text);

		expect(percentage).toBeGreaterThan(0);
	});

	it('should detect smart double quotes', () => {
		const text = 'She replied "How are you" kindly.';
		const percentage = calculate_dialogue_percentage(text);

		expect(percentage).toBeGreaterThan(0);
	});

	it('should detect single quotes', () => {
		const text = "He whispered 'Be quiet' softly.";
		const percentage = calculate_dialogue_percentage(text);

		expect(percentage).toBeGreaterThan(0);
	});

	it('should return 0 for no dialogue', () => {
		const text = 'The cat sat on the mat.';
		const percentage = calculate_dialogue_percentage(text);

		expect(percentage).toBe(0);
	});

	it('should return 0 for empty text', () => {
		const percentage = calculate_dialogue_percentage('');

		expect(percentage).toBe(0);
	});

	it('should calculate reasonable percentage for mixed content', () => {
		const text = 'John walked in. "Hello," he said. Mary looked up.';
		const percentage = calculate_dialogue_percentage(text);

		expect(percentage).toBeGreaterThan(0);
		expect(percentage).toBeLessThan(100);
	});

	it('should handle multiple dialogue segments', () => {
		const text = '"First quote." Some narration. "Second quote."';
		const percentage = calculate_dialogue_percentage(text);

		expect(percentage).toBeGreaterThan(0);
	});

	it('should calculate high percentage for mostly dialogue', () => {
		const text = '"This is all dialogue," she said. "More dialogue here."';
		const percentage = calculate_dialogue_percentage(text);

		expect(percentage).toBeGreaterThan(30);
	});
});
