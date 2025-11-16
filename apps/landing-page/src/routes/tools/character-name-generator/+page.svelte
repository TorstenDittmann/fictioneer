<script lang="ts">
	import { resolve } from '$app/paths';
	import { client } from '$lib/config';

	type NameStyle = 'regal' | 'mysterious' | 'edgy' | 'playful' | 'classic';

	const GENRES = [
		{ value: 'fantasy', label: 'Fantasy' },
		{ value: 'sci-fi', label: 'Science Fiction' },
		{ value: 'romance', label: 'Romance' },
		{ value: 'mystery', label: 'Mystery' },
		{ value: 'historical', label: 'Historical' }
	];

	const ORIGIN_OPTIONS = [
		{ value: 'western', label: 'Western' },
		{ value: 'japanese', label: 'Japanese' },
		{ value: 'celtic', label: 'Celtic' },
		{ value: 'latin', label: 'Latin' },
		{ value: 'arabic', label: 'Arabic' },
		{ value: 'custom', label: 'Blend' }
	];

	const GENDER_OPTIONS = [
		{ value: 'neutral', label: 'Neutral' },
		{ value: 'female', label: 'Feminine' },
		{ value: 'male', label: 'Masculine' }
	];

	const STYLE_OPTIONS: Array<{ value: NameStyle; label: string }> = [
		{ value: 'regal', label: 'Regal' },
		{ value: 'mysterious', label: 'Mysterious' },
		{ value: 'edgy', label: 'Edgy' },
		{ value: 'playful', label: 'Playful' },
		{ value: 'classic', label: 'Classic' }
	];

	type GeneratedName = {
		name: string;
		origin: string;
		meaning: string;
	};

	let selected_genre = $state('fantasy');
	let selected_origin = $state('western');
	let selected_gender = $state('neutral');
	let selected_style: NameStyle = $state('mysterious');
	let include_traits = $state('brave, clever, resilient');
	let results_requested = $state(6);
	let generated_names: GeneratedName[] = $state([]);
	let generating_names = $state(false);
	let error_message = $state('');

	async function generate_names() {
		if (generating_names) return;
		generating_names = true;
		error_message = '';
		generated_names = [];

		try {
			const response = await client.api.marketing['generate-character-names'].$post({
				json: {
					genre: selected_genre,
					origin: selected_origin,
					gender: selected_gender,
					style: selected_style,
					traits: include_traits,
					count: Number(results_requested)
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
				throw new Error(error_data.error || 'Failed to generate names');
			}

			const data = await response.json();
			generated_names = data.names ?? [];
		} catch (error) {
			console.error('Error generating names:', error);
			error_message =
				error instanceof Error ? error.message : 'Failed to generate names. Please try again.';
		} finally {
			generating_names = false;
		}
	}
</script>

<svelte:head>
	<title>Character Name Generator - Fantasy & Genre Names | Fictioneer</title>
	<meta
		name="description"
		content="Generate memorable character names for any genre. Blend origins, styles, and custom traits to craft unique hero, villain, or side character names instantly."
	/>
	<link rel="canonical" href="https://fictioneer.app/tools/character-name-generator" />
</svelte:head>

<div class="min-h-screen bg-paper-beige">
	<div
		class="absolute inset-0 bg-linear-to-br from-paper-beige via-paper-cream/50 to-paper-white/30"
	></div>
	<div class="absolute inset-0" style:background="var(--gradient-radial)"></div>

	<main class="relative z-10 mx-auto max-w-7xl px-4 py-12 pt-20 sm:px-6 lg:px-8">
		<div class="animate-fade-in-up mb-16 text-center">
			<div class="mb-6">
				<span class="animate-float text-6xl">👤</span>
			</div>
			<h1 class="mb-6 font-serif text-4xl font-bold md:text-6xl">
				<span class="text-paper-text">Character Name</span>
				<span class="gradient-text mt-2 block">Generator</span>
			</h1>
			<p class="mx-auto mb-8 max-w-3xl text-xl leading-relaxed text-paper-text-light">
				Craft unforgettable character names with genre-aware origins, stylistic flourishes, and
				optional traits. Perfect for fantasy epics, sci-fi adventures, romances, and mysteries.
			</p>
		</div>

		<div class="mb-16">
			<div
				class="glass hover-lift animate-fade-in-up mx-auto max-w-4xl rounded-2xl border border-paper-border p-8"
			>
				<h2 class="mb-8 text-center font-serif text-2xl font-semibold text-paper-text">
					Customize Your Character
				</h2>

				<form
					onsubmit={(event) => {
						event.preventDefault();
						generate_names();
					}}
					class="space-y-8"
				>
					<div class="grid gap-6 md:grid-cols-2">
						<div>
							<label for="genre" class="mb-2 block text-sm text-paper-text-light">Genre</label>
							<select id="genre" class="field" bind:value={selected_genre}>
								{#each GENRES as genre_option (genre_option.value)}
									<option value={genre_option.value}>{genre_option.label}</option>
								{/each}
							</select>
						</div>

						<div>
							<label for="origin" class="mb-2 block text-sm text-paper-text-light">
								Origin Style
							</label>
							<select id="origin" class="field" bind:value={selected_origin}>
								{#each ORIGIN_OPTIONS as origin_option (origin_option.value)}
									<option value={origin_option.value}>{origin_option.label}</option>
								{/each}
							</select>
						</div>

						<div>
							<label for="gender" class="mb-2 block text-sm text-paper-text-light">
								Gender Expression
							</label>
							<select id="gender" class="field" bind:value={selected_gender}>
								{#each GENDER_OPTIONS as option (option.value)}
									<option value={option.value}>{option.label}</option>
								{/each}
							</select>
						</div>

						<div>
							<label for="style" class="mb-2 block text-sm text-paper-text-light">
								Name Style
							</label>
							<select id="style" class="field" bind:value={selected_style}>
								{#each STYLE_OPTIONS as option (option.value)}
									<option value={option.value}>{option.label}</option>
								{/each}
							</select>
						</div>

						<div>
							<label for="name-count" class="mb-2 block text-sm text-paper-text-light">
								Number Of Names
							</label>
							<input
								type="range"
								min="3"
								max="12"
								step="3"
								id="name-count"
								bind:value={results_requested}
							/>
							<p class="mt-1 text-xs text-paper-text-muted">{results_requested} names</p>
						</div>

						<div>
							<label for="traits" class="mb-2 block text-sm text-paper-text-light">
								Traits or Prompts
							</label>
							<textarea
								rows="3"
								class="field"
								placeholder="brave, empathic, secretive"
								id="traits"
								bind:value={include_traits}
							></textarea>
						</div>
					</div>

					<button type="submit" class="btn-primary w-full py-3" disabled={generating_names}>
						{generating_names ? 'Generating Names...' : 'Generate Names'}
					</button>
				</form>
			</div>
		</div>

		<div class="animate-fade-in-up space-y-4" aria-live="polite">
			{#if error_message}
				<div class="glass border border-red-200 bg-red-50/80 p-4 text-sm text-red-700">
					{error_message}
				</div>
			{/if}
			{#if generated_names.length === 0}
				<div
					class="glass rounded-2xl border border-paper-border p-6 text-center text-paper-text-light"
				>
					Enter your preferences and generate bespoke character names.
				</div>
			{:else}
				<div class="grid gap-6 md:grid-cols-2">
					{#each generated_names as generated_name, index (generated_name.name)}
						<div class="glass hover-lift rounded-2xl border border-paper-border p-6">
							<p class="text-sm text-paper-text-muted">Name {index + 1}</p>
							<p class="font-serif text-2xl font-semibold text-paper-text">
								{generated_name.name}
							</p>
							<p class="mt-2 text-sm text-paper-text-light">{generated_name.meaning}</p>
						</div>
					{/each}
				</div>
			{/if}
		</div>

		<section class="mt-16">
			<div class="grid gap-6 md:grid-cols-3">
				<div class="glass rounded-2xl border border-paper-border p-6">
					<h3 class="font-serif text-xl text-paper-text">Why it works</h3>
					<p class="text-sm text-paper-text-light">
						Names blend curated phonetics with stylistic prefixes and suffixes for believable
						character voices.
					</p>
				</div>
				<div class="glass rounded-2xl border border-paper-border p-6">
					<h3 class="font-serif text-xl text-paper-text">Save your picks</h3>
					<p class="text-sm text-paper-text-light">
						Copy results into your notes or jump into the AI story generator to start writing with
						them.
					</p>
				</div>
				<div class="glass rounded-2xl border border-paper-border p-6">
					<h3 class="font-serif text-xl text-paper-text">Need a full story?</h3>
					<a
						class="btn-secondary mt-4 inline-flex w-full justify-center"
						href={resolve('/tools/ai-story-generator')}
					>
						Launch AI Story Generator
					</a>
				</div>
			</div>
		</section>
	</main>
</div>
