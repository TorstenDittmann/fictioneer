/**
 * Reactive state management for text analysis
 * Handles debounced auto-analysis and analysis results
 */

import type {
	SceneAnalysisResult,
	AnalysisHighlight,
	AnalysisConfig,
	HighlightType
} from '../types/analysis.js';
import { DEFAULT_ANALYSIS_CONFIG } from '../types/analysis.js';
import { analyze_scene, quick_analyze } from '../services/text_analysis/index.js';

const ANALYSIS_PREFS_KEY = 'fictioneer_analysis_prefs';

/**
 * Create a simple hash of content for comparison
 */
function hash_content(content: string): string {
	// Simple hash for quick comparison
	let hash = 0;
	for (let i = 0; i < content.length; i++) {
		const char = content.charCodeAt(i);
		hash = (hash << 5) - hash + char;
		hash = hash & hash; // Convert to 32-bit integer
	}
	return hash.toString(16);
}

/**
 * Strip HTML tags from content to get plain text
 */
function strip_html(html: string): string {
	return html
		.replace(/<[^>]*>/g, ' ')
		.replace(/\s+/g, ' ')
		.trim();
}

interface AnalysisPrefs {
	highlights_enabled: boolean;
	visible_types: HighlightType[];
}

function load_analysis_prefs(): AnalysisPrefs | null {
	if (typeof localStorage === 'undefined') return null;
	try {
		const raw = localStorage.getItem(ANALYSIS_PREFS_KEY);
		if (!raw) return null;
		return JSON.parse(raw) as AnalysisPrefs;
	} catch {
		return null;
	}
}

function save_analysis_prefs(prefs: AnalysisPrefs): void {
	if (typeof localStorage === 'undefined') return;
	try {
		localStorage.setItem(ANALYSIS_PREFS_KEY, JSON.stringify(prefs));
	} catch {
		// ignore write errors
	}
}

/**
 * Reactive analysis state manager
 */
class AnalysisStateManager {
	/** Whether analysis is currently running */
	is_analyzing = $state(false);

	/** The latest analysis result */
	result = $state<SceneAnalysisResult | null>(null);

	/** Whether auto-analysis is enabled */
	enabled = $state(true);

	/** Whether inline highlights should be shown in the editor */
	highlights_enabled = $state(false);

	/** Configuration for analysis */
	config = $state<AnalysisConfig>({ ...DEFAULT_ANALYSIS_CONFIG });

	/** Types of highlights currently visible */
	#visible_types = $state<HighlightType[]>([
		'adverb',
		'passive_voice',
		'filter_word',
		'repetition',
		'long_sentence',
		'sentence_starter',
		'cliche',
		'vague_word',
		'weak_verb'
	]);

	/** Debounce timeout reference */
	#debounce_timeout: ReturnType<typeof setTimeout> | null = null;

	/** Last analyzed content hash */
	#last_content_hash = '';

	/** Debounce delay in milliseconds */
	#debounce_delay = 300;

	/** Whether preferences have been loaded */
	#initialized = false;

	constructor() {
		this.#load_prefs();
	}

	#load_prefs(): void {
		if (this.#initialized) return;
		const prefs = load_analysis_prefs();
		if (prefs) {
			this.highlights_enabled = prefs.highlights_enabled;
			if (prefs.visible_types && Array.isArray(prefs.visible_types)) {
				this.#visible_types = prefs.visible_types;
			}
		}
		this.#initialized = true;
	}

	#save_prefs(): void {
		save_analysis_prefs({
			highlights_enabled: this.highlights_enabled,
			visible_types: this.#visible_types
		});
	}

	// Derived state
	get visible_highlight_types(): Set<HighlightType> {
		return new Set(this.#visible_types);
	}

	get visible_highlights(): AnalysisHighlight[] {
		if (!this.result) return [];
		const visible = this.visible_highlight_types;
		return this.result.highlights.filter((h) => visible.has(h.type));
	}

	get highlight_count(): number {
		return this.visible_highlights.length;
	}

	get has_issues(): boolean {
		return this.result !== null && this.result.top_issues.length > 0;
	}

	get overall_score(): number {
		return this.result?.overall_score ?? 0;
	}

	get summary(): string {
		return this.result?.summary ?? '';
	}

	/**
	 * Toggle a highlight type visibility
	 */
	toggle_highlight_type(type: HighlightType): void {
		const index = this.#visible_types.indexOf(type);
		if (index >= 0) {
			this.#visible_types = this.#visible_types.filter((t) => t !== type);
		} else {
			this.#visible_types = [...this.#visible_types, type];
		}
		this.#save_prefs();
	}

	/**
	 * Set which highlight types are visible
	 */
	set_visible_types(types: HighlightType[]): void {
		this.#visible_types = [...types];
		this.#save_prefs();
	}

	/**
	 * Show all highlight types
	 */
	show_all_types(): void {
		this.#visible_types = [
			'adverb',
			'passive_voice',
			'filter_word',
			'repetition',
			'long_sentence',
			'sentence_starter',
			'cliche',
			'vague_word',
			'weak_verb'
		];
		this.#save_prefs();
	}

	/**
	 * Hide all highlight types
	 */
	hide_all_types(): void {
		this.#visible_types = [];
		this.#save_prefs();
	}

	/**
	 * Enable/disable auto-analysis
	 */
	set_enabled(enabled: boolean): void {
		this.enabled = enabled;
		if (!enabled) {
			this.cancel_pending_analysis();
		}
	}

	/**
	 * Enable/disable inline highlights in the editor
	 */
	set_highlights_enabled(enabled: boolean): void {
		this.highlights_enabled = enabled;
		this.#save_prefs();
	}

	/**
	 * Update analysis configuration
	 */
	update_config(updates: Partial<AnalysisConfig>): void {
		this.config = { ...this.config, ...updates };
	}

	/**
	 * Request analysis with debouncing
	 * Call this whenever content changes
	 */
	request_analysis(content: string): void {
		if (!this.enabled) return;

		// Strip HTML to get plain text for analysis
		const plain_text = strip_html(content);

		// Check if content actually changed
		const content_hash = hash_content(plain_text);
		if (content_hash === this.#last_content_hash) {
			return;
		}

		// Cancel any pending analysis
		this.cancel_pending_analysis();

		// Schedule new analysis
		this.#debounce_timeout = setTimeout(() => {
			this.#run_analysis(plain_text, content_hash);
		}, this.#debounce_delay);
	}

	/**
	 * Run analysis immediately (bypassing debounce)
	 */
	analyze_now(content: string): void {
		this.cancel_pending_analysis();
		const plain_text = strip_html(content);
		const content_hash = hash_content(plain_text);
		this.#run_analysis(plain_text, content_hash);
	}

	/**
	 * Cancel any pending analysis
	 */
	cancel_pending_analysis(): void {
		if (this.#debounce_timeout) {
			clearTimeout(this.#debounce_timeout);
			this.#debounce_timeout = null;
		}
	}

	/**
	 * Clear analysis results
	 */
	clear(): void {
		this.cancel_pending_analysis();
		this.result = null;
		this.#last_content_hash = '';
	}

	/**
	 * Run the actual analysis
	 */
	#run_analysis(plain_text: string, content_hash: string): void {
		// Skip empty content
		if (!plain_text || plain_text.trim().length === 0) {
			this.result = null;
			this.#last_content_hash = '';
			return;
		}

		// Skip if content hasn't changed
		if (content_hash === this.#last_content_hash && this.result !== null) {
			return;
		}

		this.is_analyzing = true;

		try {
			// Run analysis synchronously (it's fast enough for most scenes)
			const result = analyze_scene(plain_text, this.config);
			this.result = result;
			this.#last_content_hash = content_hash;
		} catch (error) {
			console.error('Analysis failed:', error);
			// Keep previous result on error
		} finally {
			this.is_analyzing = false;
		}
	}

	/**
	 * Get quick stats without full analysis
	 */
	get_quick_stats(content: string): {
		word_count: number;
		sentence_count: number;
		readability_score: number;
		readability_level: string;
	} {
		return quick_analyze(strip_html(content));
	}

	/**
	 * Set debounce delay
	 */
	set_debounce_delay(ms: number): void {
		this.#debounce_delay = Math.max(100, Math.min(10000, ms));
	}
}

