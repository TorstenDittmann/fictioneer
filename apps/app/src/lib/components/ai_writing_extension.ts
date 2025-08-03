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
						
						if (!pluginState?.suggestion) return false;

						// Accept suggestion with Tab
						if (event.key === 'Tab') {
							event.preventDefault();
							
							const { from, to } = view.state.selection;
							const tr = view.state.tr.insertText(pluginState.suggestion, from, to);
							tr.setMeta(suggestionPluginKey, { type: 'clear-suggestion' });
							view.dispatch(tr);
							
							return true;
						}

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
						
						const { state } = editorView;
						const { to } = state.selection;
						const text = state.doc.textBetween(0, state.doc.content.size, '\n');
						console.log('AI: Text length:', text.length, 'Min length:', extension.options.minLength);
						console.log('AI: Text content:', text);
						
						if (text.length < extension.options.minLength) {
							console.log('AI: Text too short');
							return;
						}

						// Set loading state and show loading indicator
						let tr = state.tr;
						tr.setMeta(suggestionPluginKey, { type: 'set-loading', loading: true });
						editorView.dispatch(tr);

						// Show animated caret loading indicator
						const loadingDecoration = Decoration.widget(to, () => {
							const span = document.createElement('span');
							span.textContent = '|';
							span.className = 'ai-loading-caret';
							span.style.cssText = `
								color: #94a3b8;
								font-style: normal;
								opacity: 0;
								animation: ai-caret-explode 0.2s ease-out forwards, ai-caret-pulse 0.6s infinite 0.2s;
								transform: scale(1);
								transition: all 0.15s cubic-bezier(0.4, 0, 0.2, 1);
								cursor: pointer;
								display: inline-block;
								font-family: inherit;
								line-height: inherit;
								vertical-align: inherit;
								transform-origin: center;
								margin: 0;
								padding: 0;
								position: relative;
								left: -1px;
							`;
							span.onclick = () => {
								span.style.animation = 'ai-caret-click-explode 0.15s ease-out';
							};
							return span;
						});

						const loadingDecorationSet = DecorationSet.create(state.doc, [loadingDecoration]);
						tr = editorView.state.tr;
						tr.setMeta(suggestionPluginKey, {
							type: 'set-suggestion',
							decorations: loadingDecorationSet,
							suggestion: null
						});
						editorView.dispatch(tr);

						try {
							// Improve context for better grammar
							const lastSentence = text.split(/[.!?]+/).pop() || '';
							const recentText = lastSentence.trim();
							const isIncomplete = recentText.length > 0 && !text.match(/[.!?]\s*$/);
							
							const enhancedContext = {
								...extension.options.context,
								recent_text: recentText,
								instruction: isIncomplete 
									? 'Complete this incomplete sentence naturally, then continue writing. Only provide the words needed to finish the current sentence and continue.' 
									: 'Continue writing from this point. Start a new sentence naturally.'
							};
							
							console.log('AI: Calling backend with enhanced context:', enhancedContext);
							const result = await ai_writing_backend_service.continue_writing(
								text,
								enhancedContext,
								50
							);
							console.log('AI: Backend result:', result);

							if (result && result.trim()) {
								const suggestion = ' ' + result.trim();
								
								// Create decoration for the suggestion
								const decoration = Decoration.widget(to, () => {
									const span = document.createElement('span');
									span.textContent = suggestion;
									span.className = 'ai-suggestion';
									span.style.cssText = `
										color: #94a3b8;
										font-style: italic;
										opacity: 0;
										animation: ai-suggestion-fade-in 0.4s ease-out forwards;
										transform: translateY(2px);
										transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
									`;
									// Add hover effect
									span.onmouseenter = () => {
										span.style.opacity = '1';
										span.style.transform = 'translateY(0px) scale(1.02)';
									};
									span.onmouseleave = () => {
										span.style.opacity = '0.7';
										span.style.transform = 'translateY(0px) scale(1)';
									};
									return span;
								});

								const decorationSet = DecorationSet.create(state.doc, [decoration]);
								
								tr = editorView.state.tr;
								tr.setMeta(suggestionPluginKey, {
									type: 'set-suggestion',
									decorations: decorationSet,
									suggestion: suggestion
								});
								editorView.dispatch(tr);
							} else {
								// Clear loading state if no suggestion
								tr = editorView.state.tr;
								tr.setMeta(suggestionPluginKey, { type: 'clear-suggestion' });
								editorView.dispatch(tr);
							}
						} catch (error) {
							console.error('AI suggestion error:', error);
							
							// Clear loading state on error
							tr = editorView.state.tr;
							tr.setMeta(suggestionPluginKey, { type: 'clear-suggestion' });
							editorView.dispatch(tr);
						}
					};

					let clearSuggestionTimeout: ReturnType<typeof setTimeout> | null = null;

					const checkOptionKey = (event: KeyboardEvent) => {
						if (event.altKey && !event.ctrlKey && !event.metaKey && !event.shiftKey) {
							// Clear any pending clear timeout
							if (clearSuggestionTimeout) {
								clearTimeout(clearSuggestionTimeout);
								clearSuggestionTimeout = null;
							}

							const { state } = editorView;
							const { selection } = state;
							const text = state.doc.textBetween(0, state.doc.content.size, '\n');
							const isAtEnd = selection.from >= state.doc.content.size - 1;
							
							if (selection.empty && text.length >= extension.options.minLength && isAtEnd) {
								console.log('AI: Option key held at end, generating suggestion');
								generateSuggestion();
							}
						}
					};

					const handleKeyUp = (event: KeyboardEvent) => {
						if (!event.altKey) {
							// Option key released - clear suggestion immediately with animation
							if (clearSuggestionTimeout) {
								clearTimeout(clearSuggestionTimeout);
							}
							
							// Add fade-out animation before clearing
							const suggestionElements = editorView.dom.querySelectorAll('.ai-suggestion');
							suggestionElements.forEach(el => {
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
					editorView.dom.addEventListener('keydown', checkOptionKey);
					editorView.dom.addEventListener('keyup', handleKeyUp);

					return {
						update: () => {
							// No automatic suggestions - only on Option key
						},
						destroy: () => {
							editorView.dom.removeEventListener('keydown', checkOptionKey);
							editorView.dom.removeEventListener('keyup', handleKeyUp);
							if (clearSuggestionTimeout) {
								clearTimeout(clearSuggestionTimeout);
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