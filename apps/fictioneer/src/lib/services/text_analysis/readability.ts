/**
 * Readability score calculations
 * Implements Flesch Reading Ease, Flesch-Kincaid Grade Level, and ARI
 */

import type { ReadabilityScores } from '../../types/analysis.js';
import { count_total_syllables, extract_words } from './syllable_counter.js';

/**
 * Split text into sentences
 * Handles common abbreviations and edge cases
 */
export function split_into_sentences(text: string): string[] {
	// Common abbreviations that don't end sentences
	const abbreviations = [
		'Mr',
		'Mrs',
		'Ms',
		'Dr',
		'Prof',
		'Sr',
		'Jr',
		'vs',
		'etc',
		'i.e',
		'e.g',
		'St',
		'Lt',
		'Gen',
		'Col',
		'Sgt',
		'Rev',
		'Inc',
		'Ltd',
		'Corp',
		'Co',
		'No',
		'Vol',
		'Ch',
		'Pg',
		'Fig'
	];

	// Protect abbreviations by replacing their periods temporarily
	let processed = text;
	for (const abbr of abbreviations) {
		const regex = new RegExp(`\\b${abbr}\\.`, 'gi');
		processed = processed.replace(regex, `${abbr}<<<DOT>>>`);
	}

	// Protect decimal numbers
	processed = processed.replace(/(\d)\.(\d)/g, '$1<<<DOT>>>$2');

	// Protect ellipsis
	processed = processed.replace(/\.{3}/g, '<<<ELLIPSIS>>>');

	// Split on sentence-ending punctuation followed by space and capital letter
	// or end of string
	const sentenceEnders = /([.!?]+)\s+(?=[A-Z])|([.!?]+)\s*$/g;
	const sentences = processed
		.split(sentenceEnders)
		.filter((s) => s && s.trim().length > 0 && !/^[.!?]+$/.test(s.trim()));

	// Restore protected characters and clean up
	return sentences.map((s) =>
		s
			.replace(/<<<DOT>>>/g, '.')
			.replace(/<<<ELLIPSIS>>>/g, '...')
			.trim()
	);
}

/**
 * Calculate Flesch Reading Ease score
 * Formula: 206.835 - 1.015 * (words/sentences) - 84.6 * (syllables/words)
 *
 * Score interpretation:
 * 90-100: Very Easy (5th grade)
 * 80-89: Easy (6th grade)
 * 70-79: Fairly Easy (7th grade)
 * 60-69: Standard (8th-9th grade)
 * 50-59: Fairly Difficult (10th-12th grade)
 * 30-49: Difficult (College)
 * 0-29: Very Difficult (College Graduate)
 */
export function calculate_flesch_reading_ease(
	total_words: number,
	total_sentences: number,
	total_syllables: number
): number {
	if (total_words === 0 || total_sentences === 0) {
		return 0;
	}

	const words_per_sentence = total_words / total_sentences;
	const syllables_per_word = total_syllables / total_words;

	const score = 206.835 - 1.015 * words_per_sentence - 84.6 * syllables_per_word;

	// Clamp between 0 and 100
	return Math.max(0, Math.min(100, Math.round(score * 10) / 10));
}

/**
 * Calculate Flesch-Kincaid Grade Level
 * Formula: 0.39 * (words/sentences) + 11.8 * (syllables/words) - 15.59
 *
 * Result corresponds to US school grade level
 */
export function calculate_flesch_kincaid_grade(
	total_words: number,
	total_sentences: number,
	total_syllables: number
): number {
	if (total_words === 0 || total_sentences === 0) {
		return 0;
	}

	const words_per_sentence = total_words / total_sentences;
	const syllables_per_word = total_syllables / total_words;

	const grade = 0.39 * words_per_sentence + 11.8 * syllables_per_word - 15.59;

	// Clamp to reasonable range (0-18+)
	return Math.max(0, Math.round(grade * 10) / 10);
}

/**
 * Calculate Automated Readability Index (ARI)
 * Formula: 4.71 * (characters/words) + 0.5 * (words/sentences) - 21.43
 *
 * Result corresponds to US school grade level
 */
