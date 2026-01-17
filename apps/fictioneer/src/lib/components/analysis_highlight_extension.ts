/**
 * Tiptap extension for inline analysis highlights
 * Renders prose quality issues directly in the editor with hover tooltips
 */

import { Extension } from '@tiptap/core';
import { Plugin, PluginKey } from '@tiptap/pm/state';
import { Decoration, DecorationSet } from '@tiptap/pm/view';
import type { Node as ProseMirrorNode } from '@tiptap/pm/model';
import type {
	AnalysisHighlight as AnalysisHighlightType,
	HighlightType
} from '$lib/types/analysis.js';

export interface AnalysisHighlightExtensionOptions {
	/** Whether highlights are enabled */
	enabled: boolean;
	/** Current highlights to display */
	highlights: AnalysisHighlightType[];
	/** Which highlight types are visible */
	visibleTypes: Set<HighlightType>;
}

const analysisHighlightPluginKey = new PluginKey('analysisHighlight');

/**
 * Get CSS class for highlight type
 */
function get_highlight_class(type: HighlightType): string {
	const base = 'analysis-highlight';
	switch (type) {
		case 'adverb':
			return `${base} ${base}--adverb`;
		case 'passive_voice':
			return `${base} ${base}--passive`;
		case 'filter_word':
			return `${base} ${base}--filter`;
		case 'repetition':
			return `${base} ${base}--repetition`;
		case 'weak_verb':
			return `${base} ${base}--weak-verb`;
		case 'long_sentence':
			return `${base} ${base}--long-sentence`;
		case 'sentence_starter':
			return `${base} ${base}--starter`;
		case 'cliche':
			return `${base} ${base}--cliche`;
		case 'vague_word':
			return `${base} ${base}--vague`;
		default:
			return base;
	}
}

/**
 * Get display label for highlight type
 */
function get_type_label(type: HighlightType): string {
	switch (type) {
		case 'adverb':
			return 'Adverb';
		case 'passive_voice':
			return 'Passive Voice';
		case 'filter_word':
			return 'Filter Word';
		case 'repetition':
			return 'Repetition';
		case 'weak_verb':
			return 'Weak Verb';
		case 'long_sentence':
			return 'Long Sentence';
		case 'sentence_starter':
			return 'Repetitive Starter';
		case 'cliche':
			return 'Cliché';
		case 'vague_word':
			return 'Vague Word';
		default:
			return type;
	}
}

/**
 * Convert plain text position to ProseMirror document position
 * This accounts for HTML structure in the document
 */
function text_pos_to_doc_pos(doc: ProseMirrorNode, text_pos: number): number {
	// We need to walk through the document and count text characters
	// to find the document position that corresponds to the plain text position
	let current_text_pos = 0;
	let doc_pos = 0;

	// Walk character by character through the doc
	for (let i = 1; i <= doc.content.size; i++) {
		const text_so_far = doc.textBetween(0, i, '\n');
		if (text_so_far.length > current_text_pos) {
			current_text_pos = text_so_far.length;
			doc_pos = i;

			if (current_text_pos >= text_pos) {
				// Adjust for the difference
				const diff = current_text_pos - text_pos;
				return Math.max(1, doc_pos - diff);
			}
		}
	}

	return doc_pos;
}

/**
 * Create decorations from highlights
 */
function create_decorations(
	doc: ProseMirrorNode,
	highlights: AnalysisHighlightType[],
	visible_types: Set<HighlightType>
): DecorationSet {
	const decorations: Decoration[] = [];

	// Get plain text for position mapping
	const plain_text = doc.textBetween(0, doc.content.size, '\n');

	for (const highlight of highlights) {
		// Skip if type is not visible
		if (!visible_types.has(highlight.type)) continue;

		// Find the text in the document
		const search_text = highlight.text.toLowerCase();
		let search_start = 0;

		// Find the occurrence closest to the expected position
		let best_match_pos = -1;
		let best_distance = Infinity;

		while (true) {
			const found_pos = plain_text.toLowerCase().indexOf(search_text, search_start);
			if (found_pos === -1) break;

			const distance = Math.abs(found_pos - highlight.start);
			if (distance < best_distance) {
				best_distance = distance;
				best_match_pos = found_pos;
			}

			search_start = found_pos + 1;

			// If we found an exact match, use it
			if (distance === 0) break;
		}

		if (best_match_pos === -1) continue;

		// Convert plain text positions to doc positions
		const from = text_pos_to_doc_pos(doc, best_match_pos);
		const to = text_pos_to_doc_pos(doc, best_match_pos + highlight.text.length);

		// Validate positions
		if (from < 1 || to > doc.content.size || from >= to) continue;

		// Create inline decoration
		const decoration = Decoration.inline(from, to, {
			class: get_highlight_class(highlight.type),
			'data-highlight-type': highlight.type,
			'data-highlight-id': highlight.id,
			'data-highlight-message': highlight.message,
			'data-highlight-suggestion': highlight.suggestion || ''
		});

		decorations.push(decoration);
	}

	return DecorationSet.create(doc, decorations);
}

