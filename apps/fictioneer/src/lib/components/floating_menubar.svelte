<script lang="ts">
	import { Menubar } from 'bits-ui';
	import type { Editor } from '@tiptap/core';
	import RephraseModal from './rephrase/rephrase_modal.svelte';
	import PromptModal from './prompt_modal.svelte';
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

	// AI prompt modal state
	let prompt_modal_open = $state(false);
	let generated_content = $state('');
	let prompt_loading = $state(false);

	// Check if text is selected
	let has_selection = $state(false);

	// Check if undo/redo are available
	let can_undo = $state(false);
	let can_redo = $state(false);

	// Update selection state when editor selection changes
	$effect(() => {
		if (!editor) {
			has_selection = false;
			can_undo = false;
			can_redo = false;
			return;
		}

		const updateSelection = () => {
			const { selection } = editor.state;
			has_selection = !selection.empty;
		};

		const updateHistory = () => {
			can_undo = editor.can().undo();
			can_redo = editor.can().redo();
		};

		editor.on('selectionUpdate', updateSelection);
		editor.on('transaction', updateHistory);
		updateSelection(); // Initial check
		updateHistory(); // Initial check

		return () => {
			editor.off('selectionUpdate', updateSelection);
			editor.off('transaction', updateHistory);
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
		// if (!ai_writing_backend_service.has_valid_license) {
		// 	alert('Please configure your license key in settings to use the rephrase feature.');
		// 	return;
		// }

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

	// AI prompt functions
	function open_prompt_modal() {
		generated_content = '';
		prompt_modal_open = true;
	}

	async function handle_generate_prompt(prompt: string) {
		prompt_loading = true;
		generated_content = '';

		try {
			let accumulated_content = '';
			for await (const chunk of ai_writing_backend_service.start_from_prompt(prompt, {}, 150)) {
				accumulated_content = chunk;
			}
			generated_content = accumulated_content;
		} catch (error) {
			console.error('Failed to generate content:', error);
			alert(
				`Failed to generate content: ${error instanceof Error ? error.message : 'Unknown error'}`
			);
		} finally {
			prompt_loading = false;
		}
	}

	function insert_generated_content(content: string) {
		if (!editor) return;
		editor.chain().focus().insertContent(content).run();
	}

	function close_prompt_modal() {
		prompt_modal_open = false;
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
	<!-- Top Formatting Bar -->
	<div
		class="absolute top-4 left-1/2 z-50 -translate-x-1/2 transform transition-all duration-200 ease-in-out"
	>
		<Menubar.Root
			class="floating-panel flex items-center gap-1 rounded-lg border border-border bg-surface px-3 py-2 shadow-lg"
		>
			<!-- Undo Button -->
			<button
				class="inline-flex h-9 w-9 cursor-default items-center justify-center rounded-lg text-text-secondary transition-colors duration-200 hover:bg-background-tertiary focus:outline-none active:bg-surface disabled:cursor-not-allowed disabled:opacity-50 disabled:hover:bg-transparent"
				onclick={undo}
				disabled={!can_undo}
				title="Undo"
				aria-label="Undo"
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
				class="inline-flex h-9 w-9 cursor-default items-center justify-center rounded-lg text-text-secondary transition-colors duration-200 hover:bg-background-tertiary focus:outline-none active:bg-surface disabled:cursor-not-allowed disabled:opacity-50 disabled:hover:bg-transparent"
				onclick={redo}
				disabled={!can_redo}
				title="Redo"
				aria-label="Redo"
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
		</Menubar.Root>
	</div>

	<!-- Bottom Actions Bar (always visible) -->
	<div
		class="absolute bottom-4 left-1/2 z-50 -translate-x-1/2 transform transition-all duration-200 ease-in-out"
	>
		<div
			class="floating-panel flex items-center gap-2 rounded-lg border border-border bg-surface px-3 py-2 shadow-lg"
		>
			<!-- AI Prompt Button -->
			<button
				class="inline-flex h-9 cursor-default items-center justify-center rounded-lg px-3 text-sm font-medium text-text-secondary transition-colors duration-200 hover:bg-background-tertiary focus:outline-none"
				onclick={open_prompt_modal}
				title="Generate content with AI"
			>
				<svg class="mr-2 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
					<path
						stroke-linecap="round"
						stroke-linejoin="round"
						stroke-width="2"
						d="M9.813 15.904L9 18.75l-.813-2.846a4.5 4.5 0 00-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 003.09-3.09L9 5.25l.813 2.846a4.5 4.5 0 003.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 00-3.09 3.09zM18.259 8.715L18 9.75l-.259-1.035a3.375 3.375 0 00-2.455-2.456L14.25 6l1.036-.259a3.375 3.375 0 002.455-2.456L18 2.25l.259 1.035a3.375 3.375 0 002.456 2.456L21.75 6l-1.035.259a3.375 3.375 0 00-2.456 2.456zM16.894 20.567L16.5 21.75l-.394-1.183a2.25 2.25 0 00-1.423-1.423L13.5 18.75l1.183-.394a2.25 2.25 0 001.423-1.423l.394-1.183.394 1.183a2.25 2.25 0 001.423 1.423l1.183.394-1.183.394a2.25 2.25 0 00-1.423 1.423z"
					/>
				</svg>
				AI Prompt
			</button>

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
		</div>
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

<!-- AI Prompt Modal -->
{#if prompt_modal_open}
	<PromptModal
		bind:open={prompt_modal_open}
		loading={prompt_loading}
		{generated_content}
		onClose={close_prompt_modal}
		onGenerate={handle_generate_prompt}
		onAccept={insert_generated_content}
		onReject={() => {}}
	/>
{/if}

<style>
	.floating-panel {
		background-color: #ffffff;
		backdrop-filter: blur(12px) saturate(1.06);
		-webkit-backdrop-filter: blur(12px) saturate(1.06);
		border: 1px solid var(--color-border);
		box-shadow: var(--shadow-lg);
	}
</style>
