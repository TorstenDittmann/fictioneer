/**
 * Syllable counter for readability calculations
 * Uses a rule-based approach with common exceptions
 */

/**
 * Common words with irregular syllable counts
 */
const SYLLABLE_OVERRIDES: Record<string, number> = {
	// Silent e words that might be miscounted
	awe: 1,
	eye: 1,
	oye: 1,
	// Common contractions
	"don't": 1,
	"won't": 1,
	"can't": 1,
	"didn't": 2,
	"wouldn't": 2,
	"couldn't": 2,
	"shouldn't": 2,
	"aren't": 1,
	"isn't": 2,
	"wasn't": 2,
	"weren't": 1,
	"haven't": 2,
	"hasn't": 2,
	"hadn't": 2,
	"they're": 1,
	"we're": 1,
	"you're": 1,
	"i'm": 1,
	"he's": 1,
	"she's": 1,
	"it's": 1,
	"that's": 1,
	"what's": 1,
	"there's": 1,
	"here's": 1,
	"where's": 1,
	"let's": 1,
	"who's": 1,
	"i'll": 1,
	"you'll": 1,
	"he'll": 1,
	"she'll": 1,
	"we'll": 1,
	"they'll": 1,
	"i've": 1,
	"you've": 1,
	"we've": 1,
	"they've": 1,
	"i'd": 1,
	"you'd": 1,
	"he'd": 1,
	"she'd": 1,
	"we'd": 1,
	"they'd": 1,
	// Commonly mispronounced/miscounted
	business: 2,
	every: 2,
	evening: 2,
	different: 2,
	chocolate: 2,
	comfortable: 3,
	interesting: 3,
	vegetable: 3,
	camera: 2,
	separate: 3,
	temperature: 3,
	literature: 3,
	actually: 3,
	naturally: 3,
	family: 2,
	really: 2,
	usually: 3,
	finally: 2,
	probably: 3,
	basically: 3,
	definitely: 4,
	especially: 4,
	particularly: 5,
	simultaneously: 5,
	fire: 1,
	hour: 1,
	our: 1,
	area: 3,
	idea: 3,
	real: 1,
	being: 2,
	seeing: 2,
	doing: 2,
	going: 2,
	poem: 2,
	poet: 2,
	poetry: 3,
	quiet: 2,
	science: 2,
	diet: 2,
	lion: 2,
	riot: 2,
	violent: 2,
	create: 2,
	created: 3,
	creating: 3,
	creature: 2
};

/**
 * Suffixes that add syllables
 */
const SYLLABLE_ADDING_SUFFIXES = [
	{ suffix: 'ious', add: 2 },
	{ suffix: 'eous', add: 2 },
	{ suffix: 'uous', add: 2 },
	{ suffix: 'ial', add: 2 },
	{ suffix: 'ual', add: 2 },
	{ suffix: 'ian', add: 2 },
	{ suffix: 'ium', add: 2 }
];

/**
 * Prefixes that form their own syllable
 */
const SYLLABIC_PREFIXES = ['mc', 're', 'pre', 'un', 'dis', 'mis', 'non', 'anti', 'semi', 'co'];

/**
 * Count syllables in a single word
 * @param word - The word to count syllables in
 * @returns Number of syllables
 */
