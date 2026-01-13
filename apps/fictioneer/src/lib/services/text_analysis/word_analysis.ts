/**
 * Word-level analysis
 * Detects word repetition, weak verbs, and overused words
 */

import type {
	WordRepetition,
	WeakVerbMatch,
	AnalysisHighlight,
	AnalysisConfig
} from '../../types/analysis.js';
import { extract_words } from './syllable_counter.js';

/**
 * Weak verbs that often indicate "telling" instead of "showing"
 */
const WEAK_VERBS = [
	'was',
	'were',
	'is',
	'are',
	'am',
	'be',
	'been',
	'being',
	'had',
	'has',
	'have',
	'do',
	'does',
	'did',
	'got',
	'get',
	'gets',
	'getting',
	'went',
	'go',
	'goes',
	'going',
	'came',
	'come',
	'comes',
	'coming',
	'made',
	'make',
	'makes',
	'making',
	'put',
	'puts',
	'putting',
	'took',
	'take',
	'takes',
	'taking',
	'felt',
	'feel',
	'feels',
	'feeling',
	'seemed',
	'seem',
	'seems',
	'seeming',
	'looked',
	'look',
	'looks',
	'looking',
	'said',
	'say',
	'says',
	'saying'
];

/**
 * Common words to ignore in repetition detection
 */
const COMMON_WORDS = new Set([
	// Articles
	'a',
	'an',
	'the',
	// Pronouns
	'i',
	'me',
	'my',
	'mine',
	'myself',
	'you',
	'your',
	'yours',
	'yourself',
	'he',
	'him',
	'his',
	'himself',
	'she',
	'her',
	'hers',
	'herself',
	'it',
	'its',
	'itself',
	'we',
	'us',
	'our',
	'ours',
	'ourselves',
	'they',
	'them',
	'their',
	'theirs',
	'themselves',
	'who',
	'whom',
	'whose',
	'which',
	'what',
	'that',
	'this',
	'these',
	'those',
	// Prepositions
	'in',
	'on',
	'at',
	'to',
	'for',
	'of',
	'with',
	'by',
	'from',
	'up',
	'down',
	'into',
	'out',
	'over',
	'under',
	'through',
	'between',
	'after',
	'before',
	'about',
	'around',
	'against',
	'among',
	// Conjunctions
	'and',
	'or',
	'but',
	'nor',
	'so',
	'yet',
	'if',
	'then',
	'than',
	'when',
	'while',
	'as',
	'because',
	'although',
	'though',
	'unless',
	'until',
	'since',
	// Common verbs (allowed to repeat)
	'was',
	'were',
	'is',
	'are',
	'am',
	'be',
	'been',
	'being',
	'had',
	'has',
	'have',
	'do',
	'does',
	'did',
	'would',
	'could',
	'should',
	'might',
	'must',
	'will',
	'shall',
	'can',
	'may',
	// Other common words
	'not',
	'no',
	'yes',
	'all',
	'some',
	'any',
	'each',
	'every',
	'both',
	'few',
	'more',
	'most',
	'other',
	'such',
	'only',
	'just',
	'also',
	'very',
	'too',
	'even',
	'still',
	'again',
	'now',
	'here',
	'there',
	'where',
	'how',
	'why',
	'said',
	'like'
]);

/**
 * Information about a word occurrence
 */
interface WordOccurrence {
	word: string;
	position: number;
	word_index: number;
}

/**
 * Extract words with their positions in the original text
 */