// Export singleton instance
export const analysis_state = new AnalysisStateManager();

/**
 * Get color class for a highlight type
 */
export function get_highlight_color(type: HighlightType): string {
	switch (type) {
		case 'adverb':
			return 'bg-blue-500/20 border-blue-500';
		case 'passive_voice':
			return 'bg-yellow-500/20 border-yellow-500';
		case 'filter_word':
			return 'bg-purple-500/20 border-purple-500';
		case 'repetition':
			return 'bg-orange-500/20 border-orange-500';
		case 'weak_verb':
			return 'bg-pink-500/20 border-pink-500';
		case 'long_sentence':
			return 'bg-red-500/20 border-red-500';
		case 'sentence_starter':
			return 'bg-teal-500/20 border-teal-500';
		case 'cliche':
			return 'bg-amber-500/20 border-amber-500';
		case 'vague_word':
			return 'bg-gray-500/20 border-gray-500';
		default:
			return 'bg-gray-500/20 border-gray-500';
	}
}

/**
 * Get display name for a highlight type
 */
export function get_highlight_label(type: HighlightType): string {
	switch (type) {
		case 'adverb':
			return 'Adverbs';
		case 'passive_voice':
			return 'Passive Voice';
		case 'filter_word':
			return 'Filter Words';
		case 'repetition':
			return 'Repetition';
		case 'weak_verb':
			return 'Weak Verbs';
		case 'long_sentence':
			return 'Long Sentences';
		case 'sentence_starter':
			return 'Repetitive Starters';
		case 'cliche':
			return 'Clichés';
		case 'vague_word':
			return 'Vague Words';
		default:
			return type;
	}
}

/**
 * Get icon for a highlight type (for use with icon libraries)
 */
export function get_highlight_icon(type: HighlightType): string {
	switch (type) {
		case 'adverb':
			return 'type';
		case 'passive_voice':
			return 'arrow-right-left';
		case 'filter_word':
			return 'filter';
		case 'repetition':
			return 'copy';
		case 'weak_verb':
			return 'zap-off';
		case 'long_sentence':
			return 'text';
		case 'sentence_starter':
			return 'list-start';
		case 'cliche':
			return 'quote';
		case 'vague_word':
			return 'help-circle';
		default:
			return 'circle';
	}
}

/**
 * All available highlight types
 */
export const ALL_HIGHLIGHT_TYPES: HighlightType[] = [
	'adverb',
	'passive_voice',
	'filter_word',
	'repetition',
	'weak_verb',
	'long_sentence',
	'sentence_starter',
	'cliche',
	'vague_word'
];
