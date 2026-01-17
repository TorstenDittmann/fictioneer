import { describe, it, expect } from 'bun:test';
import {
	split_into_sentences,
	calculate_flesch_reading_ease,
	calculate_flesch_kincaid_grade,
	calculate_automated_readability_index,
	calculate_readability_scores
} from './readability.js';

describe('split_into_sentences', () => {
	it('should split basic sentences', () => {
		const text = 'Hello world. How are you. I am fine.';
		const sentences = split_into_sentences(text);
		expect(sentences.length).toBe(3);
	});

	it('should handle question marks', () => {
		const text = 'How are you? I am fine.';
		const sentences = split_into_sentences(text);
		expect(sentences.length).toBe(2);
	});

	it('should handle exclamation marks', () => {
		const text = 'Hello! How are you?';
		const sentences = split_into_sentences(text);
		expect(sentences.length).toBe(2);
	});

	it('should handle Mr. abbreviation', () => {
		const text = 'Mr. Smith went to the store. He bought milk.';
		const sentences = split_into_sentences(text);
		expect(sentences.length).toBe(2);
	});

	it('should handle Dr. abbreviation', () => {
		const text = 'Dr. Jones is here. She will see you now.';
		const sentences = split_into_sentences(text);
		expect(sentences.length).toBe(2);
	});

	it('should handle Mrs. abbreviation', () => {
		const text = 'Mrs. Smith called. She left a message.';
		const sentences = split_into_sentences(text);
		expect(sentences.length).toBe(2);
	});

	it('should handle decimal numbers', () => {
		const text = 'The price is 3.50 dollars. That is cheap.';
		const sentences = split_into_sentences(text);
		expect(sentences.length).toBe(2);
	});

	it('should handle ellipsis', () => {
		const text = 'I wonder... What could it be. Let me think.';
		const sentences = split_into_sentences(text);
		expect(sentences.length).toBeGreaterThanOrEqual(2);
	});

	it('should handle quotes with sentence endings', () => {
		const text = 'She said "Hello." Then she left.';
		const sentences = split_into_sentences(text);
		expect(sentences.length).toBeGreaterThanOrEqual(1);
	});

	it('should handle multiple abbreviations', () => {
		const text = 'Mr. and Mrs. Smith visited Dr. Jones. It was a good visit.';
		const sentences = split_into_sentences(text);
		expect(sentences.length).toBe(2);
	});

	it('should handle e.g. abbreviation', () => {
		const text = 'Some animals, e.g. dogs, are pets. Cats are too.';
		const sentences = split_into_sentences(text);
		expect(sentences.length).toBe(2);
	});

	it('should handle i.e. abbreviation', () => {
		const text = 'The capital, i.e. London, is large. It has many people.';
		const sentences = split_into_sentences(text);
		expect(sentences.length).toBe(2);
	});

	it('should handle empty string', () => {
		expect(split_into_sentences('')).toEqual([]);
	});

	it('should handle single sentence without period', () => {
		const sentences = split_into_sentences('Hello world');
		expect(sentences.length).toBeGreaterThanOrEqual(1);
	});
});

describe('calculate_flesch_reading_ease', () => {
	it('should return 0 for zero words', () => {
		expect(calculate_flesch_reading_ease(0, 1, 0)).toBe(0);
	});

	it('should return 0 for zero sentences', () => {
		expect(calculate_flesch_reading_ease(10, 0, 15)).toBe(0);
	});

	it('should handle division by zero gracefully', () => {
		expect(calculate_flesch_reading_ease(0, 0, 0)).toBe(0);
	});

	it('should clamp result to maximum 100', () => {
		// Very simple text: many short sentences, few syllables
		const result = calculate_flesch_reading_ease(10, 10, 10);
		expect(result).toBeLessThanOrEqual(100);
	});

	it('should clamp result to minimum 0', () => {
		// Very complex text: very long sentences, many syllables
		const result = calculate_flesch_reading_ease(100, 1, 500);
		expect(result).toBeGreaterThanOrEqual(0);
	});

	it('should return typical range for normal text', () => {
		// Average sentence length ~15 words, ~1.5 syllables per word
		const result = calculate_flesch_reading_ease(150, 10, 225);
		expect(result).toBeGreaterThan(30);
		expect(result).toBeLessThan(80);
	});

	it('should return higher score for simpler text', () => {
		const simple = calculate_flesch_reading_ease(50, 10, 60); // Short sentences, few syllables
		const complex = calculate_flesch_reading_ease(50, 2, 100); // Long sentences, many syllables
		expect(simple).toBeGreaterThan(complex);
	});

	it('should round to one decimal place', () => {
		const result = calculate_flesch_reading_ease(100, 5, 150);
		const decimal_places = (result.toString().split('.')[1] || '').length;
		expect(decimal_places).toBeLessThanOrEqual(1);
	});
});

