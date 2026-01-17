<script lang="ts">
	import { resolve } from '$app/paths';
	import { client } from '$lib/config';

	const GENRE_OPTIONS = [
		{ value: 'fantasy', label: 'Fantasy' },
		{ value: 'thriller', label: 'Thriller' },
		{ value: 'romance', label: 'Romance' },
		{ value: 'sci-fi', label: 'Science Fiction' },
		{ value: 'mystery', label: 'Mystery' },
		{ value: 'drama', label: 'Drama' }
	];

	const STRUCTURES = [
		{ value: 'three_act', label: 'Three-Act Structure' },
		{ value: 'heros_journey', label: "Hero's Journey" },
		{ value: 'heist', label: 'Heist / Ensemble' },
		{ value: 'romance_arc', label: 'Romantic Arc' }
	];

	const CONFLICTS = [
		{ value: 'internal', label: 'Internal Struggle' },
		{ value: 'societal', label: 'Societal Pressure' },
		{ value: 'antagonist', label: 'Rival Antagonist' },
		{ value: 'mystical', label: 'Mystical Forces' }
	];

	const TWISTS = [
		{ value: 'betrayal', label: 'Ally Betrayal' },
		{ value: 'secret_identity', label: 'Secret Identity' },
		{ value: 'ticking_clock', label: 'Hidden Deadline' },
		{ value: 'double_agent', label: 'Double Agent' },
		{ value: 'prophecy', label: 'Prophecy Reversal' }
	];

	type PlotBeat = {
		title: string;
		description: string;
		stakes: string;
	};

	type GeneratedPlot = {
		title: string;
		logline: string;
		beats: PlotBeat[];
	};

	let selected_genre = $state('fantasy');
	let selected_structure = $state('three_act');
	let selected_conflict = $state('antagonist');
	let selected_twist = $state('betrayal');
	let protagonist_prompt = $state('an exiled archivist with forbidden knowledge');
	let setting_prompt = $state('a floating capital built across tethered airships');
	let generated_plot: GeneratedPlot | null = $state(null);
	let generating_plot = $state(false);
	let error_message = $state('');

	async function generate_plot() {
		if (generating_plot) return;
		generating_plot = true;
		error_message = '';
		generated_plot = null;

		const result_section = document.getElementById('result-section');
		result_section?.scrollIntoView({ behavior: 'smooth', block: 'start' });

		try {
			const response = await client.api.marketing['generate-plot'].$post({
				json: {
					genre: selected_genre,
					structure: selected_structure,
					conflict: selected_conflict,
					twist: selected_twist,
					protagonist: protagonist_prompt,
					setting: setting_prompt
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
				throw new Error(error_data.error || 'Failed to generate plot');
			}

			const data = await response.json();
			generated_plot = data;
		} catch (error) {
			console.error('Plot generation error:', error);
			error_message =
				error instanceof Error ? error.message : 'Failed to generate plot. Please try again.';
		} finally {
			generating_plot = false;
		}
	}
</script>

<svelte:head>
	<title>AI Plot Generator - Outline Story Beats Fast | Fictioneer</title>
	<meta
		name="description"
		content="Build AI plot outlines with structures, conflicts, and twists tailored to your genre. Generate beats fast and keep momentum."
	/>
	<meta
		name="keywords"
		content="AI plot generator, AI story outline, AI story beats, plot structure generator, story outline tool"
	/>
	<meta property="og:title" content="AI Plot Generator - Outline Story Beats Fast | Fictioneer" />
	<meta
		property="og:description"
		content="Build AI plot outlines with structures, conflicts, and twists tailored to your genre."
	/>
	<meta name="twitter:title" content="AI Plot Generator - Outline Story Beats Fast | Fictioneer" />
	<meta
		name="twitter:description"
		content="Build AI plot outlines with structures, conflicts, and twists tailored to your genre."
	/>
	<link rel="canonical" href="https://fictioneer.app/tools/plot-generator" />
</svelte:head>

<div class="min-h-screen bg-paper-beige">
	<div
		class="absolute inset-0 bg-linear-to-br from-paper-beige via-paper-cream/50 to-paper-white/30"
	></div>
	<div class="absolute inset-0" style:background="var(--gradient-radial)"></div>

	<main class="relative z-10 mx-auto max-w-6xl px-4 py-12 pt-20 sm:px-6 lg:px-8">
		<section class="animate-fade-in-up mb-16 text-center">
			<div class="mb-6">
				<span class="animate-float text-6xl">🎭</span>
			</div>
			<h1 class="mb-6 font-serif text-4xl font-bold md:text-6xl">
				<span class="text-paper-text">AI Plot</span>
				<span class="gradient-text mt-2 block">Generator</span>
			</h1>
			<p class="mx-auto max-w-3xl text-xl leading-relaxed text-paper-text-light">
				Shape cinematic AI plot beats with curated structures, conflicts, and twist ideas. Ideal for
				novels, screenplays, and serialized fiction.
			</p>
		</section>

		<div class="grid gap-10 lg:grid-cols-2">
			<div class="glass hover-lift rounded-2xl border border-paper-border p-8">
				<h2 class="font-serif text-2xl font-semibold text-paper-text">Plot Controls</h2>
				<form
					class="mt-8 space-y-6"
					onsubmit={(event) => {
						event.preventDefault();
						generate_plot();
					}}
				>
					<div class="grid gap-5 md:grid-cols-2">
						<label class="text-sm text-paper-text-light">
							<span class="mb-2 block" id="genre-label">Genre</span>
							<select class="input" aria-labelledby="genre-label" bind:value={selected_genre}>
								{#each GENRE_OPTIONS as option (option.value)}
									<option value={option.value}>{option.label}</option>
								{/each}
							</select>
						</label>

						<label class="text-sm text-paper-text-light">
							<span class="mb-2 block" id="structure-label">Structure</span>
							<select
								class="input"
								aria-labelledby="structure-label"
								bind:value={selected_structure}
							>
								{#each STRUCTURES as option (option.value)}
									<option value={option.value}>{option.label}</option>
								{/each}
							</select>
						</label>

						<label class="text-sm text-paper-text-light">
							<span class="mb-2 block" id="conflict-label">Primary Conflict</span>
							<select class="input" aria-labelledby="conflict-label" bind:value={selected_conflict}>
								{#each CONFLICTS as option (option.value)}
									<option value={option.value}>{option.label}</option>
								{/each}
							</select>
						</label>

						<label class="text-sm text-paper-text-light">
							<span class="mb-2 block" id="twist-label">Signature Twist</span>
							<select class="input" aria-labelledby="twist-label" bind:value={selected_twist}>
								{#each TWISTS as option (option.value)}
									<option value={option.value}>{option.label}</option>
								{/each}
							</select>
						</label>
					</div>

					<div>
						<label for="protagonist" class="mb-2 block text-sm text-paper-text-light">
							Protagonist
						</label>
						<textarea
							class="input"
							rows="3"
							placeholder="A grumpy archivist with forbidden knowledge"
							id="protagonist"
							bind:value={protagonist_prompt}
						></textarea>
					</div>

					<div>
						<label for="setting" class="mb-2 block text-sm text-paper-text-light">Setting</label>
						<textarea
							class="input"
							rows="3"
							placeholder="A floating capital built on tethered airships"
							id="setting"
							bind:value={setting_prompt}
						></textarea>
					</div>

					<button type="submit" class="btn-primary w-full py-3" disabled={generating_plot}>
						{generating_plot ? 'Outlining...' : 'Generate Plot'}
					</button>
				</form>
			</div>

			<div id="result-section" class="space-y-6" aria-live="polite">
				{#if error_message}
					<div class="glass border border-red-200 bg-red-50/80 p-4 text-sm text-red-700">
						{error_message}
					</div>
				{/if}
				{#if generating_plot}
					<div class="glass rounded-2xl border border-paper-border p-8 text-center">
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
							Building your plot beats...
						</div>
					</div>
				{:else if !generated_plot}
					<div class="glass rounded-2xl border border-paper-border p-8 text-paper-text-light">
						Feed in your protagonist, pick a structure, and get cinematic beats within seconds.
					</div>
				{:else}
					<div class="glass rounded-2xl border border-paper-border p-6">
						<p class="text-sm text-paper-text-muted">Story Hook</p>
						<h2 class="font-serif text-3xl text-paper-text">{generated_plot.title}</h2>
						<p class="mt-3 text-sm text-paper-text-light">{generated_plot.logline}</p>
					</div>

					<div class="space-y-4">
						{#each generated_plot.beats as beat (beat.title)}
							<div class="glass hover-lift rounded-2xl border border-paper-border p-5">
								<p class="font-serif text-xl text-paper-text">{beat.title}</p>
								<p class="mt-2 text-sm text-paper-text-light">{beat.description}</p>
								<p class="mt-3 text-xs tracking-wide text-paper-text-muted uppercase">
									{beat.stakes}
								</p>
							</div>
						{/each}
					</div>

					<div class="glass rounded-2xl border border-paper-border p-5 text-center">
						<p class="text-sm text-paper-text-light">
							Ready for prose? Send this outline into the AI Story Generator to expand each beat
							into a full draft.
						</p>
						<a
							class="btn-secondary mt-4 inline-flex justify-center"
							href={resolve('/tools/ai-story-generator')}
						>
							Continue Writing
						</a>
					</div>
				{/if}
			</div>
		</div>
		<section class="mt-16">
			<div class="card-elevated glow-accent overflow-hidden p-8 text-center lg:p-12">
				<h2 class="mb-4 font-serif text-2xl font-semibold text-paper-text">
					Keep building your story engine
				</h2>
				<p class="mx-auto mb-8 max-w-lg text-paper-text-light">
					Draft inside Fictioneer or explore more tools to keep the creative momentum going.
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
