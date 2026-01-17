<script lang="ts">
	import { resolve } from '$app/paths';
	import { client } from '$lib/config';

	const WORLD_TYPES = [
		{ value: 'fantasy', label: 'Fantasy' },
		{ value: 'modern', label: 'Modern' },
		{ value: 'sci-fi', label: 'Sci-Fi' },
		{ value: 'historical', label: 'Historical' }
	];

	const REGIONS = [
		{ value: 'coastal', label: 'Coastal' },
		{ value: 'mountain', label: 'Mountain' },
		{ value: 'forest', label: 'Forest' },
		{ value: 'desert', label: 'Desert' },
		{ value: 'tundra', label: 'Tundra' }
	];

	const SIZES = [
		{ value: 'hamlet', label: 'Hamlet' },
		{ value: 'village', label: 'Village' },
		{ value: 'town', label: 'Town' },
		{ value: 'city', label: 'City' }
	];

	const VIBES = [
		{ value: 'whimsical', label: 'Whimsical' },
		{ value: 'gritty', label: 'Gritty' },
		{ value: 'serene', label: 'Serene' },
		{ value: 'mystic', label: 'Mystic' }
	];

	type Place = {
		name: string;
		region: string;
		description: string;
		population: string;
	};

	let selected_world = $state('fantasy');
	let selected_region = $state('coastal');
	let selected_size = $state('town');
	let selected_vibe = $state('whimsical');
	let features = $state('floating markets, sea glass, hidden library');
	let generated_places: Place[] = $state([]);
	let generating_places = $state(false);
	let error_message = $state('');

	async function generate_places() {
		if (generating_places) return;
		generating_places = true;
		error_message = '';
		generated_places = [];

		const result_section = document.getElementById('result-section');
		result_section?.scrollIntoView({ behavior: 'smooth', block: 'start' });

		try {
			const response = await client.api.marketing['generate-town-names'].$post({
				json: {
					world_type: selected_world,
					region: selected_region,
					size: selected_size,
					vibe: selected_vibe,
					features,
					count: 6
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
				throw new Error(error_data.error || 'Failed to generate towns');
			}

			const data = await response.json();
			generated_places = data.places ?? [];
		} catch (error) {
			console.error('Town generation error:', error);
			error_message =
				error instanceof Error ? error.message : 'Failed to generate towns. Please try again.';
		} finally {
			generating_places = false;
		}
	}
</script>

<svelte:head>
	<title>AI Town Name Generator - Fictional Locations | Fictioneer</title>
	<meta
		name="description"
		content="Invent AI town names for your stories. Blend world type, region, vibe, and features to spark believable place names with vivid descriptions."
	/>
	<meta
		name="keywords"
		content="AI town name generator, fantasy town names, fictional place names, worldbuilding tools, AI worldbuilding"
	/>
	<meta property="og:title" content="AI Town Name Generator - Fictional Locations | Fictioneer" />
	<meta
		property="og:description"
		content="Invent AI town names for your stories with world type, region, vibe, and feature controls."
	/>
	<meta name="twitter:title" content="AI Town Name Generator - Fictional Locations | Fictioneer" />
	<meta
		name="twitter:description"
		content="Invent AI town names for your stories with world type, region, vibe, and feature controls."
	/>
	<link rel="canonical" href="https://fictioneer.app/tools/town-name-generator" />
</svelte:head>

<div class="min-h-screen bg-paper-beige">
	<div
		class="absolute inset-0 bg-linear-to-br from-paper-beige via-paper-cream/50 to-paper-white/30"
	></div>
	<div class="absolute inset-0" style:background="var(--gradient-radial)"></div>

	<main class="relative z-10 mx-auto max-w-5xl px-4 py-12 pt-20 sm:px-6 lg:px-8">
		<section class="animate-fade-in-up text-center">
			<div class="mb-4">
				<span class="text-5xl">🏘️</span>
			</div>
			<h1 class="font-serif text-4xl font-bold text-paper-text">AI Town Name Generator</h1>
			<p class="mx-auto mt-4 max-w-3xl text-lg text-paper-text-light">
				Design atmospheric towns with AI guidance for any campaign, novel, or screenplay. Customize
				the world type, vibe, and regional flavor.
			</p>
		</section>

		<div class="glass mt-10 rounded-2xl border border-paper-border p-8">
			<form
				class="grid gap-6"
				onsubmit={(event) => {
					event.preventDefault();
					generate_places();
				}}
			>
				<div class="grid gap-4 md:grid-cols-2">
					<label class="text-sm text-paper-text-light">
						<span class="mb-1 block">World Type</span>
						<select class="input" bind:value={selected_world}>
							{#each WORLD_TYPES as option (option.value)}
								<option value={option.value}>{option.label}</option>
							{/each}
						</select>
					</label>

					<label class="text-sm text-paper-text-light">
						<span class="mb-1 block">Region</span>
						<select class="input" bind:value={selected_region}>
							{#each REGIONS as option (option.value)}
								<option value={option.value}>{option.label}</option>
							{/each}
						</select>
					</label>

					<label class="text-sm text-paper-text-light">
						<span class="mb-1 block">Settlement Size</span>
						<select class="input" bind:value={selected_size}>
							{#each SIZES as option (option.value)}
								<option value={option.value}>{option.label}</option>
							{/each}
						</select>
					</label>

					<label class="text-sm text-paper-text-light">
						<span class="mb-1 block">Vibe</span>
						<select class="input" bind:value={selected_vibe}>
							{#each VIBES as option (option.value)}
								<option value={option.value}>{option.label}</option>
							{/each}
						</select>
					</label>
				</div>

				<label class="text-sm text-paper-text-light">
					<span class="mb-1 block">Signature Features</span>
					<textarea
						rows="3"
						class="input"
						placeholder="floating markets, sea glass, hidden library"
						bind:value={features}
					></textarea>
				</label>

				<button type="submit" class="btn-primary w-full py-3">Generate Towns</button>
			</form>
		</div>

		<section id="result-section" class="mt-10 grid gap-6 md:grid-cols-2" aria-live="polite">
			{#if error_message}
				<div
					class="glass border border-red-200 bg-red-50/80 p-4 text-sm text-red-700 md:col-span-2"
				>
					{error_message}
				</div>
			{/if}
			{#if generating_places}
				<div
					class="glass rounded-2xl border border-paper-border p-6 text-center text-paper-text-light md:col-span-2"
				>
					<div class="flex items-center justify-center gap-3 text-paper-text">
						<svg class="h-5 w-5 animate-spin" fill="none" viewBox="0 0 24 24">
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
						Mapping new towns...
					</div>
				</div>
			{:else if generated_places.length === 0}
				<div
					class="glass rounded-2xl border border-paper-border p-6 text-center text-paper-text-light"
				>
					Click generate to populate your world map.
				</div>
			{:else}
				{#each generated_places as place (place.name)}
					<div class="glass hover-lift rounded-2xl border border-paper-border p-6">
						<p class="font-serif text-2xl text-paper-text">{place.name}</p>
						<p class="text-xs tracking-wide text-paper-text-muted uppercase">{place.region}</p>
						<p class="mt-3 text-sm text-paper-text-light">{place.description}</p>
						<p class="mt-2 text-xs text-paper-text-muted">Population ~ {place.population}</p>
					</div>
				{/each}
			{/if}
		</section>
		<section class="mt-16">
			<div class="card-elevated glow-accent overflow-hidden p-8 text-center lg:p-12">
				<h2 class="mb-4 font-serif text-2xl font-semibold text-paper-text">
					Keep your worldbuilding flowing
				</h2>
				<p class="mx-auto mb-8 max-w-lg text-paper-text-light">
					Download Fictioneer to draft scenes in your new locations or explore more tools for
					characters and plots.
				</p>
				<div class="flex flex-wrap justify-center gap-4">
					<a href={resolve('/download')} class="btn-primary">
						<span class="flex items-center gap-2">
							<svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
								<path
									stroke-linecap="round"
									stroke-linejoin="round"
									stroke-width="2"
									d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"
								/>
							</svg>
							Download Fictioneer
						</span>
					</a>
					<a href={resolve('/tools')} class="btn-ghost">Explore More Tools</a>
				</div>
			</div>
		</section>
	</main>
</div>
