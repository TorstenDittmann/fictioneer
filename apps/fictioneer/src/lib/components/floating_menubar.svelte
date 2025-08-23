<script lang="ts">
	import { Menubar } from 'bits-ui';
	import type { Editor } from '@tiptap/core';
	import RephraseModal from './rephrase/rephrase_modal.svelte';
	import {
		ai_writing_backend_service,
		type RephraseOption
	} from '../services/ai_writing_backend.js';

	interface Props {
		editor: Editor | null;
		visible?: boolean;
	}

	let { editor, visible = true }: Props = $props();

	// Show menubar when editor exists and is visible
	let should_show_menubar = $derived(visible && editor);

	// Rephrase modal state
	let rephrase_modal_open = $state(false);
	let selected_text = $state('');
	let context_before = $state('');
	let context_after = $state('');
	let rephrases = $state<RephraseOption[]>([]);
	let rephrase_loading = $state(false);

	// Check if text is selected
	let has_selection = $state(false);

	// Update selection state when editor selection changes
	$effect(() => {
		if (!editor) {
			has_selection = false;
			return;
		}

		const updateSelection = () => {
			const { selection } = editor.state;
			has_selection = !selection.empty;
		};

		editor.on('selectionUpdate', updateSelection);
		updateSelection(); // Initial check

		return () => {
			editor.off('selectionUpdate', updateSelection);
		};
	});

	// Get selected text and context
	function get_selection_context() {
		if (!editor) return { text: '', before: '', after: '' };

		const { state } = editor;
		const { selection } = state;

		if (selection.empty) return { text: '', before: '', after: '' };

		const selected = state.doc.textBetween(selection.from, selection.to);

		// Get context before (up to 200 chars)
		const before_start = Math.max(0, selection.from - 200);
		const before = state.doc.textBetween(before_start, selection.from);

		// Get context after (up to 200 chars)
		const after_end = Math.min(state.doc.content.size, selection.to + 200);
		const after = state.doc.textBetween(selection.to, after_end);

		return { text: selected, before, after };
	}

	// Text formatting functions
	function toggle_bold() {
		editor?.chain().focus().toggleBold().run();
	}

	function toggle_italic() {
		editor?.chain().focus().toggleItalic().run();
	}

	function toggle_underline() {
		editor?.chain().focus().toggleUnderline().run();
	}

	function toggle_strikethrough() {
		editor?.chain().focus().toggleStrike().run();
	}

	// Heading functions
	function set_heading(level: 1 | 2 | 3 | 4 | 5 | 6) {
		editor?.chain().focus().toggleHeading({ level }).run();
	}

	function set_paragraph() {
		editor?.chain().focus().setParagraph().run();
	}

	// Block functions
	function toggle_blockquote() {
		editor?.chain().focus().toggleBlockquote().run();
	}

	// Edit functions
	function undo() {
		editor?.chain().focus().undo().run();
	}

	function redo() {
		editor?.chain().focus().redo().run();
	}

	// Rephrase functions
	async function open_rephrase_modal() {
		const selection_context = get_selection_context();
		if (!selection_context.text.trim()) return;

		// Check if license is valid
		if (!ai_writing_backend_service.has_valid_license) {
			alert('Please configure your license key in settings to use the rephrase feature.');
			return;
		}

		selected_text = selection_context.text;
		context_before = selection_context.before;
		context_after = selection_context.after;
		rephrases = [];
		rephrase_loading = true;
		rephrase_modal_open = true;

		try {
			const response = await ai_writing_backend_service.rephrase(
				selected_text,
				context_before,
				context_after
			);

			rephrases = response.rephrases;
		} catch (error) {
			console.error('Failed to get rephrases:', error);
			alert(`Failed to get rephrases: ${error instanceof Error ? error.message : 'Unknown error'}`);
		} finally {
			rephrase_loading = false;
		}
	}

	function replace_selected_text(new_text: string) {
		if (!editor) return;

		const { state } = editor;
		const { selection } = state;

		if (selection.empty) return;

		editor.chain().focus().deleteSelection().insertContent(new_text).run();
	}

	function close_rephrase_modal() {
		rephrase_modal_open = false;
	}