export function calculate_automated_readability_index(
	total_characters: number,
	total_words: number,
	total_sentences: number
): number {
	if (total_words === 0 || total_sentences === 0) {
		return 0;
	}

	const characters_per_word = total_characters / total_words;
	const words_per_sentence = total_words / total_sentences;

	const ari = 4.71 * characters_per_word + 0.5 * words_per_sentence - 21.43;

	// Clamp to reasonable range
	return Math.max(0, Math.round(ari * 10) / 10);
}

/**
 * Get reading level category from Flesch Reading Ease score
 */
function get_reading_level(
	flesch_score: number
): 'very_easy' | 'easy' | 'moderate' | 'difficult' | 'very_difficult' {
	if (flesch_score >= 80) return 'very_easy';
	if (flesch_score >= 60) return 'easy';
	if (flesch_score >= 40) return 'moderate';
	if (flesch_score >= 20) return 'difficult';
	return 'very_difficult';
}

/**
 * Generate human-readable interpretation of readability scores
 */
function get_interpretation(flesch_score: number, grade_level: number): string {
	const grade_text =
		grade_level <= 5
			? '5th grade or below'
			: grade_level <= 8
				? `${Math.round(grade_level)}th grade`
				: grade_level <= 12
					? `${Math.round(grade_level)}th grade (high school)`
					: 'college level';

	if (flesch_score >= 80) {
		return `Very easy to read. ${grade_text}. Suitable for a wide audience.`;
	} else if (flesch_score >= 60) {
		return `Easy to read. ${grade_text}. Good for most adult fiction.`;
	} else if (flesch_score >= 40) {
		return `Moderate difficulty. ${grade_text}. May challenge some readers.`;
	} else if (flesch_score >= 20) {
		return `Difficult to read. ${grade_text}. Dense prose or complex sentences.`;
	} else {
		return `Very difficult to read. ${grade_text}. Consider simplifying.`;
	}
}

/**
 * Calculate all readability scores for a text
 * @param text - Plain text to analyze (HTML should be stripped first)
 * @returns Complete readability scores
 */
export function calculate_readability_scores(text: string): ReadabilityScores {
	// Extract basic metrics
	const words = extract_words(text);
	const sentences = split_into_sentences(text);
	const total_syllables = count_total_syllables(text);

	const total_words = words.length;
	const total_sentences = Math.max(1, sentences.length); // Avoid division by zero

	// Count characters (letters only, for ARI)
	const total_characters = words.reduce((sum, word) => sum + word.length, 0);

	// Calculate scores
	const flesch_reading_ease = calculate_flesch_reading_ease(
		total_words,
		total_sentences,
		total_syllables
	);

	const flesch_kincaid_grade = calculate_flesch_kincaid_grade(
		total_words,
		total_sentences,
		total_syllables
	);

	const automated_readability_index = calculate_automated_readability_index(
		total_characters,
		total_words,
		total_sentences
	);

	return {
		flesch_reading_ease,
		flesch_kincaid_grade,
		automated_readability_index,
		interpretation: get_interpretation(flesch_reading_ease, flesch_kincaid_grade),
		level: get_reading_level(flesch_reading_ease)
	};
}

/**
 * Get reading level label for display
 */
export function get_reading_level_label(level: ReadabilityScores['level']): string {
	switch (level) {
		case 'very_easy':
			return 'Very Easy';
		case 'easy':
			return 'Easy';
		case 'moderate':
			return 'Moderate';
		case 'difficult':
			return 'Difficult';
		case 'very_difficult':
			return 'Very Difficult';
	}
}

/**
 * Get color class for reading level (for UI)
 */
export function get_reading_level_color(level: ReadabilityScores['level']): string {
	switch (level) {
		case 'very_easy':
			return 'text-green-500';
		case 'easy':
			return 'text-green-400';
		case 'moderate':
			return 'text-yellow-500';
		case 'difficult':
			return 'text-orange-500';
		case 'very_difficult':
			return 'text-red-500';
	}
}
