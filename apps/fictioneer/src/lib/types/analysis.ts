/**
 * Text analysis type definitions for Fictioneer
 * Provides types for readability metrics, prose quality analysis, and inline highlights
 */

/**
 * Types of issues that can be highlighted in the editor
 */
export type HighlightType =
	| 'adverb'
	| 'passive_voice'
	| 'filter_word'
	| 'repetition'
	| 'weak_verb'
	| 'long_sentence'
	| 'sentence_starter'
	| 'cliche'
	| 'vague_word';

/**
 * Severity levels for analysis issues
 */
export type HighlightSeverity = 'info' | 'warning' | 'error';

/**
 * A single highlight that can be rendered inline in the editor
 */
export interface AnalysisHighlight {
	/** Unique identifier for this highlight */
	id: string;
	/** Type of issue detected */
	type: HighlightType;
	/** Severity level */
	severity: HighlightSeverity;
	/** Start character offset in plain text */
	start: number;
	/** End character offset in plain text */
	end: number;
	/** The actual text that was flagged */
	text: string;
	/** Human-readable message for tooltip */
	message: string;
	/** Optional suggestion for fixing the issue */
	suggestion?: string;
}

/**
 * Readability scores based on standard formulas
 */
export interface ReadabilityScores {
	/** Flesch Reading Ease score (0-100, higher = easier) */
	flesch_reading_ease: number;
	/** Flesch-Kincaid Grade Level (US school grade) */
	flesch_kincaid_grade: number;
	/** Automated Readability Index */
	automated_readability_index: number;
	/** Human-readable interpretation */
	interpretation: string;
	/** Reading level category */
	level: 'very_easy' | 'easy' | 'moderate' | 'difficult' | 'very_difficult';
}

/**
 * Statistics about sentence structure
 */
export interface SentenceStats {
	/** Total number of sentences */
	count: number;
	/** Average words per sentence */
	avg_length: number;
	/** Minimum sentence length in words */
	min_length: number;
	/** Maximum sentence length in words */
	max_length: number;
	/** Standard deviation of sentence lengths */
	std_deviation: number;
	/** Variety score (0-100, higher = more varied sentence lengths) */
	variety_score: number;
	/** Information about the longest sentence */
	longest: { length: number; position: number; text: string };
	/** Information about the shortest sentence */
	shortest: { length: number; position: number; text: string };
	/** Count of sentences that are too long (>30 words) */
	too_long_count: number;
	/** Count of sentences that are too short (<5 words) */
	too_short_count: number;
}

/**
 * Information about sentence starters
 */
export interface SentenceStarterStats {
	/** Map of first words to their frequency */
	starters: Record<string, number>;
	/** Most common starter word */
	most_common: { word: string; count: number };
	/** Variety score for sentence starters (0-100) */
	variety_score: number;
	/** Words that start too many sentences */
	overused: Array<{ word: string; count: number; percentage: number }>;
}

/**
 * Prose quality metrics
 */
export interface ProseMetrics {
	/** Percentage of words that are adverbs */
	adverb_percentage: number;
	/** Count of adverbs found */
	adverb_count: number;
	/** Percentage of sentences with passive voice */
	passive_voice_percentage: number;
	/** Count of passive constructions */
	passive_voice_count: number;
	/** Count of filter words found */
	filter_word_count: number;
	/** Count of weak verbs found */
	weak_verb_count: number;
	/** Count of clichés detected */
	cliche_count: number;
	/** Count of vague words */
	vague_word_count: number;
	/** Percentage of text that is dialogue */
	dialogue_percentage: number;
}

/**
 * Word repetition detection result
 */
export interface WordRepetition {
	/** The repeated word */
	word: string;
	/** Positions where the word appears (character offsets) */
	positions: number[];
	/** Distance between occurrences in words */
	distance: number;
}

/**
 * Detected passive voice construction
 */
export interface PassiveVoiceMatch {
	/** The passive construction found */
	phrase: string;
	/** Character position in text */
	position: number;
	/** Suggested active alternative */
	suggestion: string;
	/** Full sentence containing the passive voice */
	sentence: string;
}

/**
 * Detected adverb
 */
export interface AdverbMatch {
	/** The adverb found */
	word: string;
	/** Character position in text */
	position: number;
	/** Full sentence containing the adverb */
	sentence: string;
}

/**
 * Detected filter word
 */
export interface FilterWordMatch {
	/** The filter word found */
	word: string;
	/** Character position in text */
	position: number;
	/** Count of this word in the text */
	count: number;
}

/**
 * Detected weak verb
 */
export interface WeakVerbMatch {
	/** The weak verb found */
	verb: string;
	/** Character position in text */
	position: number;
	/** Context around the weak verb */
	context: string;
}

/**
 * Complete analysis result for a scene
 */
export interface SceneAnalysisResult {
	/** Word count of analyzed text */
	word_count: number;
	/** Character count of analyzed text */
	character_count: number;
	/** Readability scores */
	readability: ReadabilityScores;
	/** Sentence statistics */
	sentences: SentenceStats;
	/** Sentence starter analysis */
	sentence_starters: SentenceStarterStats;
	/** Prose quality metrics */
	metrics: ProseMetrics;
	/** All highlights for inline display */
	highlights: AnalysisHighlight[];
	/** Overall prose quality score (0-100) */
	overall_score: number;
	/** Brief summary of the analysis */
	summary: string;
	/** Top issues to address */
	top_issues: AnalysisIssue[];
	/** When the analysis was performed */
	analyzed_at: Date;
}

