<script lang="ts">
	import { resolve } from '$app/paths';
	import { client } from '$lib/config';

	const GENRE_OPTIONS = [
		{ value: 'romance', label: 'Romance' },
		{ value: 'fantasy', label: 'Fantasy' },
		{ value: 'thriller', label: 'Thriller' },
		{ value: 'literary', label: 'Literary' },
		{ value: 'nonfiction', label: 'Non-fiction' }
	];

	const STYLES = [
		{ value: 'enigmatic', label: 'Enigmatic' },
		{ value: 'approachable', label: 'Approachable' },
		{ value: 'literary', label: 'Literary' },
		{ value: 'bold', label: 'Bold' }
	];

	const PRONOUN_OPTIONS = [
		{ value: 'neutral', label: 'Neutral' },
		{ value: 'feminine', label: 'Feminine' },
		{ value: 'masculine', label: 'Masculine' }
	];

	type PenName = {
		name: string;
		tagline: string;
	};

	let selected_genre = $state('romance');
	let selected_style = $state('enigmatic');
	let selected_pronouns = $state('neutral');
	let include_initials = $state(true);
	let include_keyword = $state('lighthouses, ink, midnight');
	let generated_pen_names: PenName[] = $state([]);
	let generating_pen_names = $state(false);
	let error_message = $state('');

	async function generate_pen_names() {
		if (generating_pen_names) return;
		generating_pen_names = true;
		error_message = '';
		generated_pen_names = [];

		try {
			const response = await client.api.marketing['generate-pen-names'].$post({
				json: {
					genre: selected_genre,
					style: selected_style,
					pronouns: selected_pronouns,
					keywords: include_keyword,
					include_initials
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
				throw new Error(error_data.error || 'Failed to generate pen names');
			}

			const data = await response.json();
			generated_pen_names = data.pen_names ?? [];
		} catch (error) {
			console.error('Pen name generation error:', error);
			error_message =
				error instanceof Error ? error.message : 'Failed to generate pen names. Please try again.';
		} finally {
			generating_pen_names = false;
		}
	}
</script>

<svelte:head>
	<title>Pen Name Generator - Build Your Author Persona | Fictioneer</title>
	<meta
		name="description"
		content="Craft a memorable pen name tailored to your genre, tone, and keywords. Generate author personas perfect for branding, marketing pages, or pseudonymous publishing."
	/>
	<link rel="canonical" href="https://fictioneer.app/tools/pen-name-generator" />
</svelte:head>

<div class="min-h-screen bg-paper-beige">
	<div
		class="absolute inset-0 bg-linear-to-br from-paper-beige via-paper-cream/50 to-paper-white/30"
	></div>
	<div class="absolute inset-0" style:background="var(--gradient-radial)"></div>

	<main class="relative z-10 mx-auto max-w-5xl px-4 py-12 pt-20 sm:px-6 lg:px-8">
		<section class="animate-fade-in-up mb-14 text-center">
			<div class="mb-4">
				<span class="text-5xl">✍️</span>
			</div>
			<h1 class="font-serif text-4xl font-bold text-paper-text md:text-5xl">Pen Name Generator</h1>
			<p class="mx-auto mt-4 max-w-3xl text-lg text-paper-text-light">
				Dial in your genre, tone, initials, and keywords to mint a pseudonym readers will remember.
			</p>
		</section>

		<div class="glass hover-lift rounded-2xl border border-paper-border p-8">
			<form
				class="space-y-6"
				onsubmit={(event) => {
					event.preventDefault();
					generate_pen_names();
				}}
			>
				<div class="grid gap-6 md:grid-cols-2">
					<label class="text-sm text-paper-text-light">
						<span class="mb-2 block" id="genre-field-label">Genre</span>
						<select class="input" aria-labelledby="genre-field-label" bind:value={selected_genre}>
							{#each GENRE_OPTIONS as option (option.value)}
								<option value={option.value}>{option.label}</option>
							{/each}
						</select>
					</label>

					<label class="text-sm text-paper-text-light">
						<span class="mb-2 block" id="style-field-label">Style</span>
						<select class="input" aria-labelledby="style-field-label" bind:value={selected_style}>
							{#each STYLES as option (option.value)}
								<option value={option.value}>{option.label}</option>
							{/each}
						</select>
					</label>

					<label class="text-sm text-paper-text-light">
						<span class="mb-2 block" id="pronoun-field-label">Pronoun Cue</span>
						<select
							class="input"
							aria-labelledby="pronoun-field-label"
							bind:value={selected_pronouns}
						>
							{#each PRONOUN_OPTIONS as option (option.value)}
								<option value={option.value}>{option.label}</option>
							{/each}
						</select>
					</label>

					<label class="flex items-center gap-3 text-sm text-paper-text-light">
						<input type="checkbox" bind:checked={include_initials} class="accent-paper-accent" />
						<span>Include custom initials</span>
					</label>
				</div>

				<div>
					<label for="pen-keywords" class="mb-2 block text-sm text-paper-text-light">
						Keywords (for initials & taglines)
					</label>
					<textarea
						rows="3"
						class="input"
						placeholder="lighthouses, ink, midnight"
						id="pen-keywords"
						bind:value={include_keyword}
					></textarea>
				</div>

				<button type="submit" class="btn-primary w-full py-3" disabled={generating_pen_names}>
					{generating_pen_names ? 'Weaving identities...' : 'Generate Pen Names'}
				</button>
			</form>
		</div>

		<section class="mt-10 grid gap-6 md:grid-cols-2" aria-live="polite">
			{#if error_message}
				<div
					class="glass border border-red-200 bg-red-50/80 p-4 text-sm text-red-700 md:col-span-2"
				>
					{error_message}
				</div>
			{/if}
			{#if generated_pen_names.length === 0}
				<div
					class="glass rounded-2xl border border-paper-border p-6 text-center text-paper-text-light"
				>
					Your curated list of pen names will show up here.
				</div>
			{:else}
				{#each generated_pen_names as pen_name (pen_name.name)}
					<div class="glass hover-lift rounded-2xl border border-paper-border p-6">
						<p class="font-serif text-2xl text-paper-text">{pen_name.name}</p>
						<p class="mt-2 text-sm text-paper-text-light">{pen_name.tagline}</p>
					</div>
				{/each}
			{/if}
		</section>

		<section
			class="mt-12 rounded-2xl border border-dashed border-paper-border p-6 text-center text-sm text-paper-text-light"
		>
			<p>
				Pair your new pseudonym with a logo, author bio, and newsletter call-to-action. Need instant
				copy? Send the pen name into the AI Story Generator for custom bios.
			</p>
			<a
				class="btn-secondary mt-4 inline-flex justify-center"
				href={resolve('/tools/ai-story-generator')}
			>
				Generate Author Bio
			</a>
		</section>
	</main>
</div>
