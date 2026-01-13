/**
 * Prose quality detection
 * Detects adverbs, passive voice, filter words, clichés, and vague words
 */

import type {
	AdverbMatch,
	PassiveVoiceMatch,
	FilterWordMatch,
	AnalysisHighlight,
	AnalysisConfig
} from '../../types/analysis.js';
import { split_into_sentences } from './readability.js';

/**
 * Common filter words that often weaken prose
 */
const FILTER_WORDS = [
	'just',
	'really',
	'very',
	'quite',
	'rather',
	'somewhat',
	'actually',
	'basically',
	'literally',
	'simply',
	'totally',
	'completely',
	'absolutely',
	'definitely',
	'certainly',
	'probably',
	'possibly',
	'maybe',
	'perhaps',
	'almost',
	'nearly',
	'hardly',
	'barely',
	'slightly',
	'kind of',
	'sort of',
	'a bit',
	'a little',
	'in order to',
	'start to',
	'begin to',
	'seem to',
	'appear to',
	'tend to'
];

/**
 * Common clichés in fiction writing
 */
const CLICHES = [
	'it was a dark and stormy night',
	'once upon a time',
	'in the nick of time',
	'all of a sudden',
	'at the end of the day',
	'the fact of the matter',
	'when all was said and done',
	'for all intents and purposes',
	'each and every',
	'first and foremost',
	'few and far between',
	'last but not least',
	'time will tell',
	'only time will tell',
	'easier said than done',
	'better late than never',
	'actions speak louder than words',
	'a needle in a haystack',
	'avoid like the plague',
	'beat around the bush',
	'bite the bullet',
	'break the ice',
	'burning the midnight oil',
	'crystal clear',
	'dead as a doornail',
	'fit as a fiddle',
	'heart of gold',
	'in the blink of an eye',
	'let the cat out of the bag',
	'once in a blue moon',
	'read between the lines',
	'scared to death',
	'sick and tired',
	'think outside the box',
	'tip of the iceberg',
	'under the weather',
	'white as a ghost',
	'white as a sheet',
	'her heart skipped a beat',
	'his heart pounded',
	'butterflies in her stomach',
	'a chill ran down his spine',
	'goosebumps rose on her skin',
	"he let out a breath he didn't know he was holding",
	"she let out a breath she didn't know she was holding",
	'time stood still',
	'the world fell away',
	'his blood ran cold',
	'her blood ran cold'
];

/**
 * Vague words that could be more specific
 */
const VAGUE_WORDS = [
	'thing',
	'things',
	'stuff',
	'something',
	'anything',
	'everything',
	'nothing',
	'someone',
	'anyone',
	'everyone',
	'somewhere',
	'anywhere',
	'everywhere',
	'somehow',
	'anyway',
	'whatever',
	'whenever',
	'wherever',
	'nice',
	'good',
	'bad',
	'big',
	'small',
	'great',
	'interesting',
	'beautiful',
	'ugly',
	'amazing',
	'awesome',
	'terrible',
	'horrible',
	'wonderful',
	'fantastic',
	'incredible'
];

/**
 * Words that often indicate passive voice when followed by past participle
 */
const PASSIVE_INDICATORS = [
	'was',
	'were',
	'is',
	'are',
	'been',
	'being',
	'be',
	'am',
	'get',
	'gets',
	'got',
	'getting'
];

/**
 * Common irregular past participles
 */
const IRREGULAR_PAST_PARTICIPLES = [
	'been',
	'done',
	'gone',
	'seen',
	'taken',
	'given',
	'known',
	'made',
	'found',
	'told',
	'left',
	'felt',
	'brought',
	'thought',
	'bought',
	'caught',
	'taught',
	'sought',
	'written',
	'driven',
	'eaten',
	'fallen',
	'forgotten',
	'chosen',
	'spoken',
	'stolen',
	'broken',
	'frozen',
	'hidden',
	'bitten',
	'beaten',
	'shaken',
	'taken',
	'woken',
	'worn',
	'torn',
	'sworn',
	'born',
	'borne',
	'drawn',
	'grown',
	'known',
	'shown',
	'thrown',
	'blown',
	'flown',
	'slain',
	'lain',
	'paid',
	'said',
	'sent',
	'spent',
	'built',
	'burnt',
	'dealt',
	'dreamt',
	'dwelt',
	'kept',
	'knelt',
	'leant',
	'leapt',
	'learnt',
	'meant',
	'slept',
	'smelt',
	'spelt',
	'spilt',
	'swept',
	'wept',
	'lost',
	'shot',
	'hurt',
	'cut',
	'put',
	'shut',
	'hit',
	'let',
	'set',
	'rid',
	'spread',
	'read',
	'held',
	'hung',
	'dug',
	'stuck',
	'struck',
	'stung',
	'swung',
	'clung',
	'flung',
	'slung',
	'sprung',
	'sung',
	'rung',
	'begun',
	'drunk',
	'shrunk',
	'sunk',
	'swum',
	'run',
	'won'
];

