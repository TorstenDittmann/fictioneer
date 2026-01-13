<script lang="ts">
	import Fuse from 'fuse.js';
	import type { FuseResultMatch } from 'fuse.js';
	import { goto } from '$app/navigation';
	import { resolve } from '$app/paths';
	import { untrack } from 'svelte';
	import type { PageData } from './$types';

	let { data }: { data: PageData } = $props();

	let search_query = $state('');
	let debounced_query = $state('');
	let search_input_el: HTMLInputElement | undefined = $state();
	let debounce_timeout: ReturnType<typeof setTimeout> | undefined;

	interface SearchableScene {
		id: string;
		title: string;
		content: string;
		word_count: number;
		chapter_id: string;
		chapter_title: string;
	}

	// Cache for stripped HTML content (persists across searches)
	// eslint-disable-next-line svelte/prefer-svelte-reactivity -- Not reactive state, just a cache
	const content_cache = new Map<string, string>();

	/**
	 * Strip HTML tags from content and return plain text (with caching)
	 */
	function strip_html_cached(scene_id: string, html: string): string {
		let cached = content_cache.get(scene_id);
		if (cached === undefined) {
			cached = html
				.replace(/<[^>]*>/g, ' ')
				.replace(/\s+/g, ' ')
				.trim();
			content_cache.set(scene_id, cached);
		}
		return cached;
	}

	// Build searchable data from project - only rebuilds when project structure changes
	const searchable_scenes = $derived.by(() => {
		const scenes: SearchableScene[] = [];
		const project = data.project;

		for (const chapter of project.chapters) {
			for (const scene of chapter.scenes) {
				scenes.push({
					id: scene.id,
					title: scene.title,
					content: strip_html_cached(scene.id, scene.content),
					word_count: scene.wordCount,
					chapter_id: chapter.id,
					chapter_title: chapter.title
				});
			}
		}

		return scenes;
	});

	// Create Fuse instance - only recreates when scenes array changes
	const fuse = $derived(
		new Fuse(searchable_scenes, {
			keys: [
				{ name: 'title', weight: 2 },
				{ name: 'content', weight: 1 }
			],
			includeMatches: true,
			threshold: 0.4,
			ignoreLocation: true,
			minMatchCharLength: 2,
			useExtendedSearch: false
		})
	);

	// Debounce search input for better performance while typing
	$effect(() => {
		const query = search_query;
		clearTimeout(debounce_timeout);

		if (query.length < 2) {
			debounced_query = '';
			return;
		}

		debounce_timeout = setTimeout(() => {
			debounced_query = query;
		}, 150);

		return () => clearTimeout(debounce_timeout);
	});

	// Perform search using debounced query
	const search_results = $derived.by(() => {
		if (!debounced_query || debounced_query.length < 2) return [];
		// Access fuse in untrack to avoid circular dependency
		return untrack(() => fuse).search(debounced_query, { limit: 50 });
	});

	const is_searching = $derived(search_query.length >= 2 && search_query !== debounced_query);

	function navigate_to_scene(chapter_id: string, scene_id: string) {
		goto(
			resolve('/[projectId]/[chapterId]/[sceneId]', {
				projectId: data.project.id,
				chapterId: chapter_id,
				sceneId: scene_id
			})
		);
	}

	/**
	 * Build highlighted text from Fuse match indices
	 */
	function get_highlighted_segments(
		text: string,
		indices: readonly [number, number][] | undefined,
		max_length = 120
	): { text: string; highlighted: boolean }[] {
		if (!indices || indices.length === 0) {
			const truncated = text.length > max_length ? text.slice(0, max_length) + '...' : text;
			return [{ text: truncated, highlighted: false }];
		}

		const first_match = indices[0];
		const match_start = first_match[0];
		const match_end = first_match[1] + 1;

		const context_before = 40;
		const context_after = 60;
		const start = Math.max(0, match_start - context_before);
		const end = Math.min(text.length, match_end + context_after);

		const segments: { text: string; highlighted: boolean }[] = [];

		if (start > 0) {
			segments.push({ text: '...', highlighted: false });
		}

		const window_indices = indices.filter(([s, e]) => s >= start && e < end);

		let current_pos = start;
		for (const [idx_start, idx_end] of window_indices) {
			if (idx_start > current_pos) {
				segments.push({ text: text.slice(current_pos, idx_start), highlighted: false });
			}
			segments.push({ text: text.slice(idx_start, idx_end + 1), highlighted: true });
			current_pos = idx_end + 1;
		}

		if (current_pos < end) {
			segments.push({ text: text.slice(current_pos, end), highlighted: false });
		}

		if (end < text.length) {
			segments.push({ text: '...', highlighted: false });
		}

		return segments;
	}

	/**
	 * Get title with highlights
	 */
	function get_title_segments(
		title: string,
		matches: readonly FuseResultMatch[] | undefined
	): { text: string; highlighted: boolean }[] {
		const title_match = matches?.find((m) => m.key === 'title');
		if (!title_match?.indices) {
			return [{ text: title, highlighted: false }];
		}

		const segments: { text: string; highlighted: boolean }[] = [];
		let current_pos = 0;

		for (const [start, end] of title_match.indices) {
			if (start > current_pos) {
				segments.push({ text: title.slice(current_pos, start), highlighted: false });
			}
			segments.push({ text: title.slice(start, end + 1), highlighted: true });
			current_pos = end + 1;
		}

		if (current_pos < title.length) {
			segments.push({ text: title.slice(current_pos), highlighted: false });
		}

		return segments;
	}

	/**
	 * Get content matches for display (limited to 2 snippets)
	 */
	function get_content_matches(
		matches: readonly FuseResultMatch[] | undefined,
		content: string
	): { text: string; highlighted: boolean }[][] {
		const content_matches = matches?.filter((m) => m.key === 'content') ?? [];
		if (content_matches.length === 0) return [];

		const all_indices = content_matches.flatMap((m) => m.indices ?? []);
		if (all_indices.length === 0) return [];

		const snippets: { text: string; highlighted: boolean }[][] = [];
		const used_ranges: [number, number][] = [];

		for (const [start] of all_indices) {
			const overlaps = used_ranges.some(
				([used_start, used_end]) => start >= used_start - 50 && start <= used_end + 50
			);

			if (!overlaps && snippets.length < 2) {
				const snippet_indices = all_indices.filter(([s]) => s >= start - 50 && s <= start + 100);
				const segments = get_highlighted_segments(content, snippet_indices);
				snippets.push(segments);

				const snippet_end = Math.min(content.length, start + 100);
				used_ranges.push([start - 50, snippet_end]);
			}
		}

		return snippets;
	}

	// Focus search input on mount
	$effect(() => {
		if (search_input_el) {
			search_input_el.focus();
		}
	});