function extract_words_with_positions(text: string): WordOccurrence[] {
	const results: WordOccurrence[] = [];
	const regex = /\b([a-zA-Z]+(?:'[a-zA-Z]+)?)\b/g;
	let match;
	let word_index = 0;

	while ((match = regex.exec(text)) !== null) {
		results.push({
			word: match[1].toLowerCase(),
			position: match.index,
			word_index
		});
		word_index++;
	}

	return results;
}

/**
 * Detect word repetitions within a specified distance
 */
export function detect_repetitions(text: string, config: AnalysisConfig): WordRepetition[] {
	const words = extract_words_with_positions(text);
	const repetitions: WordRepetition[] = [];

	// Track recent words within the distance window
	const recent_words: Map<string, WordOccurrence[]> = new Map();

	for (const current of words) {
		// Skip short words and common words
		if (current.word.length < config.repetition_min_word_length || COMMON_WORDS.has(current.word)) {
			continue;
		}

		// Check if this word appeared recently
		const previous_occurrences = recent_words.get(current.word) || [];

		for (const prev of previous_occurrences) {
			const distance = current.word_index - prev.word_index;

			if (distance <= config.repetition_distance && distance > 0) {
				// Check if we already have this repetition
				const existing = repetitions.find(
					(r) => r.word === current.word && r.positions.includes(prev.position)
				);

				if (existing) {
					// Add this position to existing repetition
					if (!existing.positions.includes(current.position)) {
						existing.positions.push(current.position);
					}
				} else {
					// Create new repetition
					repetitions.push({
						word: current.word,
						positions: [prev.position, current.position],
						distance
					});
				}
			}
		}

		// Add current to recent words
		if (!recent_words.has(current.word)) {
			recent_words.set(current.word, []);
		}
		recent_words.get(current.word)!.push(current);

		// Clean up old entries outside the window
		for (const [word, occurrences] of recent_words.entries()) {
			const filtered = occurrences.filter(
				(o) => current.word_index - o.word_index <= config.repetition_distance
			);
			if (filtered.length === 0) {
				recent_words.delete(word);
			} else {
				recent_words.set(word, filtered);
			}
		}
	}

	return repetitions;
}

/**
 * Detect weak verbs
 */
export function detect_weak_verbs(text: string): WeakVerbMatch[] {
	const results: WeakVerbMatch[] = [];
	const words = extract_words_with_positions(text);

	for (let i = 0; i < words.length; i++) {
		const word = words[i];

		if (WEAK_VERBS.includes(word.word)) {
			// Get context (5 words before and after)
			const context_start = Math.max(0, i - 5);
			const context_end = Math.min(words.length, i + 6);
			const context_words = words.slice(context_start, context_end).map((w) => w.word);
			const context = context_words.join(' ');

			results.push({
				verb: word.word,
				position: word.position,
				context
			});
		}
	}

	return results;
}

/**
 * Get word frequency count
 */
export function get_word_frequency(text: string): Map<string, number> {
	const words = extract_words(text);
	const frequency: Map<string, number> = new Map();

	for (const word of words) {
		const lower = word.toLowerCase();
		frequency.set(lower, (frequency.get(lower) || 0) + 1);
	}

	return frequency;
}

/**
 * Get most frequently used words (excluding common words)
 */
export function get_overused_words(
	text: string,
	limit: number = 10
): Array<{ word: string; count: number; percentage: number }> {
	const frequency = get_word_frequency(text);
	const total_words = extract_words(text).length;
	const results: Array<{ word: string; count: number; percentage: number }> = [];

	for (const [word, count] of frequency.entries()) {
		// Skip common words and short words
		if (COMMON_WORDS.has(word) || word.length < 4) {
			continue;
		}

		// Only include words used more than twice
		if (count > 2) {
			results.push({
				word,
				count,
				percentage: Math.round((count / total_words) * 1000) / 10
			});
		}
	}

	// Sort by count descending
	results.sort((a, b) => b.count - a.count);

	return results.slice(0, limit);
}

/**
 * Generate highlights for word-level issues
 */
export function generate_word_highlights(
	text: string,
	config: AnalysisConfig
): AnalysisHighlight[] {
	const highlights: AnalysisHighlight[] = [];
	let id_counter = 0;

	// Detect repetitions
	const repetitions = detect_repetitions(text, config);

	for (const repetition of repetitions) {
		// Highlight each occurrence
		for (let i = 0; i < repetition.positions.length; i++) {
			const position = repetition.positions[i];
			const is_first = i === 0;

			highlights.push({
				id: `repetition-${id_counter++}`,
				type: 'repetition',
				severity: 'info',
				start: position,
				end: position + repetition.word.length,
				text: repetition.word,
				message: is_first
					? `"${repetition.word}" appears again within ${repetition.distance} words`
					: `Repeated word: "${repetition.word}" - ${repetition.distance} words from previous use`,
				suggestion: 'Consider using a synonym or restructuring the sentence'
			});
		}
	}

	// Detect weak verbs (but don't flag all of them - too noisy)
	// Only flag when density is high
	const weak_verbs = detect_weak_verbs(text);
	const total_words = extract_words(text).length;
	const weak_verb_percentage = (weak_verbs.length / total_words) * 100;

	// Only highlight weak verbs if they're particularly dense (>15%)
	if (weak_verb_percentage > 15) {
		// Just highlight a sample (every 3rd one)
		for (let i = 0; i < weak_verbs.length; i += 3) {
			const wv = weak_verbs[i];
			highlights.push({
				id: `weak-verb-${id_counter++}`,
				type: 'weak_verb',
				severity: 'info',
				start: wv.position,
				end: wv.position + wv.verb.length,
				text: wv.verb,
				message: `Weak verb "${wv.verb}" - Consider using a more specific action verb`,
				suggestion: 'Replace with a stronger, more descriptive verb'
			});
		}
	}

	return highlights;
}