/**
 * Detect adverbs in text
 * Most English adverbs end in -ly, with some exceptions
 */
export function detect_adverbs(text: string): AdverbMatch[] {
	const results: AdverbMatch[] = [];
	const sentences = split_into_sentences(text);

	// Words ending in -ly that are NOT adverbs
	const exceptions = [
		'only',
		'early',
		'daily',
		'weekly',
		'monthly',
		'yearly',
		'holy',
		'lonely',
		'lovely',
		'ugly',
		'likely',
		'unlikely',
		'friendly',
		'family',
		'elderly',
		'orderly',
		'silly',
		'belly',
		'bully',
		'jelly',
		'jolly',
		'folly',
		'rally',
		'tally',
		'valley',
		'alley',
		'trolley',
		'volley',
		'pulley',
		'gully',
		'fully',
		'hilly',
		'chilly',
		'frilly',
		'smelly',
		'wooly',
		'curly',
		'burly',
		'surly',
		'pearly',
		'gnarly',
		'snarky',
		'italy',
		'assembly',
		'butterfly',
		'dragonfly',
		'firefly',
		'fly',
		'july',
		'reply',
		'supply',
		'apply',
		'multiply',
		'comply',
		'imply',
		'rely'
	];

	// Common adverbs that don't end in -ly
	const non_ly_adverbs = [
		'very',
		'really',
		'quite',
		'rather',
		'almost',
		'already',
		'also',
		'always',
		'never',
		'ever',
		'often',
		'seldom',
		'sometimes',
		'soon',
		'still',
		'yet',
		'just',
		'even',
		'too',
		'well',
		'fast',
		'hard',
		'late',
		'near',
		'far',
		'long',
		'low',
		'high',
		'straight',
		'right',
		'wrong',
		'much',
		'little',
		'enough',
		'anywhere',
		'everywhere',
		'nowhere',
		'somewhere',
		'somehow',
		'anyway',
		'perhaps',
		'maybe'
	];

	let text_position = 0;

	for (const sentence of sentences) {
		const sentence_start = text.indexOf(sentence, text_position);
		if (sentence_start === -1) continue;

		// Find -ly adverbs
		const ly_regex = /\b(\w+ly)\b/gi;
		let match;

		while ((match = ly_regex.exec(sentence)) !== null) {
			const word = match[1].toLowerCase();

			if (!exceptions.includes(word)) {
				results.push({
					word: match[1],
					position: sentence_start + match.index,
					sentence: sentence.trim()
				});
			}
		}

		// Find non-ly adverbs
		for (const adverb of non_ly_adverbs) {
			const adverb_regex = new RegExp(`\\b${adverb}\\b`, 'gi');
			while ((match = adverb_regex.exec(sentence)) !== null) {
				results.push({
					word: match[0],
					position: sentence_start + match.index,
					sentence: sentence.trim()
				});
			}
		}

		text_position = sentence_start + sentence.length;
	}

	return results;
}

/**
 * Check if a word is a past participle
 */
function is_past_participle(word: string): boolean {
	const lower = word.toLowerCase();

	// Check irregular past participles
	if (IRREGULAR_PAST_PARTICIPLES.includes(lower)) {
		return true;
	}

	// Regular past participles end in -ed
	if (lower.endsWith('ed') && lower.length > 3) {
		return true;
	}

	// Some end in -en
	if (lower.endsWith('en') && lower.length > 3) {
		return true;
	}

	return false;
}

/**
 * Detect passive voice constructions
 */
export function detect_passive_voice(text: string): PassiveVoiceMatch[] {
	const results: PassiveVoiceMatch[] = [];
	const sentences = split_into_sentences(text);

	let text_position = 0;

	for (const sentence of sentences) {
		const sentence_start = text.indexOf(sentence, text_position);
		if (sentence_start === -1) continue;

		// Pattern: auxiliary + (adverb)? + past participle
		// Examples: "was taken", "were being watched", "is often seen"
		for (const auxiliary of PASSIVE_INDICATORS) {
			const pattern = new RegExp(`\\b(${auxiliary})\\s+(\\w+ly\\s+)?(\\w+)\\b`, 'gi');

			let match;
			while ((match = pattern.exec(sentence)) !== null) {
				const aux = match[1];
				const adverb = match[2] || '';
				const participle = match[3];

				if (is_past_participle(participle)) {
					const full_phrase = `${aux} ${adverb}${participle}`.replace(/\s+/g, ' ').trim();

					results.push({
						phrase: full_phrase,
						position: sentence_start + match.index,
						suggestion: `Consider rewriting in active voice`,
						sentence: sentence.trim()
					});
				}
			}
		}

		text_position = sentence_start + sentence.length;
	}

	return results;
}

