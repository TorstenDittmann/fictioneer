/**
 * Main text analysis service
 * Combines all analysis modules into a single interface
 */

import type {
	SceneAnalysisResult,
	AnalysisHighlight,
	AnalysisConfig,
	AnalysisIssue,
	ProseMetrics
} from '../../types/analysis.js';

import { extract_words } from './syllable_counter.js';
import { calculate_readability_scores } from './readability.js';
import {
	detect_adverbs,
	detect_passive_voice,
	detect_filter_words,
	detect_cliches,
	detect_vague_words,
	generate_prose_quality_highlights
} from './prose_quality.js';
import {
	analyze_sentences,
	analyze_sentence_starters,
	generate_sentence_highlights,
	calculate_dialogue_percentage
} from './sentence_analysis.js';
import {
	detect_repetitions,
	detect_weak_verbs,
	get_overused_words,
	generate_word_highlights
} from './word_analysis.js';

// Re-export for convenience
export { DEFAULT_ANALYSIS_CONFIG } from '../../types/analysis.js';
export type {
	SceneAnalysisResult,
	AnalysisHighlight,
	AnalysisConfig
} from '../../types/analysis.js';

/**
 * Strip HTML tags from text
 */
function strip_html(html: string): string {
	return html.replace(/<[^>]*>/g, '');
}

/**
 * Calculate overall prose quality score
 * Based on weighted combination of various metrics
 */
function calculate_overall_score(
	readability_score: number,
	sentence_variety: number,
	starter_variety: number,
	adverb_percentage: number,
	passive_percentage: number,
	filter_count: number,
	word_count: number
): number {
	// Start with base score
	let score = 70;

	// Readability contribution (0-15 points)
	// Ideal readability is 60-70 (standard fiction)
	const readability_contrib = readability_score >= 50 && readability_score <= 80 ? 15 : 10;
	score += readability_contrib - 10;

	// Sentence variety contribution (0-15 points)
	score += (sentence_variety / 100) * 15 - 7.5;

	// Starter variety contribution (0-10 points)
	score += (starter_variety / 100) * 10 - 5;

	// Adverb penalty (0 to -10 points)
	if (adverb_percentage > 2) {
		score -= Math.min(10, (adverb_percentage - 2) * 3);
	}

	// Passive voice penalty (0 to -10 points)
	if (passive_percentage > 15) {
		score -= Math.min(10, (passive_percentage - 15) * 0.5);
	}

	// Filter word penalty (0 to -5 points)
	const filter_percentage = (filter_count / Math.max(1, word_count)) * 100;
	if (filter_percentage > 1) {
		score -= Math.min(5, (filter_percentage - 1) * 2);
	}

	// Clamp to 0-100
	return Math.max(0, Math.min(100, Math.round(score)));
}

/**
 * Generate top issues from analysis
 */
function generate_top_issues(
	highlights: AnalysisHighlight[],
	metrics: ProseMetrics,
	config: AnalysisConfig
): AnalysisIssue[] {
	const issues: AnalysisIssue[] = [];

	// Count highlights by type
	const type_counts: Record<string, number> = {};
	for (const h of highlights) {
		type_counts[h.type] = (type_counts[h.type] || 0) + 1;
	}

	// Adverb issue
	if (metrics.adverb_percentage > config.max_adverb_percentage) {
		issues.push({
			type: 'adverb',
			severity: metrics.adverb_percentage > 3 ? 'warning' : 'info',
			message: `High adverb density (${metrics.adverb_percentage.toFixed(1)}%)`,
			count: metrics.adverb_count
		});
	}

	// Passive voice issue
	if (metrics.passive_voice_percentage > config.max_passive_percentage) {
		issues.push({
			type: 'passive_voice',
			severity: metrics.passive_voice_percentage > 20 ? 'warning' : 'info',
			message: `Frequent passive voice (${metrics.passive_voice_percentage.toFixed(1)}% of sentences)`,
			count: metrics.passive_voice_count
		});
	}

	// Filter word issue
	if (metrics.filter_word_count > 5) {
		issues.push({
			type: 'filter_word',
			severity: metrics.filter_word_count > 15 ? 'warning' : 'info',
			message: `${metrics.filter_word_count} filter words found`,
			count: metrics.filter_word_count
		});
	}

	// Repetition issue
	if (type_counts['repetition'] > 3) {
		issues.push({
			type: 'repetition',
			severity: type_counts['repetition'] > 10 ? 'warning' : 'info',
			message: `${type_counts['repetition']} word repetitions detected`,
			count: type_counts['repetition']
		});
	}

	// Long sentence issue
	if (type_counts['long_sentence'] > 2) {
		issues.push({
			type: 'long_sentence',
			severity: type_counts['long_sentence'] > 5 ? 'warning' : 'info',
			message: `${type_counts['long_sentence']} sentences exceed ${config.max_sentence_length} words`,
			count: type_counts['long_sentence']
		});
	}

	// Sentence starter issue
	if (type_counts['sentence_starter'] > 0) {
		issues.push({
			type: 'sentence_starter',
			severity: 'info',
			message: 'Some sentence starters are repetitive',
			count: type_counts['sentence_starter']
		});
	}

	// Cliché issue
	if (metrics.cliche_count > 0) {
		issues.push({
			type: 'cliche',
			severity: 'warning',
			message: `${metrics.cliche_count} cliché${metrics.cliche_count > 1 ? 's' : ''} detected`,
			count: metrics.cliche_count
		});
	}

	// Sort by severity and count
	const severity_order = { error: 0, warning: 1, info: 2 };
	issues.sort((a, b) => {
		const severity_diff = severity_order[a.severity] - severity_order[b.severity];
		if (severity_diff !== 0) return severity_diff;
		return b.count - a.count;
	});

	// Return top 5 issues
	return issues.slice(0, 5);
}