</script>

<div class="h-full overflow-y-auto">
	<div class="mx-auto max-w-4xl p-8">
		<!-- Header -->
		<div class="mb-8">
			<h1 class="text-3xl font-bold text-text">Search Scenes</h1>
			<p class="mt-2 text-text-secondary">Fuzzy search through all scene titles and content.</p>
		</div>

		<!-- Search Input -->
		<div class="mb-6">
			<div class="relative">
				<svg
					class="absolute top-1/2 left-3 h-5 w-5 -translate-y-1/2 text-text-muted"
					fill="none"
					stroke="currentColor"
					viewBox="0 0 24 24"
				>
					<path
						stroke-linecap="round"
						stroke-linejoin="round"
						stroke-width="2"
						d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
					/>
				</svg>
				<input
					bind:this={search_input_el}
					bind:value={search_query}
					type="text"
					placeholder="Search scenes..."
					class="flex h-10 w-full rounded-md border border-border bg-surface py-2 pr-3 pl-10 text-base text-text ring-offset-background placeholder:text-text-muted focus:ring-2 focus:ring-accent focus:ring-offset-2 focus:outline-none"
				/>
				{#if is_searching}
					<div class="absolute top-1/2 right-3 -translate-y-1/2">
						<svg class="h-4 w-4 animate-spin text-text-muted" fill="none" viewBox="0 0 24 24">
							<circle
								class="opacity-25"
								cx="12"
								cy="12"
								r="10"
								stroke="currentColor"
								stroke-width="4"
							></circle>
							<path
								class="opacity-75"
								fill="currentColor"
								d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
							></path>
						</svg>
					</div>
				{/if}
			</div>
			{#if debounced_query.length >= 2}
				<p class="mt-2 text-sm text-text-muted">
					{search_results.length} scene{search_results.length !== 1 ? 's' : ''} found
				</p>
			{:else if search_query.length > 0 && search_query.length < 2}
				<p class="mt-2 text-sm text-text-muted">Type at least 2 characters to search</p>
			{/if}
		</div>

		<!-- Search Results -->
		{#if debounced_query.length >= 2}
			{#if search_results.length > 0}
				<div class="space-y-4">
					{#each search_results as result (result.item.id)}
						{@const title_segments = get_title_segments(result.item.title, result.matches)}
						{@const content_snippets = get_content_matches(result.matches, result.item.content)}
						<button
							type="button"
							class="w-full rounded-lg border border-border bg-background-secondary p-6 text-left shadow-sm transition-colors hover:bg-background-tertiary focus:ring-2 focus:ring-accent focus:outline-none"
							onclick={() => navigate_to_scene(result.item.chapter_id, result.item.id)}
						>
							<div class="flex items-start gap-4">
								<div
									class="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-background-tertiary"
								>
									<svg
										class="h-5 w-5 text-accent"
										fill="none"
										stroke="currentColor"
										viewBox="0 0 24 24"
									>
										<path
											stroke-linecap="round"
											stroke-linejoin="round"
											stroke-width="2"
											d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
										/>
									</svg>
								</div>
								<div class="min-w-0 flex-1">
									<div class="flex items-center gap-2">
										<h3 class="font-medium text-text">
											{#each title_segments as segment, i (i)}
												{#if segment.highlighted}
													<mark class="bg-accent/30 text-text">{segment.text}</mark>
												{:else}
													{segment.text}
												{/if}
											{/each}
										</h3>
										{#if result.score !== undefined && result.score < 0.2}
											<span class="shrink-0 rounded bg-accent/20 px-1.5 py-0.5 text-xs text-accent">
												Best match
											</span>
										{/if}
									</div>
									<p class="mt-1 text-sm text-text-muted">
										{result.item.chapter_title} &bull; {result.item.word_count} words
									</p>

									<!-- Content matches -->
									{#each content_snippets as snippet, i (i)}
										<div
											class="mt-3 rounded-md bg-background-tertiary p-3 text-sm text-text-secondary"
										>
											{#each snippet as segment, j (j)}
												{#if segment.highlighted}
													<mark class="bg-accent/30 text-text">{segment.text}</mark>
												{:else}
													{segment.text}
												{/if}
											{/each}
										</div>
									{/each}
								</div>
							</div>
						</button>
					{/each}
				</div>
			{:else}
				<div class="rounded-lg bg-background-tertiary p-8 text-center">
					<svg
						class="mx-auto h-12 w-12 text-text-muted"
						fill="none"
						stroke="currentColor"
						viewBox="0 0 24 24"
					>
						<path
							stroke-linecap="round"
							stroke-linejoin="round"
							stroke-width="2"
							d="M9.172 16.172a4 4 0 015.656 0M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
						/>
					</svg>
					<h3 class="mt-4 text-lg font-medium text-text">No results found</h3>
					<p class="mt-2 text-text-secondary">
						No scenes match "{debounced_query}". Try a different search term.
					</p>
				</div>
			{/if}
		{:else}
			<div class="rounded-lg bg-background-tertiary p-8 text-center">
				<svg
					class="mx-auto h-12 w-12 text-text-muted"
					fill="none"
					stroke="currentColor"
					viewBox="0 0 24 24"
				>
					<path
						stroke-linecap="round"
						stroke-linejoin="round"
						stroke-width="2"
						d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
					/>
				</svg>
				<h3 class="mt-4 text-lg font-medium text-text">Search your scenes</h3>
				<p class="mt-2 text-text-secondary">
					Enter a search term to find scenes by title or content.
				</p>
			</div>
		{/if}
	</div>
</div>