/**
 * Create and manage tooltip element
 */
function create_tooltip_manager() {
	let tooltip: HTMLDivElement | null = null;
	let hide_timeout: ReturnType<typeof setTimeout> | null = null;

	function show(target: HTMLElement, type: HighlightType, message: string, suggestion: string) {
		// Clear any pending hide
		if (hide_timeout) {
			clearTimeout(hide_timeout);
			hide_timeout = null;
		}

		// Create tooltip if it doesn't exist
		if (!tooltip) {
			tooltip = document.createElement('div');
			tooltip.className = 'analysis-tooltip';
			document.body.appendChild(tooltip);
		}

		// Build tooltip content
		const type_label = get_type_label(type);
		tooltip.innerHTML = `
			<div class="analysis-tooltip__header">
				<span class="analysis-tooltip__type analysis-tooltip__type--${type}">${type_label}</span>
			</div>
			<div class="analysis-tooltip__message">${message}</div>
			${suggestion ? `<div class="analysis-tooltip__suggestion">${suggestion}</div>` : ''}
		`;

		// Position tooltip above the target
		const rect = target.getBoundingClientRect();
		const tooltip_rect = tooltip.getBoundingClientRect();

		let top = rect.top - tooltip_rect.height - 8;
		let left = rect.left + rect.width / 2 - tooltip_rect.width / 2;

		// Adjust if tooltip would go off screen
		if (top < 8) {
			top = rect.bottom + 8;
		}
		if (left < 8) {
			left = 8;
		}
		if (left + tooltip_rect.width > window.innerWidth - 8) {
			left = window.innerWidth - tooltip_rect.width - 8;
		}

		tooltip.style.top = `${top}px`;
		tooltip.style.left = `${left}px`;
		tooltip.classList.add('analysis-tooltip--visible');
	}

	function hide() {
		if (tooltip) {
			tooltip.classList.remove('analysis-tooltip--visible');
		}
	}

	function hide_delayed(delay = 100) {
		if (hide_timeout) {
			clearTimeout(hide_timeout);
		}
		hide_timeout = setTimeout(hide, delay);
	}

	function destroy() {
		if (hide_timeout) {
			clearTimeout(hide_timeout);
		}
		if (tooltip) {
			tooltip.remove();
			tooltip = null;
		}
	}

	return { show, hide, hide_delayed, destroy };
}