/**
 * Generate summary text
 */
function generate_summary(
	overall_score: number,
	top_issues: AnalysisIssue[],
	readability_level: string
): string {
	const parts: string[] = [];

	// Score assessment
	if (overall_score >= 80) {
		parts.push('Excellent prose quality');
	} else if (overall_score >= 60) {
		parts.push('Good prose quality');
	} else if (overall_score >= 40) {
		parts.push('Fair prose quality');
	} else {
		parts.push('Prose needs attention');
	}

	// Readability
	parts.push(`${readability_level} readability`);

	// Top issue
	if (top_issues.length > 0 && top_issues[0].severity !== 'info') {
		parts.push(top_issues[0].message.toLowerCase());
	}

	return parts.join('. ') + '.';
}

/**
 * Analyze a scene's text and return comprehensive results
 */
export function analyze_scene(
	html_content: string,
	config: AnalysisConfig = {
		min_sentence_length: 5,
		max_sentence_length: 30,
		max_adverb_percentage: 1.5,
		max_passive_percentage: 10,
		repetition_distance: 50,
		repetition_min_word_length: 5,
		enable_cliche_detection: true,
		enable_vague_word_detection: true
	}
): SceneAnalysisResult {
	// Strip HTML to get plain text
	const text = strip_html(html_content);

	// Basic counts
	const words = extract_words(text);
	const word_count = words.length;
	const character_count = text.length;

	// Calculate readability
	const readability = calculate_readability_scores(text);

	// Analyze sentences
	const sentences = analyze_sentences(text);
	const sentence_starters = analyze_sentence_starters(text);

	// Detect prose quality issues
	const adverbs = detect_adverbs(text);
	const passives = detect_passive_voice(text);
	const filters = detect_filter_words(text);
	const cliches = config.enable_cliche_detection ? detect_cliches(text) : [];
	const vagues = config.enable_vague_word_detection ? detect_vague_words(text) : [];
	const weak_verbs = detect_weak_verbs(text);

	// Calculate metrics
	const metrics: ProseMetrics = {
		adverb_percentage: word_count > 0 ? (adverbs.length / word_count) * 100 : 0,
		adverb_count: adverbs.length,
		passive_voice_percentage: sentences.count > 0 ? (passives.length / sentences.count) * 100 : 0,
		passive_voice_count: passives.length,
		filter_word_count: filters.length,
		weak_verb_count: weak_verbs.length,
		cliche_count: cliches.length,
		vague_word_count: vagues.length,
		dialogue_percentage: calculate_dialogue_percentage(text)
	};

	// Generate highlights
	const prose_highlights = generate_prose_quality_highlights(text, config);
	const sentence_highlights = generate_sentence_highlights(text, config);
	const word_highlights = generate_word_highlights(text, config);

	// Combine and sort all highlights
	const highlights = [...prose_highlights, ...sentence_highlights, ...word_highlights].sort(
		(a, b) => a.start - b.start
	);

	// Calculate overall score
	const overall_score = calculate_overall_score(
		readability.flesch_reading_ease,
		sentences.variety_score,
		sentence_starters.variety_score,
		metrics.adverb_percentage,
		metrics.passive_voice_percentage,
		metrics.filter_word_count,
		word_count
	);

	// Generate top issues
	const top_issues = generate_top_issues(highlights, metrics, config);

	// Generate summary
	const summary = generate_summary(
		overall_score,
		top_issues,
		readability.interpretation.split('.')[0]
	);

	return {
		word_count,
		character_count,
		readability,
		sentences,
		sentence_starters,
		metrics,
		highlights,
		overall_score,
		summary,
		top_issues,
		analyzed_at: new Date()
	};
}

/**
 * Quick analysis for real-time feedback (lighter weight)
 * Only calculates basic metrics without full highlights
 */
export function quick_analyze(html_content: string): {
	word_count: number;
	sentence_count: number;
	readability_score: number;
	readability_level: string;
} {
	const text = strip_html(html_content);
	const words = extract_words(text);
	const sentences = analyze_sentences(text);
	const readability = calculate_readability_scores(text);

	return {
		word_count: words.length,
		sentence_count: sentences.count,
		readability_score: readability.flesch_reading_ease,
		readability_level: readability.level
	};
}

/**
 * Get highlights for a specific type only
 */
export function get_highlights_by_type(
	html_content: string,
	type: AnalysisHighlight['type'],
	config: AnalysisConfig = {
		min_sentence_length: 5,
		max_sentence_length: 30,
		max_adverb_percentage: 1.5,
		max_passive_percentage: 10,
		repetition_distance: 50,
		repetition_min_word_length: 5,
		enable_cliche_detection: true,
		enable_vague_word_detection: true
	}
): AnalysisHighlight[] {
	const text = strip_html(html_content);

	switch (type) {
		case 'adverb':
		case 'passive_voice':
		case 'filter_word':
		case 'cliche':
		case 'vague_word':
			return generate_prose_quality_highlights(text, config).filter((h) => h.type === type);

		case 'long_sentence':
		case 'sentence_starter':
			return generate_sentence_highlights(text, config).filter((h) => h.type === type);

		case 'repetition':
		case 'weak_verb':
			return generate_word_highlights(text, config).filter((h) => h.type === type);

		default:
			return [];
	}
}

// Export individual analysis functions for granular use
export {
	calculate_readability_scores,
	analyze_sentences,
	analyze_sentence_starters,
	detect_adverbs,
	detect_passive_voice,
	detect_filter_words,
	detect_cliches,
	detect_vague_words,
	detect_repetitions,
	detect_weak_verbs,
	get_overused_words,
	calculate_dialogue_percentage
};
