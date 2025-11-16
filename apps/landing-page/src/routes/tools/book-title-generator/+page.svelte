<script lang="ts">
	import { resolve } from '$app/paths';
	import { client } from '$lib/config';

	const GENRE_OPTIONS = [
		{ value: 'fantasy', label: 'Fantasy' },
		{ value: 'thriller', label: 'Thriller' },
		{ value: 'romance', label: 'Romance' },
		{ value: 'literary', label: 'Literary' },
		{ value: 'sci-fi', label: 'Science Fiction' },
		{ value: 'horror', label: 'Horror' }
	];

	const STYLE_OPTIONS = [
		{ value: 'lyrical', label: 'Lyrical' },
		{ value: 'bold', label: 'Bold' },
		{ value: 'mysterious', label: 'Mysterious' },
		{ value: 'whimsical', label: 'Whimsical' }
	];

	type GeneratedTitle = {
		title: string;
		hook: string;
	};

	let selected_genre = $state('fantasy');
	let selected_style = $state('lyrical');
	let keywords_input = $state('gilded rebellion, twin heirs');
	let title_count = $state(6);
	let generated_titles: GeneratedTitle[] = $state([]);
	let generating_titles = $state(false);
	let error_message = $state('');

	async function generate_titles() {
		if (generating_titles) return;
		generating_titles = true;
		error_message = '';
		generated_titles = [];

		try {
			const response = await client.api.marketing['generate-book-titles'].$post({
				json: {
					genre: selected_genre,
					style: selected_style,
					keywords: keywords_input,
					count: Number(title_count)
				}
			});

			if (!response.ok) {
				const error_text = await response.text();
				let error_data;
				try {
					error_data = JSON.parse(error_text);
				} catch {
					error_data = { error: error_text };
				}
				throw new Error(error_data.error || 'Failed to generate titles');
			}

			const data = await response.json();
			generated_titles = data.titles ?? [];
		} catch (error) {
			console.error('Book title generation error:', error);
			error_message =
				error instanceof Error ? error.message : 'Failed to generate titles. Please try again.';
		} finally {
			generating_titles = false;
		}
	}
</script>

<svelte:head>
	<title>Book Title Generator - Unique Title Ideas | Fictioneer</title>
	<meta
		name="description"
		content="Discover compelling book titles in any genre. Mix keywords with lyrical or bold styles to grab readers instantly."
	/>
	<link rel="canonical" href="https://fictioneer.app/tools/book-title-generator" />
</svelte:head>

<div class="min-h-screen bg-paper-beige">
	<div
		class="absolute inset-0 bg-linear-to-br from-paper-beige via-paper-cream/50 to-paper-white/30"
	></div>
	<div class="absolute inset-0" style:background="var(--gradient-radial)"></div>

	<main class="relative z-10 mx-auto max-w-5xl px-4 py-12 pt-20 sm:px-6 lg:px-8">
		<section class="animate-fade-in-up mb-16 text-center">
			<div class="mb-6">
				<span class="animate-float text-6xl">📖</span>
			</div>
			<h1 class="mb-6 font-serif text-4xl font-bold md:text-6xl">
				<span class="text-paper-text">Book Title</span>
				<span class="gradient-text mt-2 block">Generator</span>
			</h1>
			<p class="mx-auto max-w-3xl text-xl leading-relaxed text-paper-text-light">
				Pair evocative keywords with curated structures to produce market-ready titles that sell
				your story at a glance.
			</p>
		</section>

		<div class="glass hover-lift rounded-2xl border border-paper-border p-8">
			<form
				class="space-y-6"
				onsubmit={(event) => {
					event.preventDefault();
					generate_titles();
				}}
			>
				<div class="grid gap-6 md:grid-cols-2">
					<label class="text-sm text-paper-text-light">
						<span class="mb-2 block" id="genre-select-label">Genre</span>
						<select class="field" aria-labelledby="genre-select-label" bind:value={selected_genre}>
							{#each GENRE_OPTIONS as option (option.value)}
								<option value={option.value}>{option.label}</option>
							{/each}
						</select>
					</label>

					<label class="text-sm text-paper-text-light">
						<span class="mb-2 block" id="style-select-label">Style</span>
						<select class="field" aria-labelledby="style-select-label" bind:value={selected_style}>
							{#each STYLE_OPTIONS as option (option.value)}
								<option value={option.value}>{option.label}</option>
							{/each}
						</select>
					</label>

					<label class="text-sm text-paper-text-light">
						<span class="mb-2 block">Number of Titles</span>
						<input type="range" min="3" max="12" step="3" bind:value={title_count} />
						<span class="mt-1 block text-xs text-paper-text-muted">{title_count} titles</span>
					</label>
				</div>

				<div>
					<label for="keywords" class="mb-2 block text-sm text-paper-text-light">Keywords</label>
					<textarea
						rows="3"
						class="field"
						placeholder="heirloom, rebellion, star-crossed"
						id="keywords"
						bind:value={keywords_input}
					></textarea>
				</div>

				<button type="submit" class="btn-primary w-full py-3" disabled={generating_titles}>
					{generating_titles ? 'Generating...' : 'Generate Titles'}
				</button>
			</form>
		</div>

		<section class="mt-10 space-y-4" aria-live="polite">
			{#if error_message}
				<div class="glass border border-red-200 bg-red-50/80 p-4 text-sm text-red-700">
					{error_message}
				</div>
			{/if}
			{#if generated_titles.length === 0}
				<div
					class="glass rounded-2xl border border-paper-border p-6 text-center text-paper-text-light"
				>
					Your generated titles will appear here.
				</div>
			{:else}
				{#each generated_titles as generated_title (generated_title.title)}
					<div class="glass hover-lift rounded-2xl border border-paper-border p-6">
						<p class="font-serif text-2xl text-paper-text">{generated_title.title}</p>
						<p class="mt-1 text-sm text-paper-text-muted">{generated_title.hook}</p>
					</div>
				{/each}
			{/if}
		</section>

		<section class="mt-12 text-center">
			<p class="text-sm text-paper-text-light">
				Pair your favorite title with a synopsis. Continue in the AI Plot Generator or jump directly
				into prose with the AI Story Generator.
			</p>
			<div class="mt-4 flex flex-wrap justify-center gap-4">
				<a class="btn-secondary" href={resolve('/tools/plot-generator')}>Build Plot</a>
				<a class="btn-primary" href={resolve('/tools/ai-story-generator')}>Write Story</a>
			</div>
		</section>
	</main>
</div>
