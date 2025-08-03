import { Extension } from '@tiptap/core';
import { Plugin, PluginKey } from '@tiptap/pm/state';
import { Decoration, DecorationSet } from '@tiptap/pm/view';
import { ai_writing_backend_service } from '$lib/services/ai_writing_backend.js';

export interface AIWritingSuggestionOptions {
	delay: number;
	minLength: number;
	context: unknown;
	enabled: boolean;
}

const suggestionPluginKey = new PluginKey('aiWritingSuggestion');

export const AIWritingSuggestion = Extension.create<AIWritingSuggestionOptions>({
	name: 'aiWritingSuggestion',

	addOptions() {
		return {
			delay: 2000,
			minLength: 50,
			context: {},
			enabled: true
		};
	},

	addProseMirrorPlugins() {
		// eslint-disable-next-line @typescript-eslint/no-this-alias
		const extension = this;

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
					const generateSuggestion = async () => {
						console.log('AI: generateSuggestion called');
						if (!extension.options.enabled) {
							console.log('AI: Extension disabled');
							return;
						}

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
						const { to } = state.selection;
						const text = state.doc.textBetween(0, state.doc.content.size, '\n');
						console.log(
							'AI: Text length:',
							text.length,
							'Min length:',
							extension.options.minLength
						);
						console.log('AI: Text content:', text);

						if (text.length < extension.options.minLength) {
							console.log('AI: Text too short');
							return;
						}

						try {
							// Improve context for better grammar
							const last_sentence = text.split(/[.!?]+/).pop() || '';
							const recent_text = last_sentence.trim();
							const is_incomplete = recent_text.length > 0 && !text.match(/[.!?]\s*$/);

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
							typewriter_span.title = 'AI is generating text... Release ⌘ to cancel';
							typewriter_span.style.cssText = `
								color: #94a3b8;
								font-style: italic;
								opacity: 0.7;
							`;
							typewriter_span.textContent = '';

							// Add hover effect
							typewriter_span.onmouseenter = () => {
								typewriter_span.style.opacity = '1';
								typewriter_span.style.transform = 'scale(1.02)';
							};
							typewriter_span.onmouseleave = () => {
								typewriter_span.style.opacity = '0.7';
								typewriter_span.style.transform = 'scale(1)';
							};

							const decoration = Decoration.widget(to, () => typewriter_span);
							const decoration_set = DecorationSet.create(state.doc, [decoration]);

							// Show empty suggestion container immediately
							let tr = editorView.state.tr;
							tr.setMeta(suggestionPluginKey, {
								type: 'set-suggestion',
								decorations: decoration_set,
								suggestion: ''
							});
							editorView.dispatch(tr);

							console.log('AI: Calling backend with enhanced context:', enhanced_context);

							let full_suggestion = '';
							let result = '';

							for await (const streamed_text of ai_writing_backend_service.continue_writing(
								text,
								enhanced_context,
								50
							)) {
								// Check if request was cancelled or option key released before updating UI
								if (!ai_writing_backend_service.is_request_active() || !option_key_held) {
									// Clear suggestion if option key was released
									const tr = editorView.state.tr;
									tr.setMeta(suggestionPluginKey, { type: 'clear-suggestion' });
									editorView.dispatch(tr);
									break;
								}
								// Update typewriter span in real-time as text streams in
								const display_text = ' ' + streamed_text.trim();
								typewriter_span.textContent = display_text;
								full_suggestion = display_text;
								result = streamed_text;
							}

							console.log('AI: Backend result:', result);

							if (result && result.trim() && option_key_held) {
								// Ensure final text is set only if option key is still held
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
							} else {
								console.log('AI: No result from backend');
								// Clear suggestion
								tr = editorView.state.tr;
								tr.setMeta(suggestionPluginKey, { type: 'clear-suggestion' });
								editorView.dispatch(tr);
							}
						} catch (error) {
							console.error('AI suggestion error:', error);

							// Clear suggestion on error
							const tr = editorView.state.tr;
							tr.setMeta(suggestionPluginKey, { type: 'clear-suggestion' });
							editorView.dispatch(tr);
						}
					};

					let clear_suggestion_timeout: ReturnType<typeof setTimeout> | null = null;
					let option_key_held = false;

					const check_option_key = (event: KeyboardEvent) => {
						if (event.altKey && !event.ctrlKey && !event.metaKey && !event.shiftKey) {
							option_key_held = true;
							// Clear any pending clear timeout
							if (clear_suggestion_timeout) {
								clearTimeout(clear_suggestion_timeout);
								clear_suggestion_timeout = null;
							}

							const { state } = editorView;
							const { selection } = state;
							const text = state.doc.textBetween(0, state.doc.content.size, '\n');
							const isAtEnd = selection.from >= state.doc.content.size - 1;

							if (
								selection.empty &&
								text.length >= extension.options.minLength &&
								isAtEnd &&
								!ai_writing_backend_service.is_request_active()
							) {
								console.log('AI: Option key held at end, generating suggestion');
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
							event.code === 'AltRight'
						) {
							option_key_held = false;
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
							const tr = editorView.state.tr;
							tr.setMeta(suggestionPluginKey, { type: 'clear-suggestion' });
							editorView.dispatch(tr);
							return;
						}

						if (!event.altKey) {
							// Option key released - clear suggestion immediately with animation
							if (clear_suggestion_timeout) {
								clearTimeout(clear_suggestion_timeout);
							}

							// Add fade-out animation before clearing
							const suggestionElements = editorView.dom.querySelectorAll('.ai-suggestion');
							suggestionElements.forEach((el) => {
								const element = el as HTMLElement;
								element.style.animation = 'ai-suggestion-fade-out 0.3s ease-in forwards';
							});

							// Clear after animation completes
							setTimeout(() => {
								const tr = editorView.state.tr;
								tr.setMeta(suggestionPluginKey, { type: 'clear-suggestion' });
								editorView.dispatch(tr);
							}, 300);
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
