<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import { Editor } from '@tiptap/core';
	import StarterKit from '@tiptap/starter-kit';
	import Placeholder from '@tiptap/extension-placeholder';
	import CharacterCount from '@tiptap/extension-character-count';
	import Focus from '@tiptap/extension-focus';
	import Typography from '@tiptap/extension-typography';
	import { AIWritingSuggestion } from './ai_writing_extension.js';
	import FloatingMenubar from './floating_menubar.svelte';
	import './tiptap.css';
	import { settings_state } from '$lib/state/settings.svelte';

	let editor_element: HTMLDivElement | undefined = undefined;
	let editor_container: HTMLDivElement | undefined = undefined;
	let editor = $state<Editor | null>(null);
	let doc_words = $state(0);
	let doc_chars = $state(0);

	const app_settings = $derived(settings_state.settings);

	// Scene word target (sweet spot)
	const target_min = 800;
	const target_max = 1800;

	const progress_percent = $derived(() => {
		const w = doc_words || 0;
		const pct = Math.min(Math.max((w / target_max) * 100, 0), 100);

		return Math.round(pct);
	});

	const progress_color = $derived(() => {
		const w = doc_words || 0;
		if (w < target_min) return 'var(--color-accent-muted)';
		if (w <= target_max) return 'var(--color-accent)';
		return 'var(--color-accent-active)';
	});

	interface Props {
		content?: string;
		placeholder?: string;
		onUpdate?: (content: string) => void;
		aiContext?: {
			title?: string;
			scene_description?: string;
		};
		os_type?: string;
	}

	let {
		content = '',
		placeholder = 'Start writing your story...',
		onUpdate,
		aiContext = {},
		os_type = 'unknown'
	}: Props = $props();

	const extensions = [
		StarterKit.configure({
			heading: {
				levels: [1, 2, 3, 4, 5, 6]
			},
			bulletList: {
				keepMarks: true,
				keepAttributes: false
			},
			orderedList: {
				keepMarks: true,
				keepAttributes: false
			}
		}),
		Placeholder.configure({
			placeholder: placeholder,
			emptyEditorClass: 'is-editor-empty'
		}),
		CharacterCount,
		Focus.configure({
			className: 'has-focus',
			mode: 'all'
		}),
		Typography,
		AIWritingSuggestion.configure({
			delay: 0,
			minLength: 10,
			contextWindowSize: 2000,
			context: aiContext,
			enabled: true,
			platformOS: os_type
		})
	];

	// Auto-scroll functionality to keep current line in middle
	function scroll_to_cursor(instant = false) {
		if (!editor || !editor_container) return;

		const { view } = editor;
		const { state } = view;
		const { selection } = state;

		// Get the DOM coordinates of the cursor
		const coords = view.coordsAtPos(selection.head);
		const container_rect = editor_container.getBoundingClientRect();

		// Calculate the scroll position to center the cursor
		const cursor_top = coords.top - container_rect.top + editor_container.scrollTop;
		const container_height = editor_container.clientHeight;
		const target_scroll_top = cursor_top - container_height / 2;

		// Scroll to center the cursor - instant for initial load, smooth for interaction
		editor_container.scrollTo({
			top: Math.max(0, target_scroll_top),
			behavior: instant ? 'auto' : 'smooth'
		});
	}

	// Position cursor at end of document without scrolling
	function position_cursor_at_end() {
		if (!editor) return;

		// Move cursor to end of document
		editor.commands.focus('end');
		scroll_to_cursor(true);
	}

	onMount(() => {
		editor = new Editor({
			element: editor_element,
			extensions: extensions,
			content: content,
			editorProps: {
				attributes: {
					class:
						'prose prose-stone max-w-none focus:outline-none min-h-screen prose-headings:font-serif prose-headings:font-bold prose-p:text-text prose-strong:text-text prose-em:text-text-secondary',
					style: `font-family: ${app_settings.editor.font_family}; font-size: ${app_settings.editor.font_size_px}px; line-height: ${app_settings.editor.line_height};`,
					spellcheck: app_settings.editor.spellcheck ? 'true' : 'false'
				}
			},
			onUpdate: ({ editor }) => {
				const html = editor.getHTML();
				onUpdate?.(html);

				// Auto-scroll to keep cursor in middle when typing
				requestAnimationFrame(() => {
					scroll_to_cursor();
				});

				update_counts();
			},
			onSelectionUpdate: () => {
				// Don't auto-scroll on selection changes (clicks)
				// Only scroll when typing (handled in onUpdate)
				update_counts();
			},
			onCreate: ({ editor }) => {
				// Set initial content if provided
				if (content) {
					editor.commands.setContent(content);
					// Position cursor at end and scroll there instantly
					position_cursor_at_end();
				}

				// AI context is set via extension options if enabled
				update_counts();
			}
		});
	});

	onDestroy(() => {
		if (editor) {
			editor.destroy();
		}
	});

	// Update editor content when content prop changes
	$effect(() => {
		if (editor && content !== editor.getHTML()) {
			editor.commands.setContent(content);
			// Position cursor at end and scroll there instantly when content changes
			position_cursor_at_end();
		}
	});

	// React to editor style settings changes
	$effect(() => {
		if (!editor) return;
		const { dom } = editor.view;
		dom.style.fontFamily = app_settings.editor.font_family;
		dom.style.fontSize = `${app_settings.editor.font_size_px}px`;
		dom.style.lineHeight = String(app_settings.editor.line_height);
		dom.setAttribute('spellcheck', app_settings.editor.spellcheck ? 'true' : 'false');
	});

	// Update padding based on margin
	const content_padding_style = $derived(`padding:${app_settings.editor.page_margin_px}px;`);

	function update_counts() {
		if (!editor) return;
		// Prefer the aggregated storage API exposed by Tiptap
		const cc = editor.storage.characterCount;
		if (cc) {
			doc_words = cc.words();
			doc_chars = cc.characters();
			return;
		}

		// Fallback to extension instance storage if needed
		const ext = editor.extensionManager.extensions.find((e) => e.name === 'characterCount');
		if (ext?.storage) {
			doc_words = ext.storage.words !== undefined ? ext.storage.words() : 0;
			doc_chars = ext.storage.characters !== undefined ? ext.storage.characters() : 0;
		}
	}

	// AI context updates automatically via extension options if enabled

	// Expose editor instance for parent components
	export function get_editor() {
		return editor;
	}

	export function focus() {
		editor?.commands.focus();
	}

	export function get_stats() {
		if (!editor) return { words: 0, characters: 0 };

		const extension = editor.extensionManager.extensions.find(
			(ext) => ext.name === 'characterCount'
		);
		if (!extension) return { words: 0, characters: 0 };

		return {
			words: extension.storage.words !== undefined ? extension.storage.words() : 0,
			characters: extension.storage.characters !== undefined ? extension.storage.characters() : 0
		};
	}

	export function get_content() {
		if (!editor) return '';
		return editor.getHTML();
	}
</script>

<div class="editor-container relative h-full w-full overflow-hidden">
	<div class="relative h-full w-full">
		<FloatingMenubar {editor} {content} />
		<div
			bind:this={editor_container}
			class="editor-content h-full overflow-y-auto"
			style={content_padding_style}
		>
			<div bind:this={editor_element} class="editor-element"></div>
		</div>

		<div
			class="group absolute right-3 bottom-2 z-10 flex flex-col rounded-md border border-border bg-surface px-2 py-1 text-xs text-text-secondary"
		>
			<div class="flex items-center gap-1">
				<span>{doc_words.toLocaleString()} words</span>
				<span>·</span>
				<span>{doc_chars.toLocaleString()} chars</span>
			</div>
			<div
				class="h-0 w-full overflow-hidden rounded bg-background-tertiary transition-[height,margin] duration-200 group-hover:mt-1 group-hover:h-1.5"
			>
				<div
					class="h-full rounded"
					style={`width:${progress_percent()}%; background-color:${progress_color()};`}
				></div>
			</div>
		</div>
	</div>
</div>
