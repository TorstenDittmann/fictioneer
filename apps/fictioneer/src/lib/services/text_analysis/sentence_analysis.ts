/**
 * Sentence analysis
 * Analyzes sentence structure, length, variety, and starters
 */

import type {
	SentenceStats,
	SentenceStarterStats,
	AnalysisHighlight,
	AnalysisConfig
} from '../../types/analysis.js';
import { split_into_sentences } from './readability.js';
import { extract_words } from './syllable_counter.js';

/**
 * Get detailed information about each sentence
 */
export interface SentenceInfo {
	/** The sentence text */
	text: string;
	/** Start position in original text */
	start: number;
	/** End position in original text */
	end: number;
	/** Word count */
	word_count: number;
	/** First word (for starter analysis) */
	first_word: string;
}

/**
 * Parse text into sentence info objects
 */
export function parse_sentences(text: string): SentenceInfo[] {
	const sentences = split_into_sentences(text);
	const results: SentenceInfo[] = [];
	let search_position = 0;

	for (const sentence of sentences) {
		const trimmed = sentence.trim();
		if (!trimmed) continue;

		const start = text.indexOf(trimmed, search_position);
		if (start === -1) continue;

		const words = extract_words(trimmed);
		const first_word = words[0]?.toLowerCase() || '';

		results.push({
			text: trimmed,
			start,
			end: start + trimmed.length,
			word_count: words.length,
			first_word
		});

		search_position = start + trimmed.length;
	}

	return results;
}

/**
 * Calculate standard deviation
 */
function calculate_std_deviation(values: number[], mean: number): number {
	if (values.length === 0) return 0;

	const squared_diffs = values.map((v) => Math.pow(v - mean, 2));
	const avg_squared_diff = squared_diffs.reduce((a, b) => a + b, 0) / values.length;

	return Math.sqrt(avg_squared_diff);
}

/**
 * Calculate sentence variety score based on length distribution
 * Higher score = more varied sentence lengths
 */
function calculate_variety_score(lengths: number[]): number {
	if (lengths.length < 3) return 50; // Not enough data

	const mean = lengths.reduce((a, b) => a + b, 0) / lengths.length;
	const std_dev = calculate_std_deviation(lengths, mean);

	// Ideal std deviation is around 5-10 words
	// Too low = monotonous, too high = chaotic
	const ideal_std_dev = 7;
	const deviation_from_ideal = Math.abs(std_dev - ideal_std_dev);

	// Convert to 0-100 score
	// Perfect variety at ideal std dev, decreasing as it moves away
	const score = Math.max(0, 100 - deviation_from_ideal * 10);

	return Math.round(score);
}

/**
 * Analyze sentence statistics
 */
export function analyze_sentences(text: string): SentenceStats {
	const sentences = parse_sentences(text);

	if (sentences.length === 0) {
		return {
			count: 0,
			avg_length: 0,
			min_length: 0,
			max_length: 0,
			std_deviation: 0,
			variety_score: 0,
			longest: { length: 0, position: 0, text: '' },
			shortest: { length: 0, position: 0, text: '' },
			too_long_count: 0,
			too_short_count: 0
		};
	}

	const lengths = sentences.map((s) => s.word_count);
	const total_words = lengths.reduce((a, b) => a + b, 0);
	const avg_length = total_words / lengths.length;

	const min_length = Math.min(...lengths);
	const max_length = Math.max(...lengths);

	const std_deviation = calculate_std_deviation(lengths, avg_length);
	const variety_score = calculate_variety_score(lengths);

	// Find longest sentence
	const longest_index = lengths.indexOf(max_length);
	const longest = sentences[longest_index];

	// Find shortest sentence
	const shortest_index = lengths.indexOf(min_length);
	const shortest = sentences[shortest_index];

	// Count problematic sentences
	const too_long_count = lengths.filter((l) => l > 30).length;
	const too_short_count = lengths.filter((l) => l < 5 && l > 0).length;

	return {
		count: sentences.length,
		avg_length: Math.round(avg_length * 10) / 10,
		min_length,
		max_length,
		std_deviation: Math.round(std_deviation * 10) / 10,
		variety_score,
		longest: {
			length: longest.word_count,
			position: longest.start,
			text: longest.text.length > 100 ? longest.text.slice(0, 100) + '...' : longest.text
		},
		shortest: {
			length: shortest.word_count,
			position: shortest.start,
			text: shortest.text
		},
		too_long_count,
		too_short_count
	};
}