/**
 * Detect filter words
 */
export function detect_filter_words(text: string): FilterWordMatch[] {
	const results: FilterWordMatch[] = [];
	const lower_text = text.toLowerCase();

	for (const filter of FILTER_WORDS) {
		const escaped = filter.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
		const regex = new RegExp(`\\b${escaped}\\b`, 'gi');
		const matches: number[] = [];
		let match;

		while ((match = regex.exec(lower_text)) !== null) {
			matches.push(match.index);
		}

		if (matches.length > 0) {
			// Add each occurrence
			for (const position of matches) {
				results.push({
					word: filter,
					position,
					count: matches.length
				});
			}
		}
	}

	// Sort by position
	return results.sort((a, b) => a.position - b.position);
}

/**
 * Detect clichés
 */
export function detect_cliches(text: string): Array<{ phrase: string; position: number }> {
	const results: Array<{ phrase: string; position: number }> = [];
	const lower_text = text.toLowerCase();

	for (const cliche of CLICHES) {
		const escaped = cliche.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
		const regex = new RegExp(escaped, 'gi');
		let match;

		while ((match = regex.exec(lower_text)) !== null) {
			results.push({
				phrase: cliche,
				position: match.index
			});
		}
	}

	return results.sort((a, b) => a.position - b.position);
}

/**
 * Detect vague words
 */
export function detect_vague_words(text: string): Array<{ word: string; position: number }> {
	const results: Array<{ word: string; position: number }> = [];

	for (const vague of VAGUE_WORDS) {
		const regex = new RegExp(`\\b${vague}\\b`, 'gi');
		let match;

		while ((match = regex.exec(text)) !== null) {
			results.push({
				word: match[0],
				position: match.index
			});
		}
	}

	return results.sort((a, b) => a.position - b.position);
}

/**
 * Generate highlights for prose quality issues
 */
export function generate_prose_quality_highlights(
	text: string,
	config: AnalysisConfig
): AnalysisHighlight[] {
	const highlights: AnalysisHighlight[] = [];
	let id_counter = 0;

	// Detect adverbs
	const adverbs = detect_adverbs(text);
	for (const adverb of adverbs) {
		highlights.push({
			id: `adverb-${id_counter++}`,
			type: 'adverb',
			severity: 'info',
			start: adverb.position,
			end: adverb.position + adverb.word.length,
			text: adverb.word,
			message: `Adverb: "${adverb.word}" - Consider using a stronger verb instead`,
			suggestion: 'Try replacing with a more specific verb'
		});
	}

	// Detect passive voice
	const passives = detect_passive_voice(text);
	for (const passive of passives) {
		highlights.push({
			id: `passive-${id_counter++}`,
			type: 'passive_voice',
			severity: 'warning',
			start: passive.position,
			end: passive.position + passive.phrase.length,
			text: passive.phrase,
			message: `Passive voice: "${passive.phrase}" - Active voice is often stronger`,
			suggestion: passive.suggestion
		});
	}

	// Detect filter words
	const filters = detect_filter_words(text);
	for (const filter of filters) {
		highlights.push({
			id: `filter-${id_counter++}`,
			type: 'filter_word',
			severity: 'info',
			start: filter.position,
			end: filter.position + filter.word.length,
			text: filter.word,
			message: `Filter word: "${filter.word}" - Often unnecessary and weakens prose`,
			suggestion: 'Consider removing or finding a stronger alternative'
		});
	}

	// Detect clichés
	if (config.enable_cliche_detection) {
		const cliches = detect_cliches(text);
		for (const cliche of cliches) {
			highlights.push({
				id: `cliche-${id_counter++}`,
				type: 'cliche',
				severity: 'warning',
				start: cliche.position,
				end: cliche.position + cliche.phrase.length,
				text: cliche.phrase,
				message: `Cliché: "${cliche.phrase}" - Consider a more original expression`,
				suggestion: 'Try expressing this idea in your own unique way'
			});
		}
	}

	// Detect vague words
	if (config.enable_vague_word_detection) {
		const vagues = detect_vague_words(text);
		for (const vague of vagues) {
			highlights.push({
				id: `vague-${id_counter++}`,
				type: 'vague_word',
				severity: 'info',
				start: vague.position,
				end: vague.position + vague.word.length,
				text: vague.word,
				message: `Vague word: "${vague.word}" - Could be more specific`,
				suggestion: 'Consider using a more precise word'
			});
		}
	}

	// Sort by position
	return highlights.sort((a, b) => a.start - b.start);
}
