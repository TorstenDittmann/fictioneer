<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import { Editor } from '@tiptap/core';
	import StarterKit from '@tiptap/starter-kit';
	import Placeholder from '@tiptap/extension-placeholder';
	import CharacterCount from '@tiptap/extension-character-count';
	import Focus from '@tiptap/extension-focus';
	import Typography from '@tiptap/extension-typography';
	import { AIWritingSuggestion } from './ai_writing_extension.js';
	import { AnalysisHighlightExtension } from './analysis_highlight_extension.js';
	import FloatingMenubar from './floating_menubar.svelte';
	import './tiptap.css';
	import { settings_state } from '$lib/state/settings.svelte';
	import { analysis_state } from '$lib/state/analysis.svelte.js';

	let editor_element: HTMLDivElement | undefined = undefined;
	let editor_container: HTMLDivElement | undefined = undefined;
	let editor = $state<Editor | null>(null);
	let doc_words = $state(0);
	let doc_chars = $state(0);
	let stats_expanded = $state(false);

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
			placeholder,
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
		}),
		AnalysisHighlightExtension.configure({
			enabled: false,
			highlights: [],
			visibleTypes: analysis_state.visible_highlight_types
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

				// Trigger analysis on content change
				analysis_state.request_analysis(html);
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

	// Run initial analysis when editor loads with content
	$effect(() => {
		if (editor && content) {
			analysis_state.request_analysis(content);
		}
	});

	// Sync analysis highlights with editor when result changes
	$effect(() => {
		if (!editor) return;

		// Access reactive state properties to track them
		const result = analysis_state.result;
		const highlights_enabled = analysis_state.highlights_enabled;
		const visible_types = analysis_state.visible_highlight_types;

		// Update highlights in editor
		if (result && highlights_enabled) {
			editor.commands.setAnalysisEnabled(true);
			editor.commands.setAnalysisHighlights(result.highlights);
			editor.commands.setVisibleHighlightTypes(visible_types);
		} else {
			editor.commands.setAnalysisEnabled(false);
			editor.commands.clearAnalysisHighlights();
		}
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

		<!-- Expandable Stats Pill -->
		<button
			class="group absolute right-3 bottom-2 z-10 flex flex-col rounded-lg border border-border bg-background text-xs text-text-secondary transition-all duration-200 {stats_expanded
				? 'w-72 p-3'
				: 'px-2 py-1'} hover:border-accent/50"
			onclick={() => (stats_expanded = !stats_expanded)}
		>
			<!-- Collapsed: single row with hover progress bar -->
			{#if !stats_expanded}
				<div class="flex items-center gap-1">
					{#if analysis_state.result}
						<span
							class="font-medium {analysis_state.overall_score >= 70
								? 'text-green-500'
								: analysis_state.overall_score >= 50
									? 'text-yellow-500'
									: 'text-red-500'}"
						>
							{analysis_state.overall_score} score
						</span>
						<span class="text-text-muted">·</span>
					{/if}
					<span>{doc_words.toLocaleString()} words</span>
					<span class="text-text-muted">·</span>
					<span>{doc_chars.toLocaleString()} chars</span>
				</div>
				<!-- Progress bar on hover -->
				<div
					class="h-0 w-full overflow-hidden rounded bg-background-tertiary transition-[height,margin] duration-200 group-hover:mt-1 group-hover:h-1.5"
				>
					<div
						class="h-full rounded"
						style={`width:${progress_percent()}%; background-color:${progress_color()};`}
					></div>
				</div>
			{:else}
				<!-- Expanded view -->
				<div class="w-full text-left">
					<!-- Header row -->
					<div class="mb-2 flex items-center justify-between">
						<div class="flex items-center gap-1.5">
							{#if analysis_state.result}
								<span
									class="font-medium {analysis_state.overall_score >= 70
										? 'text-green-500'
										: analysis_state.overall_score >= 50
											? 'text-yellow-500'
											: 'text-red-500'}"
								>
									{analysis_state.overall_score} score
								</span>
								<span class="text-text-muted">·</span>
							{/if}
							<span class="text-text">{doc_words.toLocaleString()} words</span>
							<span class="text-text-muted">·</span>
							<span>{doc_chars.toLocaleString()} chars</span>
						</div>
						<svg
							class="h-3 w-3 text-text-muted"
							fill="none"
							stroke="currentColor"
							viewBox="0 0 24 24"
						>
							<path
								stroke-linecap="round"
								stroke-linejoin="round"
								stroke-width="2"
								d="M5 15l7-7 7 7"
							/>
						</svg>
					</div>

					<!-- Progress bar -->
					<div class="mb-3">
						<div class="mb-1 flex items-center justify-between text-[10px] text-text-muted">
							<span>Scene progress</span>
							<span>{target_min}–{target_max} words</span>
						</div>
						<div class="h-1.5 w-full rounded bg-background-tertiary">
							<div
								class="h-full rounded transition-all"
								style={`width:${progress_percent()}%; background-color:${progress_color()};`}
							></div>
						</div>
					</div>

					{#if analysis_state.result}
						<!-- Summary -->
						<p class="mb-3 text-[11px] text-text-secondary">{analysis_state.summary}</p>

						<!-- Readability -->
						<div class="mb-3">
							<h4 class="mb-1.5 text-[10px] font-medium tracking-wider text-text-muted uppercase">
								Readability
							</h4>
							<div class="grid grid-cols-2 gap-1.5">
								<div class="rounded bg-background-secondary p-1.5">
									<div class="text-[10px] text-text-muted">Reading Ease</div>
									<div class="text-sm font-semibold text-text">
										{analysis_state.result.readability.flesch_reading_ease}
									</div>
								</div>
								<div class="rounded bg-background-secondary p-1.5">
									<div class="text-[10px] text-text-muted">Grade Level</div>
									<div class="text-sm font-semibold text-text">
										{analysis_state.result.readability.flesch_kincaid_grade}
									</div>
								</div>
							</div>
						</div>

						<!-- Metrics -->
						<div class="mb-3">
							<h4 class="mb-1.5 text-[10px] font-medium tracking-wider text-text-muted uppercase">
								Prose Metrics
							</h4>
							<div class="space-y-1">
								<div class="flex items-center justify-between">
									<span class="text-text-muted">Adverbs</span>
									<span
										class="font-medium {analysis_state.result.metrics.adverb_percentage > 2
											? 'text-yellow-500'
											: 'text-text-secondary'}"
									>
										{analysis_state.result.metrics.adverb_percentage.toFixed(1)}%
									</span>
								</div>
								<div class="flex items-center justify-between">
									<span class="text-text-muted">Passive Voice</span>
									<span
										class="font-medium {analysis_state.result.metrics.passive_voice_percentage > 15
											? 'text-yellow-500'
											: 'text-text-secondary'}"
									>
										{analysis_state.result.metrics.passive_voice_percentage.toFixed(1)}%
									</span>
								</div>
								<div class="flex items-center justify-between">
									<span class="text-text-muted">Filter Words</span>
									<span class="font-medium text-text-secondary">
										{analysis_state.result.metrics.filter_word_count}
									</span>
								</div>
								<div class="flex items-center justify-between">
									<span class="text-text-muted">Dialogue</span>
									<span class="font-medium text-text-secondary">
										{analysis_state.result.metrics.dialogue_percentage}%
									</span>
								</div>
								<div class="flex items-center justify-between">
									<span class="text-text-muted">Sentence Variety</span>
									<span class="font-medium text-text-secondary">
										{analysis_state.result.sentences.variety_score}/100
									</span>
								</div>
							</div>
						</div>

						<!-- Top Issues -->
						{#if analysis_state.result.top_issues.length > 0}
							<div>
								<h4 class="mb-1.5 text-[10px] font-medium tracking-wider text-text-muted uppercase">
									Top Issues
								</h4>
								<div class="space-y-1">
									{#each analysis_state.result.top_issues.slice(0, 5) as issue (issue.type + issue.message)}
										<div
											class="flex items-start gap-1.5 rounded bg-background-secondary p-1.5 text-[11px]"
										>
											<span
												class="mt-0.5 h-1.5 w-1.5 shrink-0 rounded-full {issue.severity === 'error'
													? 'bg-red-500'
													: issue.severity === 'warning'
														? 'bg-yellow-500'
														: 'bg-blue-500'}"
											></span>
											<span class="text-text-secondary">{issue.message}</span>
										</div>
									{/each}
								</div>
							</div>
						{/if}
					{/if}
				</div>
			{/if}
		</button>
	</div>
</div>
