<script lang="ts">
	import { resolve } from '$app/paths';
	import { client } from '$lib/config';

	const FANDOMS = [
		{ value: 'wizarding', label: 'Wizarding World' },
		{ value: 'space_opera', label: 'Galactic Saga' },
		{ value: 'superhero', label: 'Superhero Universe' },
		{ value: 'pirate', label: 'Pirate Epic' },
		{ value: 'anime', label: 'Anime Ensemble' },
		{ value: 'video_game', label: 'Video Game' }
	];

	const SHIP_TYPES = [
		{ value: 'friends_to_lovers', label: 'Friends to Lovers' },
		{ value: 'rivals', label: 'Rivals' },
		{ value: 'found_family', label: 'Found Family' },
		{ value: 'mentor_student', label: 'Mentor & Protégé' }
	];

	const TONES = [
		{ value: 'adventurous', label: 'Adventurous' },
		{ value: 'fluffy', label: 'Fluffy' },
		{ value: 'angsty', label: 'Angsty' },
		{ value: 'dramatic', label: 'Dramatic' }
	];

	type FanStory = {
		title: string;
		tagline: string;
		sections: Array<{ heading: string; text: string }>;
	};

	let selected_fandom = $state('wizarding');
	let selected_ship = $state('friends_to_lovers');
	let selected_tone = $state('adventurous');
	let canon_alignment = $state(70);
	let custom_prompt = $state(
		'after a canon battle, they co-run detention and uncover a conspiracy'
	);
	let generated_story: FanStory | null = $state(null);
	let generating_story = $state(false);
	let error_message = $state('');

	async function generate_story() {
		if (generating_story) return;
		generating_story = true;
		error_message = '';
		generated_story = null;

		const result_section = document.getElementById('result-section');
		result_section?.scrollIntoView({ behavior: 'smooth', block: 'start' });

		try {
			const response = await client.api.marketing['generate-fan-fiction'].$post({
				json: {
					fandom: selected_fandom,
					ship_type: selected_ship,
					tone: selected_tone,
					canon_alignment: Number(canon_alignment),
					prompt_details: custom_prompt
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
			console.error('Fan fiction generation error:', error);
			error_message =
				error instanceof Error ? error.message : 'Failed to generate prompt. Please try again.';
		} finally {
			generating_story = false;
		}
	}
</script>

<svelte:head>
	<title>AI Fan Fiction Generator - Prompt Ideas | Fictioneer</title>
	<meta
		name="description"
		content="Generate AI fan fiction prompts with canon alignment, relationship dynamics, and tone-aware beats."
	/>
	<meta
		name="keywords"
		content="AI fan fiction generator, fanfic prompts, AU prompt generator, fandom writing tools, AI writing tools"
	/>
	<meta property="og:title" content="AI Fan Fiction Generator - Prompt Ideas | Fictioneer" />
	<meta
		property="og:description"
		content="Generate AI fan fiction prompts with canon alignment, ship dynamics, and tone controls."
	/>
	<meta name="twitter:title" content="AI Fan Fiction Generator - Prompt Ideas | Fictioneer" />
	<meta
		name="twitter:description"
		content="Generate AI fan fiction prompts with canon alignment, ship dynamics, and tone controls."
	/>
	<link rel="canonical" href="https://fictioneer.app/tools/fan-fiction-story-generator" />
</svelte:head>

<div class="min-h-screen bg-paper-beige">
	<div
		class="absolute inset-0 bg-linear-to-br from-paper-beige via-paper-cream/50 to-paper-white/30"
	></div>
	<div class="absolute inset-0" style:background="var(--gradient-radial)"></div>

	<main class="relative z-10 mx-auto max-w-4xl px-4 py-12 pt-20 sm:px-6 lg:px-8">
		<section class="text-center">
			<div class="mb-4 text-5xl">⭐</div>
			<h1 class="font-serif text-4xl font-bold text-paper-text">AI Fan Fiction Generator</h1>
			<p class="mt-4 text-lg text-paper-text-light">
				Specify your fandom, ship style, tone, and canon alignment. We spin up AI prompts with
				easter eggs.
			</p>
		</section>

		<div class="glass mt-8 rounded-2xl border border-paper-border p-8">
			<form
				class="space-y-6"
				onsubmit={(event) => {
					event.preventDefault();
					generate_story();
				}}
			>
				<div class="grid gap-4 md:grid-cols-2">
					<label class="text-sm text-paper-text-light">
						<span class="mb-1 block">Fandom</span>
						<select class="input" bind:value={selected_fandom}>
							{#each FANDOMS as fandom (fandom.value)}
								<option value={fandom.value}>{fandom.label}</option>
							{/each}
						</select>
					</label>

					<label class="text-sm text-paper-text-light">
						<span class="mb-1 block">Relationship Dynamic</span>
						<select class="input" bind:value={selected_ship}>
							{#each SHIP_TYPES as ship (ship.value)}
								<option value={ship.value}>{ship.label}</option>
							{/each}
						</select>
					</label>

					<label class="text-sm text-paper-text-light">
						<span class="mb-1 block">Tone</span>
						<select class="input" bind:value={selected_tone}>
							{#each TONES as tone (tone.value)}
								<option value={tone.value}>{tone.label}</option>
							{/each}
						</select>
					</label>

					<label class="text-sm text-paper-text-light">
						<span class="mb-1 block">Canon Alignment ({canon_alignment}%)</span>
						<input type="range" min="0" max="100" bind:value={canon_alignment} />
					</label>
				</div>

				<label class="text-sm text-paper-text-light">
					<span class="mb-1 block">Prompt Details</span>
					<textarea class="input" rows="3" bind:value={custom_prompt}></textarea>
				</label>

				<button type="submit" class="btn-primary w-full py-3">Generate Prompt</button>
			</form>
		</div>

		<section id="result-section" class="mt-8 space-y-4" aria-live="polite">
			{#if error_message}
				<div class="glass border border-red-200 bg-red-50/80 p-4 text-sm text-red-700">
					{error_message}
				</div>
			{/if}
			{#if generating_story}
				<div
					class="glass rounded-2xl border border-paper-border p-6 text-center text-paper-text-light"
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
						Generating your prompt...
					</div>
				</div>
			{:else if !generated_story}
				<div
					class="glass rounded-2xl border border-paper-border p-6 text-center text-paper-text-light"
				>
					Your multi-beat prompt will appear here.
				</div>
			{:else}
				<div class="glass rounded-2xl border border-paper-border p-6">
					<h2 class="font-serif text-2xl text-paper-text">{generated_story.title}</h2>
					<p class="mt-1 text-sm text-paper-text-muted">{generated_story.tagline}</p>
				</div>
				{#each generated_story.sections as section (section.heading)}
					<div class="glass rounded-2xl border border-paper-border p-5">
						<p class="font-serif text-xl text-paper-text">{section.heading}</p>
						<p class="mt-2 text-sm text-paper-text-light">{section.text}</p>
					</div>
				{/each}
			{/if}
		</section>
		<section class="mt-16">
			<div class="card-elevated glow-accent overflow-hidden p-8 text-center lg:p-12">
				<h2 class="mb-4 font-serif text-2xl font-semibold text-paper-text">
					Spin a full draft with AI
				</h2>
				<p class="mx-auto mb-8 max-w-lg text-paper-text-light">
					Download Fictioneer to draft fan fiction chapters faster, or explore more tools for plots,
					titles, and characters.
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