describe('calculate_flesch_kincaid_grade', () => {
	it('should return 0 for zero words', () => {
		expect(calculate_flesch_kincaid_grade(0, 1, 0)).toBe(0);
	});

	it('should return 0 for zero sentences', () => {
		expect(calculate_flesch_kincaid_grade(10, 0, 15)).toBe(0);
	});

	it('should clamp result to minimum 0', () => {
		const result = calculate_flesch_kincaid_grade(10, 10, 10);
		expect(result).toBeGreaterThanOrEqual(0);
	});

	it('should return higher grade for more complex text', () => {
		const simple = calculate_flesch_kincaid_grade(50, 10, 60);
		const complex = calculate_flesch_kincaid_grade(50, 2, 100);
		expect(complex).toBeGreaterThan(simple);
	});

	it('should return typical grade range for normal text', () => {
		const result = calculate_flesch_kincaid_grade(150, 10, 200);
		expect(result).toBeGreaterThan(0);
		expect(result).toBeLessThan(20);
	});

	it('should round to one decimal place', () => {
		const result = calculate_flesch_kincaid_grade(100, 5, 150);
		const decimal_places = (result.toString().split('.')[1] || '').length;
		expect(decimal_places).toBeLessThanOrEqual(1);
	});
});

describe('calculate_automated_readability_index', () => {
	it('should return 0 for zero words', () => {
		expect(calculate_automated_readability_index(50, 0, 1)).toBe(0);
	});

	it('should return 0 for zero sentences', () => {
		expect(calculate_automated_readability_index(50, 10, 0)).toBe(0);
	});

	it('should clamp result to minimum 0', () => {
		const result = calculate_automated_readability_index(20, 10, 10);
		expect(result).toBeGreaterThanOrEqual(0);
	});

	it('should return higher index for more complex text', () => {
		const simple = calculate_automated_readability_index(200, 50, 10);
		const complex = calculate_automated_readability_index(500, 50, 2);
		expect(complex).toBeGreaterThan(simple);
	});

	it('should use character/word ratio correctly', () => {
		// More characters per word = higher readability index
		const short_words = calculate_automated_readability_index(150, 50, 5); // 3 chars/word
		const long_words = calculate_automated_readability_index(350, 50, 5); // 7 chars/word
		expect(long_words).toBeGreaterThan(short_words);
	});

	it('should round to one decimal place', () => {
		const result = calculate_automated_readability_index(500, 100, 10);
		const decimal_places = (result.toString().split('.')[1] || '').length;
		expect(decimal_places).toBeLessThanOrEqual(1);
	});
});

describe('calculate_readability_scores', () => {
	it('should return all score components', () => {
		const text = 'The quick brown fox jumps over the lazy dog. It was a simple sentence.';
		const scores = calculate_readability_scores(text);

		expect(scores).toHaveProperty('flesch_reading_ease');
		expect(scores).toHaveProperty('flesch_kincaid_grade');
		expect(scores).toHaveProperty('automated_readability_index');
		expect(scores).toHaveProperty('interpretation');
		expect(scores).toHaveProperty('level');
	});

	it('should return numeric scores', () => {
		const text = 'This is a test. It is simple.';
		const scores = calculate_readability_scores(text);

		expect(typeof scores.flesch_reading_ease).toBe('number');
		expect(typeof scores.flesch_kincaid_grade).toBe('number');
		expect(typeof scores.automated_readability_index).toBe('number');
	});

	it('should return valid level', () => {
		const text = 'This is a simple test sentence.';
		const scores = calculate_readability_scores(text);

		expect(['very_easy', 'easy', 'moderate', 'difficult', 'very_difficult']).toContain(
			scores.level
		);
	});

	it('should return non-empty interpretation', () => {
		const text = 'The cat sat on the mat.';
		const scores = calculate_readability_scores(text);

		expect(scores.interpretation.length).toBeGreaterThan(0);
	});

	it('should handle empty text', () => {
		const scores = calculate_readability_scores('');
		expect(scores.flesch_reading_ease).toBe(0);
	});

	it('should handle single word', () => {
		const scores = calculate_readability_scores('Hello');
		expect(scores).toBeDefined();
	});

	it('should categorize simple text as easy', () => {
		const simple_text = 'The cat sat. The dog ran. The bird flew. It was fun. They played.';
		const scores = calculate_readability_scores(simple_text);

		expect(scores.flesch_reading_ease).toBeGreaterThan(60);
	});

	it('should categorize complex text as difficult', () => {
		const complex_text =
			'The implementation of sophisticated methodological frameworks necessitates comprehensive consideration of multifaceted theoretical constructs and epistemological paradigms that fundamentally characterize contemporary interdisciplinary scholarship.';
		const scores = calculate_readability_scores(complex_text);

		expect(scores.flesch_reading_ease).toBeLessThan(40);
	});
});
