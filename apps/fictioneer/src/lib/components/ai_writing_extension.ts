import { Extension } from '@tiptap/core';
import { Plugin, PluginKey } from '@tiptap/pm/state';
import { Decoration, DecorationSet } from '@tiptap/pm/view';
import { ai_writing_backend_service } from '$lib/services/ai_writing_backend.js';

export interface AIWritingSuggestionOptions {
	delay: number;
	minLength: number;
	context: unknown;
	enabled: boolean;
	contextWindowSize: number;
	platformOS: string;
}

const suggestionPluginKey = new PluginKey('aiWritingSuggestion');

/**
 * Get the last N characters from the provided text as context
 */
function get_relevant_context(full_text: string, max_length: number): string {
	if (full_text.length <= max_length) {
		return full_text;
	}

	// Take the last max_length characters
	const context = full_text.slice(-max_length);

	console.log(
		'AI: Context extraction - Full length:',
		full_text.length,
		'Context length:',
		context.length
	);

	return context;
}

export const AIWritingSuggestion = Extension.create<AIWritingSuggestionOptions>({
	name: 'aiWritingSuggestion',

	addOptions() {
		return {
			delay: 50,
			minLength: 50,
			context: {},
			enabled: true,
			contextWindowSize: 2000,
			platformOS: 'unknown'
		};
	},

	addProseMirrorPlugins() {
		// eslint-disable-next-line @typescript-eslint/no-this-alias
		const extension = this;
		const platform_os = extension.options.platformOS;
		const normalized_os = platform_os.toLowerCase();
		const is_darwin = normalized_os === 'darwin' || normalized_os === 'macos';

		return [
			new Plugin({
				key: suggestionPluginKey,
				state: {
					init() {
						console.log('AI: Plugin initialized');
						return {
							decorations: DecorationSet.empty,
							timeout: null,
							suggestion: null,
							isLoading: false
						};
					},
					apply(tr, oldState) {
						const meta = tr.getMeta(suggestionPluginKey);

						if (meta?.type === 'set-suggestion') {
							return {
								...oldState,
								decorations: meta.decorations,
								suggestion: meta.suggestion,
								isLoading: false
							};
						}

						if (meta?.type === 'clear-suggestion') {
							return {
								...oldState,
								decorations: DecorationSet.empty,
								suggestion: null,
								isLoading: false
							};
						}

						if (meta?.type === 'set-loading') {
							return {
								...oldState,
								isLoading: meta.loading
							};
						}

						// Clear suggestions on document changes
						if (tr.docChanged) {
							if (oldState.timeout) {
								clearTimeout(oldState.timeout);
							}

							return {
								...oldState,
								decorations: DecorationSet.empty,
								suggestion: null,
								timeout: null,
								isLoading: false
							};
						}

						return oldState;
					}
				},
				props: {
					decorations(state) {
						const pluginState = this.getState(state);
						return pluginState?.decorations || DecorationSet.empty;
					},
					handleKeyDown(view, event) {
						const pluginState = suggestionPluginKey.getState(view.state);

						// Handle Tab key
						if (event.key === 'Tab') {
							// Always prevent default when Option/Alt is held
							if (event.altKey) {
								event.preventDefault();

								// If there's a suggestion, accept it
								if (pluginState?.suggestion) {
									const { from, to } = view.state.selection;
									const tr = view.state.tr.insertText(pluginState.suggestion, from, to);
									tr.setMeta(suggestionPluginKey, { type: 'clear-suggestion' });
									view.dispatch(tr);
								}
								// If generation is in progress or no suggestion yet, do nothing
								// This prevents triggering new generations

								return true;
							}

							// Accept suggestion with Tab (but not with other modifier keys)
							if (pluginState?.suggestion && !event.ctrlKey && !event.metaKey && !event.shiftKey) {
								event.preventDefault();

								const { from, to } = view.state.selection;
								const tr = view.state.tr.insertText(pluginState.suggestion, from, to);
								tr.setMeta(suggestionPluginKey, { type: 'clear-suggestion' });
								view.dispatch(tr);

								return true;
							}
						}

						// Accept suggestion with Ctrl+Enter on Windows/Linux
						if (
							!is_darwin &&
							event.key === 'Enter' &&
							pluginState?.suggestion &&
							event.ctrlKey &&
							!event.altKey &&
							!event.metaKey &&
							!event.shiftKey
						) {
							event.preventDefault();

							const { from, to } = view.state.selection;
							const tr = view.state.tr.insertText(pluginState.suggestion, from, to);
							tr.setMeta(suggestionPluginKey, { type: 'clear-suggestion' });
							view.dispatch(tr);

							return true;
						}

						// Only handle other keys if suggestion exists
						if (!pluginState?.suggestion) return false;

						// Dismiss suggestion with Escape
						if (event.key === 'Escape') {
							event.preventDefault();

							const tr = view.state.tr;
							tr.setMeta(suggestionPluginKey, { type: 'clear-suggestion' });
							view.dispatch(tr);

							return true;
						}

						return false;
					}
				},
				view(editorView) {
					let clear_suggestion_timeout: ReturnType<typeof setTimeout> | null = null;
					let option_key_held = false;
					let is_clearing = false;
					const option_indicator_class = 'ai-option-active';
					const editor_dom = editorView.dom as HTMLElement;
					const editor_container = editor_dom.closest('.editor-container') as HTMLElement | null;

					const update_option_indicator = (is_active: boolean) => {
						const target = editor_container ?? editor_dom;

						if (is_active) {
							target.classList.add(option_indicator_class);
							if (target !== editor_dom) {
								editor_dom.classList.remove(option_indicator_class);
							}
						} else {
							target.classList.remove(option_indicator_class);
							editor_dom.classList.remove(option_indicator_class);
						}
					};

					const generateSuggestion = async () => {
						console.log('AI: generateSuggestion called');
						if (!extension.options.enabled) {
							console.log('AI: Extension disabled');
							return;
						}

						// Check if license key is available and valid
						// if (!license_key_state.has_license_key || !license_key_state.is_valid) {
						// 	console.log('AI: No valid license key available');
						// 	return;
						// }

						// Don't generate if option key is not held
						if (!option_key_held) {
							console.log('AI: Option key not held, skipping generation');
							return;
						}

						// Don't generate if already generating
						if (ai_writing_backend_service.is_request_active()) {
							console.log('AI: Request already active, skipping generation');
							return;
						}

						const { state } = editorView;
						const { selection } = state;
						const cursor_position = selection.to;

						if (!selection.empty) {
							console.log('AI: Selection not collapsed, skipping generation');
							return;
						}

						// Use only the text before the cursor to build context
						const text_before_cursor = state.doc.textBetween(0, cursor_position, '\n');
						const context_text = get_relevant_context(
							text_before_cursor,
							extension.options.contextWindowSize
						);

						console.log(
							'AI: Context length:',
							context_text.length,
							'Min length:',
							extension.options.minLength
						);
						console.log('AI: Context content:', context_text);

						if (context_text.length < extension.options.minLength) {
							console.log('AI: Context too short');
							return;
						}

						try {
							// Improve context for better grammar
							const last_sentence = context_text.split(/[.!?]+/).pop() || '';
							const recent_text = last_sentence.trim();
							const is_incomplete = recent_text.length > 0 && !context_text.match(/[.!?]\s*$/);

							const enhanced_context = {
								...(typeof extension.options.context === 'object' &&
								extension.options.context !== null
									? extension.options.context
									: {}),
								recent_text: recent_text,
								instruction: is_incomplete
									? 'Complete this incomplete sentence naturally, then continue writing. Only provide the words needed to finish the current sentence and continue.'
									: 'Continue writing from this point. Start a new sentence naturally.'
							};

							// Create streaming typewriter container
							const typewriter_span = document.createElement('span');
							typewriter_span.className = 'ai-typewriter';
							typewriter_span.textContent = '';

							const decoration = Decoration.widget(cursor_position, () => typewriter_span, {
								side: 1,
								ignoreSelection: true
							});
							const decoration_set = DecorationSet.create(state.doc, [decoration]);

							// Show empty suggestion container immediately
							let tr = editorView.state.tr;
							tr.setMeta(suggestionPluginKey, {
								type: 'set-suggestion',
								decorations: decoration_set,
								suggestion: ''
							});
							editorView.dispatch(tr);

							// Animate dots appearing one by one before streaming starts
							let dot_count = 0;
							const dot_interval = setInterval(() => {
								if (dot_count < 3 && option_key_held && !is_clearing) {
									dot_count++;
									typewriter_span.textContent = '.'.repeat(dot_count);
								} else {
									clearInterval(dot_interval);
								}
							}, 150);

							console.log('AI: Calling backend with enhanced context:', enhanced_context);

							let full_suggestion = '';
							let result = '';
							let has_received_text = false;

							for await (const streamed_text of ai_writing_backend_service.continue_writing(
								context_text,
								enhanced_context,
								36
							)) {
								// Clear dot animation once we start receiving text
								if (!has_received_text) {
									clearInterval(dot_interval);
									has_received_text = true;
								}

								// Check if request was cancelled or option key released before updating UI
								if (!ai_writing_backend_service.is_request_active() || !option_key_held) {
									// Clear suggestion if option key was released
									if (!is_clearing) {
										is_clearing = true;
										const tr = editorView.state.tr;
										tr.setMeta(suggestionPluginKey, { type: 'clear-suggestion' });
										editorView.dispatch(tr);
										is_clearing = false;
									}
									clearInterval(dot_interval);
									break;
								}
								// Update typewriter span directly (no transaction needed for DOM-only update)
								const trimmed_text = streamed_text.trim();
								const should_show_dots = !trimmed_text.endsWith('.');
								const display_text = ' ' + trimmed_text + (should_show_dots ? '...' : '');
								// Direct DOM update - synchronous for immediate visual feedback
								typewriter_span.textContent = display_text;
								full_suggestion = ' ' + trimmed_text;
								result = streamed_text;
							}

							// Clean up dot interval
							clearInterval(dot_interval);

							console.log('AI: Backend result:', result);

							if (result && result.trim() && option_key_held) {
								// Ensure final text is set only if option key is still held (without trailing dots)
								full_suggestion = ' ' + result.trim();
								typewriter_span.textContent = full_suggestion;

								// Update suggestion state with final result
								tr = editorView.state.tr;
								tr.setMeta(suggestionPluginKey, {
									type: 'set-suggestion',
									decorations: decoration_set,
									suggestion: full_suggestion
								});
								editorView.dispatch(tr);
								is_clearing = false;
							} else {
								console.log('AI: No result from backend');
								// Clear suggestion
								if (!is_clearing) {
									is_clearing = true;
									tr = editorView.state.tr;
									tr.setMeta(suggestionPluginKey, { type: 'clear-suggestion' });
									editorView.dispatch(tr);
									is_clearing = false;
								}
							}
						} catch (error) {
							console.error('AI suggestion error:', error);

							// Clear suggestion on error
							if (!is_clearing) {
								is_clearing = true;
								const tr = editorView.state.tr;
								tr.setMeta(suggestionPluginKey, { type: 'clear-suggestion' });
								editorView.dispatch(tr);
								is_clearing = false;
							}
						}
					};

					const check_option_key = (event: KeyboardEvent) => {
						const allow_ctrl_trigger = !is_darwin;
						const is_option_trigger =
							(event.altKey && !event.metaKey && !event.shiftKey) ||
							(allow_ctrl_trigger && event.ctrlKey && !event.metaKey && !event.shiftKey);

						if (is_option_trigger) {
							option_key_held = true;
							update_option_indicator(true);
							// Reset clearing state when trigger key is pressed again
							is_clearing = false;
							// Clear any pending clear timeout
							if (clear_suggestion_timeout) {
								clearTimeout(clear_suggestion_timeout);
								clear_suggestion_timeout = null;
							}

							const { state } = editorView;
							const { selection } = state;
							const text_before_cursor = state.doc.textBetween(0, selection.from, '\n');
							const context_text = get_relevant_context(
								text_before_cursor,
								extension.options.contextWindowSize
							);

							if (
								selection.empty &&
								context_text.length >= extension.options.minLength &&
								!ai_writing_backend_service.is_request_active()
							) {
								console.log('AI: Suggestion trigger held, generating suggestion');
								generateSuggestion();
							}
						}
					};

					const handle_key_up = (event: KeyboardEvent) => {
						// Update option key state
						if (
							event.key === 'Alt' ||
							event.key === 'Option' ||
							event.code === 'AltLeft' ||
							event.code === 'AltRight' ||
							(!is_darwin &&
								(event.key === 'Control' ||
									event.code === 'ControlLeft' ||
									event.code === 'ControlRight'))
						) {
							option_key_held = false;
							update_option_indicator(false);
						}

						// Cancel request when Command key is released if there's an active request
						if (
							(event.key === 'Meta' ||
								event.key === 'Cmd' ||
								event.code === 'MetaLeft' ||
								event.code === 'MetaRight') &&
							ai_writing_backend_service.is_request_active()
						) {
							console.log('AI: Command key released, cancelling request');
							ai_writing_backend_service.cancel_current_request();

							// Clear suggestion immediately without animation
							if (!is_clearing) {
								is_clearing = true;
								const tr = editorView.state.tr;
								tr.setMeta(suggestionPluginKey, { type: 'clear-suggestion' });
								editorView.dispatch(tr);
								is_clearing = false;
							}
							return;
						}

						if (!event.altKey && (!event.ctrlKey || is_darwin) && !is_clearing) {
							// Option key released - clear suggestion with smooth animation
							if (clear_suggestion_timeout) {
								clearTimeout(clear_suggestion_timeout);
							}

							is_clearing = true;

							// Find typewriter elements and apply fade-out
							const typewriterElements = editorView.dom.querySelectorAll('.ai-typewriter');
							if (typewriterElements.length > 0) {
								typewriterElements.forEach((el) => {
									const element = el as HTMLElement;
									element.style.transition = 'opacity 0.2s ease-out';
									element.style.opacity = '0';
								});

								// Clear after animation completes
								clear_suggestion_timeout = setTimeout(() => {
									if (is_clearing) {
										const tr = editorView.state.tr;
										tr.setMeta(suggestionPluginKey, { type: 'clear-suggestion' });
										editorView.dispatch(tr);
										is_clearing = false;
									}
								}, 200);
							} else {
								// No animation needed, clear immediately
								const tr = editorView.state.tr;
								tr.setMeta(suggestionPluginKey, { type: 'clear-suggestion' });
								editorView.dispatch(tr);
								is_clearing = false;
							}
						}
					};

					// Add event listeners
					editorView.dom.addEventListener('keydown', check_option_key);
					editorView.dom.addEventListener('keyup', handle_key_up);

					return {
						update: () => {
							// No automatic suggestions - only on Option key
						},
						destroy: () => {
							editorView.dom.removeEventListener('keydown', check_option_key);
							editorView.dom.removeEventListener('keyup', handle_key_up);
							update_option_indicator(false);
							if (clear_suggestion_timeout) {
								clearTimeout(clear_suggestion_timeout);
							}
							const pluginState = suggestionPluginKey.getState(editorView.state);
							if (pluginState?.timeout) {
								clearTimeout(pluginState.timeout);
							}
						}
					};
				}
			})
		];
	},

	addKeyboardShortcuts() {
		return {
			'Mod-Shift-s': () => {
				this.options.enabled = !this.options.enabled;
				return true;
			}
		};
	}
});
