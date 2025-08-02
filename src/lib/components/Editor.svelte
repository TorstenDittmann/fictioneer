<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import { Editor } from '@tiptap/core';
	import StarterKit from '@tiptap/starter-kit';
	import Placeholder from '@tiptap/extension-placeholder';
	import CharacterCount from '@tiptap/extension-character-count';
	import Focus from '@tiptap/extension-focus';
	import Typography from '@tiptap/extension-typography';
	import { projects } from '$lib/state/projects.svelte.js';
	import './editor.css';

	let editorElement: HTMLDivElement;
	let editor: Editor;

	interface Props {
		content?: string;
		placeholder?: string;
		onUpdate?: (content: string) => void;
	}

	let { content = '', placeholder = 'Start writing your story...', onUpdate }: Props = $props();

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
				Typography
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

				// Update the active scene
				const activeScene = projects.activeScene;
				const activeChapter = projects.activeChapter;
				const activeProject = projects.activeProject;
				if (activeScene && activeChapter && activeProject) {
					projects.updateScene(activeProject.id, activeChapter.id, activeScene.id, {
						content: html
					});
				}
			},
			onCreate: ({ editor }) => {
				// Set initial content if provided
				if (content) {
					editor.commands.setContent(content);
				}
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

<div class="editor-container h-full w-full">
	<div bind:this={editorElement} class="editor-content h-full w-full"></div>
</div>
