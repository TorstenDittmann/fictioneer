<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import { Editor } from '@tiptap/core';
	import StarterKit from '@tiptap/starter-kit';
	import Placeholder from '@tiptap/extension-placeholder';
	import CharacterCount from '@tiptap/extension-character-count';
	import Focus from '@tiptap/extension-focus';
	import Typography from '@tiptap/extension-typography';
	import Underline from '@tiptap/extension-underline';
	import { AIWritingSuggestion } from './ai_writing_extension.js';
	import FloatingMenubar from './floating_menubar.svelte';
	import './tiptap.css';

	let editor_element: HTMLDivElement | undefined = undefined;
	let editor_container: HTMLDivElement | undefined = undefined;
	let editor = $state<Editor | null>(null);

	interface Props {
		content?: string;
		placeholder?: string;
		onUpdate?: (content: string) => void;
		enableAI?: boolean;
		aiContext?: {
			title?: string;
			scene_description?: string;
		};
	}

	let {
		content = '',
		placeholder = 'Start writing your story...',
		onUpdate,
		enableAI = false,
		aiContext = {}
	}: Props = $props();

	// Conditionally include AI extension based on enableAI prop
	let extensions = $derived([
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
		Underline,
		// Only include AI writing suggestion if enabled
		...(enableAI
			? [
					AIWritingSuggestion.configure({
						delay: 0,
						minLength: 10,
						contextWindowSize: 2000,
						context: aiContext,
						enabled: true
					})
				]
			: [])
	]);

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
						'prose prose-lg prose-stone max-w-none focus:outline-none min-h-screen p-8 prose-headings:font-serif prose-headings:font-bold prose-p:text-gray-800 prose-p:leading-relaxed prose-strong:text-gray-900 prose-em:text-gray-700'
				}
			},
			onUpdate: ({ editor }) => {
				const html = editor.getHTML();
				onUpdate?.(html);

				// Auto-scroll to keep cursor in middle when typing
				requestAnimationFrame(() => {
					scroll_to_cursor();
				});
			},
			onSelectionUpdate: () => {
				// Don't auto-scroll on selection changes (clicks)
				// Only scroll when typing (handled in onUpdate)
			},
			onCreate: ({ editor }) => {
				// Set initial content if provided
				if (content) {
					editor.commands.setContent(content);
					// Position cursor at end and scroll there instantly
					position_cursor_at_end();
				}

				// AI context is set via extension options if enabled
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

		const storage = extension.storage as { characters: () => number; words: () => number };
		return {
			words: typeof storage.words === 'function' ? storage.words() : 0,
			characters: typeof storage.characters === 'function' ? storage.characters() : 0
		};
	}
</script>

<div class="editor-container relative h-full w-full overflow-hidden">
	<div class="relative h-full w-full">
		<FloatingMenubar {editor} />
		<div bind:this={editor_container} class="editor-content h-full overflow-y-auto">
			<div bind:this={editor_element} class="editor-element"></div>
		</div>
	</div>
</div>
