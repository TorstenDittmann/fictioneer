<script lang="ts">
	import { client } from '$lib/config';

	const GENRES = [
		{ value: 'romance', label: 'Romance' },
		{ value: 'dark_romance', label: 'Dark Romance' },
		{ value: 'drama', label: 'Drama' },
		{ value: 'sci_fantasy', label: 'Sci-Fantasy' }
	];

	const TONES = [
		{ value: 'tender', label: 'Tender' },
		{ value: 'playful', label: 'Playful' },
		{ value: 'intense', label: 'Intense' },
		{ value: 'slow_burn', label: 'Slow Burn' }
	];

	const TROPES = [
		'enemies to lovers',
		'fake dating',
		'secret royalty',
		'forced proximity',
		'only one bed',
		'age gap',
		'after hours office',
		'celebrity x civilian'
	];

	type AdultStory = {
		title: string;
		paragraphs: string[];
		steam: string;
	};

	let selected_genre = $state('romance');
	let selected_tone = $state('tender');
	let steam_level = $state(60);
	let trope_input = $state(['enemies to lovers', 'only one bed']);
	let custom_prompt = $state('two rival sommeliers stranded during a snowstorm tasting event');
	let allow_mature = $state(false);
	let generated_story: AdultStory | null = $state(null);
	let generating_story = $state(false);
	let error_message = $state('');

	function toggle_trope(trope: string) {
		if (trope_input.includes(trope)) {
			trope_input = trope_input.filter((item) => item !== trope);
		} else {
			const updated = [...trope_input, trope];
			trope_input = updated.slice(-3);
		}
	}

	async function generate_story() {
		if (!allow_mature || generating_story) {
			if (!allow_mature) {
				error_message = 'Please confirm you are 18+ before generating mature content.';
			}
			return;
		}

		generating_story = true;
		error_message = '';
		generated_story = null;

		try {
			const response = await client.api.marketing['generate-adult-story'].$post({
				json: {
					genre: selected_genre,
					tone: selected_tone,
					steam_level: Number(steam_level),
					tropes: trope_input,
					custom_prompt
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
				throw new Error(error_data.error || 'Failed to generate story');
			}

			const data = await response.json();
			generated_story = data;
		} catch (error) {
			console.error('Adult story generation error:', error);
			error_message =
				error instanceof Error ? error.message : 'Failed to generate story. Please try again.';
		} finally {
			generating_story = false;
		}
	}
</script>

<svelte:head>
	<title>Adult Story Generator | Fictioneer</title>
	<meta
		name="description"
		content="Consent-first, AI-assisted adult fiction ideas with tone controls, trope toggles, and adjustable steam levels."
	/>
	<link rel="canonical" href="https://fictioneer.app/tools/adult-story-generator" />
</svelte:head>

<div class="min-h-screen bg-paper-beige">
	<div
		class="absolute inset-0 bg-linear-to-br from-paper-beige via-paper-cream/50 to-paper-white/30"
	></div>
	<div class="absolute inset-0" style:background="var(--gradient-radial)"></div>

	<main class="relative z-10 mx-auto max-w-4xl px-4 py-12 pt-24 sm:px-6 lg:px-8">
		<section class="glass rounded-2xl border border-paper-border p-8 text-center">
			<h1 class="font-serif text-4xl text-paper-text">Adult Story Generator</h1>
			<p class="mt-3 text-sm text-paper-text-light">
				18+ only. Check the consent box to unlock mature prompts tailored to your tropes, tones, and
				steam level.
			</p>
			<label class="mt-4 inline-flex items-center gap-3 text-paper-text">
				<input type="checkbox" bind:checked={allow_mature} class="accent-paper-accent" />
				<span>I confirm I am 18+ and agree to view mature creative content.</span>
			</label>
		</section>

		<form
			class="mt-10 space-y-6"
			onsubmit={(event) => {
				event.preventDefault();
				generate_story();
			}}
		>
			<div class="glass rounded-2xl border border-paper-border p-6">
				<div class="grid gap-4 md:grid-cols-2">
					<label class="text-sm text-paper-text-light">
						<span class="mb-1 block">Genre</span>
						<select class="field" bind:value={selected_genre}>
							{#each GENRES as option (option.value)}
								<option value={option.value}>{option.label}</option>
							{/each}
						</select>
					</label>

					<label class="text-sm text-paper-text-light">
						<span class="mb-1 block">Tone</span>
						<select class="field" bind:value={selected_tone}>
							{#each TONES as option (option.value)}
								<option value={option.value}>{option.label}</option>
							{/each}
						</select>
					</label>

					<label class="text-sm text-paper-text-light">
						<span class="mb-1 block">Steam Level ({steam_level}%)</span>
						<input type="range" min="0" max="100" bind:value={steam_level} />
					</label>
				</div>

				<p class="mt-4 text-xs tracking-wide text-paper-text-muted uppercase">
					Tropes (pick up to 3)
				</p>
				<div class="mt-3 flex flex-wrap gap-3">
					{#each TROPES as trope (trope)}
						<button
							type="button"
							class={`rounded-full border px-4 py-2 text-sm transition ${
								trope_input.includes(trope)
									? 'border-paper-accent bg-paper-accent/10 text-paper-accent'
									: 'border-paper-border text-paper-text-light'
							}`}
							onclick={() => toggle_trope(trope)}
						>
							{trope}
						</button>
					{/each}
				</div>

				<label class="mt-6 block text-sm text-paper-text-light">
					<span class="mb-1 block">Custom Prompt</span>
					<textarea class="field" rows="3" bind:value={custom_prompt}></textarea>
				</label>
			</div>

			<button type="submit" class="btn-primary w-full py-3" disabled={!allow_mature}>
				Generate Mature Story Idea
			</button>
		</form>

		<section class="mt-8" aria-live="polite">
			{#if error_message}
				<div class="glass border border-red-200 bg-red-50/80 p-4 text-sm text-red-700">
					{error_message}
				</div>
			{/if}
			{#if !generated_story}
				<div
					class="glass rounded-2xl border border-paper-border p-6 text-center text-paper-text-light"
				>
					Unlock the generator to see custom adult fiction beats.
				</div>
			{:else}
				<div class="glass rounded-2xl border border-paper-border p-6">
					<h2 class="font-serif text-2xl text-paper-text">{generated_story.title}</h2>
					<p class="mt-2 text-sm text-paper-text-muted">{generated_story.steam}</p>
					<div class="mt-4 space-y-3">
						{#each generated_story.paragraphs as paragraph (paragraph)}
							<p class="text-sm text-paper-text-light">{paragraph}</p>
						{/each}
					</div>
				</div>
			{/if}
		</section>
	</main>
</div>
