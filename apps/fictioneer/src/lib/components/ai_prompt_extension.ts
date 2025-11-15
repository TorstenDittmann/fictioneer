import { Extension } from '@tiptap/core';
import { Plugin, PluginKey } from '@tiptap/pm/state';
import { DecorationSet } from '@tiptap/pm/view';

export interface AIPromptOptions {
	enabled: boolean;
	contextWindowSize: number;
}

const promptPluginKey = new PluginKey('aiPrompt');

export const AIPromptExtension = Extension.create<AIPromptOptions>({
	name: 'aiPrompt',

	addOptions() {
		return {
			enabled: true,
			contextWindowSize: 2000
		};
	},

	addProseMirrorPlugins() {
		return [
			new Plugin({
				key: promptPluginKey,
				state: {
					init() {
						return {
							decorations: DecorationSet.empty,
							suggestion: null,
							isLoading: false,
							prompt: null
						};
					},
					apply(tr, oldState) {
						const meta = tr.getMeta(promptPluginKey);

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
								isLoading: false,
								prompt: null
							};
						}

						if (meta?.type === 'set-loading') {
							return {
								...oldState,
								isLoading: meta.loading
							};
						}

						if (meta?.type === 'set-prompt') {
							return {
								...oldState,
								prompt: meta.prompt
							};
						}

						// Clear suggestions on document changes
						if (tr.docChanged) {
							return {
								...oldState,
								decorations: DecorationSet.empty,
								suggestion: null,
								isLoading: false,
								prompt: null
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
				}
			})
		];
	}
});