export function count_syllables(word: string): number {
	// Normalize the word
	const normalized = word.toLowerCase().trim();

	// Handle empty strings
	if (!normalized || normalized.length === 0) {
		return 0;
	}

	// Check for overrides first
	if (SYLLABLE_OVERRIDES[normalized] !== undefined) {
		return SYLLABLE_OVERRIDES[normalized];
	}

	// Remove non-alphabetic characters except apostrophe
	const cleaned = normalized.replace(/[^a-z']/g, '');

	if (!cleaned || cleaned.length === 0) {
		return 0;
	}

	// Single letter words
	if (cleaned.length === 1) {
		return 1;
	}

	// Count using vowel groups as base
	let count = count_vowel_groups(cleaned);

	// Apply suffix adjustments
	count = adjust_for_suffixes(cleaned, count);

	// Apply prefix adjustments
	count = adjust_for_prefixes(cleaned, count);

	// Apply silent e rules
	count = adjust_for_silent_e(cleaned, count);

	// Ensure at least 1 syllable for any word
	return Math.max(1, count);
}

/**
 * Count vowel groups in a word
 * Each vowel group typically represents one syllable
 */
function count_vowel_groups(word: string): number {
	// Match sequences of vowels
	const vowelGroups = word.match(/[aeiouy]+/gi);
	return vowelGroups ? vowelGroups.length : 0;
}

/**
 * Adjust syllable count for common suffix patterns
 */
function adjust_for_suffixes(word: string, count: number): number {
	let adjusted = count;

	// Check special suffixes that add syllables
	for (const { suffix, add } of SYLLABLE_ADDING_SUFFIXES) {
		if (word.endsWith(suffix)) {
			// These suffixes are often counted as fewer vowel groups
			// but actually have more syllables
			const vowelsInSuffix = (suffix.match(/[aeiouy]+/gi) || []).length;
			adjusted = adjusted - vowelsInSuffix + add;
			break;
		}
	}

	// -ed ending adjustments
	if (word.endsWith('ed') && word.length > 2) {
		const beforeEd = word.charAt(word.length - 3);
		// -ed is silent after most consonants except t and d
		if (!/[aeiouytd]/.test(beforeEd)) {
			adjusted--;
		}
	}

	// -es ending adjustments
	if (word.endsWith('es') && word.length > 2) {
		const beforeEs = word.charAt(word.length - 3);
		// -es adds syllable after s, x, z, ch, sh
		if (!/[sxz]/.test(beforeEs) && !word.endsWith('ches') && !word.endsWith('shes')) {
			// Silent es in most cases
			if (/[^aeiou]/.test(beforeEs)) {
				adjusted--;
			}
		}
	}

	// -le ending (often syllabic: table, little)
	if (word.endsWith('le') && word.length > 2) {
		const beforeLe = word.charAt(word.length - 3);
		if (/[^aeiou]/.test(beforeLe)) {
			// Consonant + le is usually a syllable
			// but we've already counted the 'e', so no adjustment needed
		}
	}

	// -tion, -sion endings
	if (word.endsWith('tion') || word.endsWith('sion')) {
		// These are single syllables, not two
		adjusted--;
	}

	return adjusted;
}

/**
 * Adjust syllable count for prefix patterns
 */
function adjust_for_prefixes(word: string, count: number): number {
	// Some prefixes before consonants add a syllable
	for (const prefix of SYLLABIC_PREFIXES) {
		if (word.startsWith(prefix) && word.length > prefix.length) {
			const nextChar = word.charAt(prefix.length);
			// If prefix is followed by a consonant, it's likely its own syllable
			if (/[^aeiou]/.test(nextChar) && prefix !== 're') {
				// Most cases already counted correctly
			}
		}
	}

	return count;
}

/**
 * Adjust for silent 'e' at end of words
 */
function adjust_for_silent_e(word: string, count: number): number {
	let adjusted = count;

	// Silent e at end of word
	if (word.endsWith('e') && word.length > 2) {
		const beforeE = word.charAt(word.length - 2);
		// Silent e after consonant (not le, which is syllabic)
		if (/[^aeiou]/.test(beforeE) && !word.endsWith('le')) {
			adjusted--;
		}
	}

	// Words ending in -es where s makes it not silent
	if (word.endsWith('es') && word.length > 3) {
		const thirdFromEnd = word.charAt(word.length - 3);
		if (/[sxzh]/.test(thirdFromEnd) || word.endsWith('ches') || word.endsWith('shes')) {
			// -es is pronounced, add back
			adjusted++;
		}
	}

	return adjusted;
}

/**
 * Count total syllables in a text
 * @param text - The text to analyze
 * @returns Total syllable count
 */
export function count_total_syllables(text: string): number {
	const words = extract_words(text);
	let total = 0;

	for (const word of words) {
		total += count_syllables(word);
	}

	return total;
}

/**
 * Extract words from text, handling punctuation and contractions
 * @param text - The text to extract words from
 * @returns Array of words
 */
export function extract_words(text: string): string[] {
	// Match words including contractions and hyphenated words
	const matches = text.match(/[a-zA-Z]+(?:'[a-zA-Z]+)?(?:-[a-zA-Z]+)*/g);
	return matches || [];
}

/**
 * Get syllable count per word for a text
 * @param text - The text to analyze
 * @returns Array of {word, syllables} objects
 */
export function get_syllables_breakdown(text: string): Array<{ word: string; syllables: number }> {
	const words = extract_words(text);
	return words.map((word) => ({
		word,
		syllables: count_syllables(word)
	}));
}
