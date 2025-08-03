<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import { Editor } from '@tiptap/core';
	import StarterKit from '@tiptap/starter-kit';
	import Placeholder from '@tiptap/extension-placeholder';
	import CharacterCount from '@tiptap/extension-character-count';
	import Focus from '@tiptap/extension-focus';
	import Typography from '@tiptap/extension-typography';
	import { projects } from '$lib/state/projects.svelte.js';
	import type { Project, Chapter, Scene } from '$lib/services/projects.js';
	import { AIWritingSuggestion } from './ai_writing_extension.js';
	import './editor.css';

	let editorElement: HTMLDivElement;
	let editor: Editor;

	interface Props {
		content?: string;
		placeholder?: string;
		onUpdate?: (content: string) => void;
		project: Project;
		chapter: Chapter;
		scene: Scene;
	}

	let {
		content = '',
		placeholder = 'Start writing your story...',
		onUpdate,
		project,
		chapter,
		scene
	}: Props = $props();

	// Build writing context from project data
	let writing_context = $derived({
		title: project?.title,
		scene_description: scene?.title
	});

	onMount(() => {
		editor = new Editor({
			element: editorElement,
			extensions: [
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
					delay: 150,
					minLength: 10,
					context: writing_context,
					enabled: true
				})
			],
			content: content,
			editorProps: {
				attributes: {
					class:
						'prose prose-stone dark:prose-invert max-w-none focus:outline-none min-h-screen p-8 text-lg leading-relaxed'
				}
			},
			onUpdate: ({ editor }) => {
				const html = editor.getHTML();
				onUpdate?.(html);

				// Update the scene using the state
				if (project && chapter && scene) {
					projects.updateScene(project.id, chapter.id, scene.id, {
						content: html
					});
				}
			},
			onSelectionUpdate: () => {
				// Selection tracking removed
			},
			onCreate: ({ editor }) => {
				// Set initial content if provided
				if (content) {
					editor.commands.setContent(content);
				}

				// AI context is set via extension options
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
		}
	});

	// AI context updates automatically via extension options

	// Expose editor instance for parent components
	export function getEditor() {
		return editor;
	}

	export function focus() {
		editor?.commands.focus();
	}

	export function getStats() {
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
	<div bind:this={editorElement} class="editor-content h-full overflow-y-auto"></div>
</div>