export const AnalysisHighlightExtension = Extension.create<AnalysisHighlightExtensionOptions>({
	name: 'analysisHighlight',

	addOptions() {
		return {
			enabled: false,
			highlights: [],
			visibleTypes: new Set<HighlightType>([
				'adverb',
				'passive_voice',
				'filter_word',
				'repetition',
				'weak_verb',
				'long_sentence',
				'sentence_starter',
				'cliche',
				'vague_word'
			])
		};
	},

	addStorage() {
		return {
			highlights: [] as AnalysisHighlightType[],
			visibleTypes: new Set<HighlightType>(),
			enabled: false
		};
	},

	addCommands() {
		return {
			setAnalysisHighlights:
				(highlights: AnalysisHighlightType[]) =>
				({ tr, dispatch }) => {
					if (dispatch) {
						tr.setMeta(analysisHighlightPluginKey, {
							type: 'set-highlights',
							highlights
						});
					}
					return true;
				},
			clearAnalysisHighlights:
				() =>
				({ tr, dispatch }) => {
					if (dispatch) {
						tr.setMeta(analysisHighlightPluginKey, {
							type: 'clear-highlights'
						});
					}
					return true;
				},
			setAnalysisEnabled:
				(enabled: boolean) =>
				({ tr, dispatch }) => {
					if (dispatch) {
						tr.setMeta(analysisHighlightPluginKey, {
							type: 'set-enabled',
							enabled
						});
					}
					return true;
				},
			setVisibleHighlightTypes:
				(types: Set<HighlightType>) =>
				({ tr, dispatch }) => {
					if (dispatch) {
						tr.setMeta(analysisHighlightPluginKey, {
							type: 'set-visible-types',
							types
						});
					}
					return true;
				}
		};
	},

	addProseMirrorPlugins() {
		// eslint-disable-next-line @typescript-eslint/no-this-alias
		const extension = this;

		return [
			new Plugin({
				key: analysisHighlightPluginKey,
				state: {
					init() {
						return {
							decorations: DecorationSet.empty,
							highlights: extension.options.highlights,
							visibleTypes: extension.options.visibleTypes,
							enabled: extension.options.enabled
						};
					},
					apply(tr, oldState, _oldEditorState, newEditorState) {
						const meta = tr.getMeta(analysisHighlightPluginKey);

						let highlights = oldState.highlights;
						let visible_types = oldState.visibleTypes;
						let enabled = oldState.enabled;
						let needs_rebuild = false;

						if (meta?.type === 'set-highlights') {
							highlights = meta.highlights;
							needs_rebuild = true;
						}

						if (meta?.type === 'clear-highlights') {
							highlights = [];
							needs_rebuild = true;
						}

						if (meta?.type === 'set-enabled') {
							enabled = meta.enabled;
							needs_rebuild = true;
						}

						if (meta?.type === 'set-visible-types') {
							visible_types = meta.types;
							needs_rebuild = true;
						}

						// Rebuild decorations if needed or if doc changed
						if (needs_rebuild || tr.docChanged) {
							const decorations = enabled
								? create_decorations(newEditorState.doc, highlights, visible_types)
								: DecorationSet.empty;

							return {
								decorations,
								highlights,
								visibleTypes: visible_types,
								enabled
							};
						}

						// Map decorations through document changes
						if (tr.docChanged) {
							return {
								...oldState,
								decorations: oldState.decorations.map(tr.mapping, tr.doc)
							};
						}

						return oldState;
					}
				},
				props: {
					decorations(state) {
						const pluginState = this.getState(state);
						return pluginState?.decorations || DecorationSet.empty;
					}
				},
				view() {
					const tooltip_manager = create_tooltip_manager();

					// Event handlers for hover
					const handle_mouseover = (event: MouseEvent) => {
						const target = event.target as HTMLElement;
						const highlight_el = target.closest('.analysis-highlight') as HTMLElement;

						if (highlight_el) {
							const type = highlight_el.dataset.highlightType as HighlightType;
							const message = highlight_el.dataset.highlightMessage || '';
							const suggestion = highlight_el.dataset.highlightSuggestion || '';

							tooltip_manager.show(highlight_el, type, message, suggestion);
						}
					};

					const handle_mouseout = (event: MouseEvent) => {
						const target = event.target as HTMLElement;
						const highlight_el = target.closest('.analysis-highlight');

						if (highlight_el) {
							tooltip_manager.hide_delayed();
						}
					};

					// Hide tooltip immediately on scroll
					const handle_scroll = () => {
						tooltip_manager.hide();
					};

					// Add event listeners
					document.addEventListener('mouseover', handle_mouseover);
					document.addEventListener('mouseout', handle_mouseout);
					document.addEventListener('scroll', handle_scroll, true);

					return {
						destroy() {
							document.removeEventListener('mouseover', handle_mouseover);
							document.removeEventListener('mouseout', handle_mouseout);
							document.removeEventListener('scroll', handle_scroll, true);
							tooltip_manager.destroy();
						}
					};
				}
			})
		];
	}
});

// Declare module augmentation for custom commands
declare module '@tiptap/core' {
	interface Commands<ReturnType> {
		analysisHighlight: {
			setAnalysisHighlights: (highlights: AnalysisHighlightType[]) => ReturnType;
			clearAnalysisHighlights: () => ReturnType;
			setAnalysisEnabled: (enabled: boolean) => ReturnType;
			setVisibleHighlightTypes: (types: Set<HighlightType>) => ReturnType;
		};
	}
}