</script>

{#if should_show_menubar}
	<div
		class="absolute top-4 left-1/2 z-50 -translate-x-1/2 transform transition-all duration-200 ease-in-out"
	>
		<Menubar.Root
			class="flex items-center gap-1 rounded-lg border border-border bg-surface px-3 py-2 shadow-lg"
		>
			<!-- Undo Button -->
			<button
				class="inline-flex h-9 w-9 cursor-default items-center justify-center rounded-lg text-text-secondary transition-colors duration-200 hover:bg-background-tertiary focus:outline-none active:bg-surface"
				onclick={undo}
				title="Undo"
			>
				<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
					<path
						stroke-linecap="round"
						stroke-linejoin="round"
						stroke-width="2"
						d="M3 10h10a8 8 0 018 8v2M3 10l6 6m-6-6l6-6"
					/>
				</svg>
			</button>

			<!-- Redo Button -->
			<button
				class="inline-flex h-9 w-9 cursor-default items-center justify-center rounded-lg text-text-secondary transition-colors duration-200 hover:bg-background-tertiary focus:outline-none active:bg-surface"
				onclick={redo}
				title="Redo"
			>
				<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
					<path
						stroke-linecap="round"
						stroke-linejoin="round"
						stroke-width="2"
						d="M21 10h-10a8 8 0 00-8 8v2m18-10l-6 6m6-6l-6-6"
					/>
				</svg>
			</button>

			<!-- Format Menu -->
			<Menubar.Menu>
				<Menubar.Trigger
					class="inline-flex h-9 cursor-default items-center justify-center rounded-lg px-3 text-sm font-medium text-text-secondary transition-colors duration-200 hover:bg-background-tertiary focus:outline-none data-[state=open]:bg-background-tertiary"
				>
					Format
				</Menubar.Trigger>
				<Menubar.Portal>
					<Menubar.Content
						class="z-50 w-48 rounded-lg border border-border bg-surface p-1 shadow-lg"
						sideOffset={6}
					>
						<Menubar.Item
							class="flex h-8 cursor-default items-center rounded-md px-2 py-1 text-sm text-text outline-none select-none hover:bg-background-tertiary focus:bg-background-tertiary"
							onSelect={toggle_bold}
						>
							<svg class="mr-2 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
								<path
									stroke-linecap="round"
									stroke-linejoin="round"
									stroke-width="2"
									d="M6 4h8a4 4 0 014 4 4 4 0 01-4 4H6z"
								/>
								<path
									stroke-linecap="round"
									stroke-linejoin="round"
									stroke-width="2"
									d="M6 12h9a4 4 0 014 4 4 4 0 01-4 4H6z"
								/>
							</svg>
							Bold
						</Menubar.Item>
						<Menubar.Item
							class="flex h-8 cursor-default items-center rounded-md px-2 py-1 text-sm text-text outline-none select-none hover:bg-background-tertiary focus:bg-background-tertiary"
							onSelect={toggle_italic}
						>
							<svg class="mr-2 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
								<path
									stroke-linecap="round"
									stroke-linejoin="round"
									stroke-width="2"
									d="M19 4h-9M14 20H5m5-16L8 20"
								/>
							</svg>
							Italic
						</Menubar.Item>
						<Menubar.Item
							class="flex h-8 cursor-default items-center rounded-md px-2 py-1 text-sm text-text outline-none select-none hover:bg-background-tertiary focus:bg-background-tertiary"
							onSelect={toggle_underline}
						>
							<svg class="mr-2 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
								<path
									stroke-linecap="round"
									stroke-linejoin="round"
									stroke-width="2"
									d="M4 19h16M8 4v10a4 4 0 008 0V4"
								/>
							</svg>
							Underline
						</Menubar.Item>
						<Menubar.Item
							class="flex h-8 cursor-default items-center rounded-md px-2 py-1 text-sm text-text outline-none select-none hover:bg-background-tertiary focus:bg-background-tertiary"
							onSelect={toggle_strikethrough}
						>
							<svg class="mr-2 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
								<path
									stroke-linecap="round"
									stroke-linejoin="round"
									stroke-width="2"
									d="M6 12h12M6 4h4v8M14 4h4v8"
								/>
							</svg>
							Strikethrough
						</Menubar.Item>
						<Menubar.Separator class="my-1 h-px bg-border" />
						<Menubar.Item
							class="flex h-8 cursor-default items-center rounded-md px-2 py-1 text-sm text-text outline-none select-none hover:bg-background-tertiary focus:bg-background-tertiary"
							onSelect={toggle_blockquote}
						>
							<svg class="mr-2 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
								<path
									stroke-linecap="round"
									stroke-linejoin="round"
									stroke-width="2"
									d="M11 15h2a2 2 0 002-2V9a2 2 0 00-2-2h-2v8zM7 15h2a2 2 0 002-2V9a2 2 0 00-2-2H7v8z"
								/>
							</svg>
							Quote
						</Menubar.Item>
					</Menubar.Content>
				</Menubar.Portal>
			</Menubar.Menu>

			<!-- Headings Menu -->
			<Menubar.Menu>
				<Menubar.Trigger
					class="inline-flex h-9 cursor-default items-center justify-center rounded-lg px-3 text-sm font-medium text-text-secondary transition-colors duration-200 hover:bg-background-tertiary focus:outline-none data-[state=open]:bg-background-tertiary"
				>
					Headings
				</Menubar.Trigger>
				<Menubar.Portal>
					<Menubar.Content
						class="z-50 w-48 rounded-lg border border-border bg-surface p-1 shadow-lg"
						sideOffset={6}
					>
						<Menubar.Item
							class="flex h-8 cursor-default items-center rounded-md px-2 py-1 text-sm text-text outline-none select-none hover:bg-background-tertiary focus:bg-background-tertiary"
							onSelect={set_paragraph}
						>
							<svg class="mr-2 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
								<path
									stroke-linecap="round"
									stroke-linejoin="round"
									stroke-width="2"
									d="M4 6h16M4 12h16M4 18h7"
								/>
							</svg>
							Paragraph
						</Menubar.Item>
						<Menubar.Item
							class="flex h-8 cursor-default items-center rounded-md px-2 py-1 text-sm text-text outline-none select-none hover:bg-background-tertiary focus:bg-background-tertiary"
							onSelect={() => set_heading(1)}
						>
							<span class="mr-2 text-lg font-bold">H1</span>
							Heading 1
						</Menubar.Item>
						<Menubar.Item
							class="flex h-8 cursor-default items-center rounded-md px-2 py-1 text-sm text-text outline-none select-none hover:bg-background-tertiary focus:bg-background-tertiary"
							onSelect={() => set_heading(2)}
						>
							<span class="mr-2 text-base font-bold">H2</span>
							Heading 2
						</Menubar.Item>
						<Menubar.Item
							class="flex h-8 cursor-default items-center rounded-md px-2 py-1 text-sm text-text outline-none select-none hover:bg-background-tertiary focus:bg-background-tertiary"
							onSelect={() => set_heading(3)}
						>
							<span class="mr-2 text-sm font-bold">H3</span>
							Heading 3
						</Menubar.Item>
					</Menubar.Content>
				</Menubar.Portal>
			</Menubar.Menu>

			<!-- Rephrase Button (only show when text is selected) -->
			{#if has_selection}
				<button
					class="inline-flex h-9 cursor-default items-center justify-center rounded-lg px-3 text-sm font-medium text-text-secondary transition-colors duration-200 hover:bg-background-tertiary focus:outline-none"
					onclick={open_rephrase_modal}
					title="Get rephrase suggestions"
				>
					<svg class="mr-2 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
						<path
							stroke-linecap="round"
							stroke-linejoin="round"
							stroke-width="2"
							d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
						/>
					</svg>
					Rephrase
				</button>
			{/if}
		</Menubar.Root>
	</div>
{/if}

<!-- Rephrase Modal -->
{#if rephrase_modal_open}
	<RephraseModal
		bind:open={rephrase_modal_open}
		original_text={selected_text}
		{rephrases}
		loading={rephrase_loading}
		onClose={close_rephrase_modal}
		onSelect={replace_selected_text}
	/>
{/if}