/**
 * Analyze sentence starters
 */
export function analyze_sentence_starters(text: string): SentenceStarterStats {
	const sentences = parse_sentences(text);

	if (sentences.length === 0) {
		return {
			starters: {},
			most_common: { word: '', count: 0 },
			variety_score: 0,
			overused: []
		};
	}

	// Count first words
	const starters: Record<string, number> = {};
	for (const sentence of sentences) {
		const first = sentence.first_word;
		if (first) {
			starters[first] = (starters[first] || 0) + 1;
		}
	}

	// Find most common
	let most_common = { word: '', count: 0 };
	for (const [word, count] of Object.entries(starters)) {
		if (count > most_common.count) {
			most_common = { word, count };
		}
	}

	// Calculate variety score
	// Based on how evenly distributed starters are
	const unique_starters = Object.keys(starters).length;
	const ideal_ratio = unique_starters / sentences.length;
	const variety_score = Math.round(Math.min(100, ideal_ratio * 100));

	// Find overused starters (>15% of sentences)
	const threshold = Math.max(2, sentences.length * 0.15);
	const overused: Array<{ word: string; count: number; percentage: number }> = [];

	for (const [word, count] of Object.entries(starters)) {
		if (count >= threshold) {
			overused.push({
				word,
				count,
				percentage: Math.round((count / sentences.length) * 100)
			});
		}
	}

	// Sort overused by count descending
	overused.sort((a, b) => b.count - a.count);

	return {
		starters,
		most_common,
		variety_score,
		overused
	};
}

/**
 * Generate highlights for sentence issues
 */
export function generate_sentence_highlights(
	text: string,
	config: AnalysisConfig
): AnalysisHighlight[] {
	const highlights: AnalysisHighlight[] = [];
	const sentences = parse_sentences(text);

	let id_counter = 0;

	// Check for long sentences
	for (const sentence of sentences) {
		if (sentence.word_count > config.max_sentence_length) {
			highlights.push({
				id: `long-sentence-${id_counter++}`,
				type: 'long_sentence',
				severity: 'warning',
				start: sentence.start,
				end: sentence.end,
				text: sentence.text.length > 50 ? sentence.text.slice(0, 50) + '...' : sentence.text,
				message: `Long sentence (${sentence.word_count} words) - Consider breaking into smaller sentences`,
				suggestion: 'Look for natural break points like conjunctions (and, but, or)'
			});
		}
	}

	// Group consecutive sentences with same starter
	let i = 0;
	while (i < sentences.length) {
		const current_starter = sentences[i].first_word;
		let consecutive_count = 1;
		let j = i + 1;

		// Count consecutive sentences with same starter
		while (j < sentences.length && sentences[j].first_word === current_starter) {
			consecutive_count++;
			j++;
		}

		// Flag if 3+ consecutive sentences start the same way
		if (consecutive_count >= 3) {
			for (let k = i; k < j; k++) {
				const sentence = sentences[k];
				const first_word_end = sentence.start + sentence.first_word.length;

				highlights.push({
					id: `starter-${id_counter++}`,
					type: 'sentence_starter',
					severity: 'info',
					start: sentence.start,
					end: first_word_end,
					text: sentence.first_word,
					message: `${consecutive_count} consecutive sentences start with "${current_starter}"`,
					suggestion: 'Vary your sentence openings for better flow'
				});
			}
		}

		i = j;
	}

	return highlights;
}

/**
 * Calculate dialogue percentage in text
 * Looks for text within quotation marks
 */
export function calculate_dialogue_percentage(text: string): number {
	// Match text within various quotation styles
	const dialogue_patterns = [
		/"[^"]*"/g, // Standard double quotes
		/'[^']*'/g, // Single quotes (for nested dialogue)
		/"[^"]*"/g, // Smart double quotes
		/'[^']*'/g // Smart single quotes
	];

	let dialogue_chars = 0;

	for (const pattern of dialogue_patterns) {
		const matches = text.match(pattern);
		if (matches) {
			for (const match of matches) {
				// Subtract 2 for the quote characters
				dialogue_chars += Math.max(0, match.length - 2);
			}
		}
	}

	const total_chars = text.replace(/\s/g, '').length;
	if (total_chars === 0) return 0;

	return Math.round((dialogue_chars / total_chars) * 100);
}