/**
 * A prioritized issue from the analysis
 */
export interface AnalysisIssue {
	/** Type of issue */
	type: HighlightType;
	/** Severity level */
	severity: HighlightSeverity;
	/** Human-readable description */
	message: string;
	/** Number of occurrences */
	count: number;
}

/**
 * Configuration for the text analysis service
 */
export interface AnalysisConfig {
	/** Minimum sentence length before flagging as too short */
	min_sentence_length: number;
	/** Maximum sentence length before flagging as too long */
	max_sentence_length: number;
	/** Maximum adverb percentage before warning */
	max_adverb_percentage: number;
	/** Maximum passive voice percentage before warning */
	max_passive_percentage: number;
	/** Distance threshold for repetition detection (in words) */
	repetition_distance: number;
	/** Minimum word length to check for repetition */
	repetition_min_word_length: number;
	/** Whether to enable cliché detection */
	enable_cliche_detection: boolean;
	/** Whether to enable vague word detection */
	enable_vague_word_detection: boolean;
}

/**
 * Default analysis configuration
 */
export const DEFAULT_ANALYSIS_CONFIG: AnalysisConfig = {
	min_sentence_length: 5,
	max_sentence_length: 30,
	max_adverb_percentage: 1.5,
	max_passive_percentage: 10,
	repetition_distance: 50,
	repetition_min_word_length: 5,
	enable_cliche_detection: true,
	enable_vague_word_detection: true
};

// =============================================================================
// AI Analysis Types (Phase 3)
// =============================================================================

/**
 * Show vs Tell analysis request
 */
export interface ShowTellRequest {
	content: string;
	scene_context?: string;
}

/**
 * A detected "telling" passage
 */
export interface TellingPassage {
	/** The original text that is "telling" */
	text: string;
	/** Character position in the content */
	position: number;
	/** Suggested rewrite that "shows" instead */
	suggestion: string;
	/** How significant this issue is */
	severity: 'minor' | 'moderate' | 'significant';
}

/**
 * Show vs Tell analysis response
 */
export interface ShowTellResponse {
	/** Detected telling passages */
	telling_passages: TellingPassage[];
	/** Percentage of text that is "showing" vs "telling" */
	show_tell_ratio: number;
	/** Overall assessment */
	assessment: string;
}

/**
 * POV analysis request
 */
export interface POVRequest {
	content: string;
	declared_pov: 'first' | 'third_limited' | 'third_omniscient';
	pov_character?: string;
}

/**
 * A detected POV slip
 */
export interface POVSlip {
	/** The text where POV slips */
	text: string;
	/** Character position */
	position: number;
	/** Description of the POV issue */
	issue: string;
	/** How to fix the slip */
	suggestion: string;
}

/**
 * POV analysis response
 */
export interface POVResponse {
	/** Detected POV slips */
	pov_slips: POVSlip[];
	/** POV consistency score (0-100) */
	consistency_score: number;
	/** Overall assessment */
	assessment: string;
}

/**
 * Tone analysis request
 */
export interface ToneRequest {
	content: string;
	intended_tone?: string;
}

/**
 * Point on the emotional arc
 */
export interface EmotionalArcPoint {
	/** Position as percentage through the text (0-100) */
	position: number;
	/** Tension level (0-10) */
	tension: number;
	/** Dominant emotion at this point */
	dominant_emotion: string;
}

/**
 * Tone analysis response
 */
export interface ToneResponse {
	/** Detected tones with confidence scores */
	detected_tones: Array<{ name: string; confidence: number }>;
	/** Overall tension level (0-10) */
	tension_level: number;
	/** Emotional arc through the scene */
	emotional_arc: EmotionalArcPoint[];
	/** Tone consistency score (0-100) */
	tone_consistency: number;
	/** Overall assessment */
	assessment: string;
}

/**
 * Consistency check request
 */
export interface ConsistencyRequest {
	current_scene: string;
	previous_scenes?: string[];
	characters?: Array<{ name: string; traits: string[] }>;
	established_facts?: string[];
}

/**
 * A character inconsistency
 */
export interface CharacterInconsistency {
	/** Character name */
	character: string;
	/** Description of the inconsistency */
	issue: string;
	/** Evidence from the text */
	evidence: string;
}

/**
 * A timeline issue
 */
export interface TimelineIssue {
	/** Description of the timeline problem */
	issue: string;
	/** The conflicting passages */
	conflicting_passages: [string, string];
}

/**
 * A factual contradiction
 */
export interface FactualContradiction {
	/** The established fact */
	fact: string;
	/** The contradicting text */
	contradiction: string;
}

/**
 * Consistency check response
 */
export interface ConsistencyResponse {
	/** Character behavior/trait inconsistencies */
	character_inconsistencies: CharacterInconsistency[];
	/** Timeline/sequencing issues */
	timeline_issues: TimelineIssue[];
	/** Contradictions with established facts */
	factual_contradictions: FactualContradiction[];
	/** Overall consistency score (0-100) */
	consistency_score: number;
	/** Overall assessment */
	assessment: string;
}
