<script lang="ts">
	import { resolve } from '$app/paths';
	import { client } from '$lib/config';

	const GENRES = [
		{ value: 'fantasy', label: 'Fantasy', icon: '🏰' },
		{ value: 'sci-fi', label: 'Sci-Fi', icon: '🚀' },
		{ value: 'mystery', label: 'Mystery', icon: '🔍' },
		{ value: 'romance', label: 'Romance', icon: '💕' },
		{ value: 'horror', label: 'Horror', icon: '👻' },
		{ value: 'drama', label: 'Drama', icon: '🎭' },
		{ value: 'comedy', label: 'Comedy', icon: '😄' },
		{ value: 'adventure', label: 'Adventure', icon: '⚔️' },
		{ value: 'thriller', label: 'Thriller', icon: '😰' }
	] as const;

	const SETTINGS = [
		{ value: 'modern', label: 'Modern', icon: '🏙️' },
		{ value: 'historical', label: 'Historical', icon: '🏛️' },
		{ value: 'futuristic', label: 'Future', icon: '🌌' },
		{ value: 'fantasy_world', label: 'Fantasy', icon: '✨' },
		{ value: 'small_town', label: 'Small Town', icon: '🏘️' },
		{ value: 'big_city', label: 'Big City', icon: '🌃' }
	] as const;

	const TONES = [
		{ value: 'serious', label: 'Serious', icon: '📜' },
		{ value: 'lighthearted', label: 'Light', icon: '☀️' },
		{ value: 'dark', label: 'Dark', icon: '🌑' },
		{ value: 'inspirational', label: 'Uplifting', icon: '🌟' },
		{ value: 'mysterious', label: 'Mysterious', icon: '🔮' },
		{ value: 'humorous', label: 'Funny', icon: '🎪' }
	] as const;

	const THEMES_BY_GENRE: Record<string, Array<{ value: string; label: string }>> = {
		fantasy: [
			{ value: 'Good vs evil', label: 'Good vs Evil' },
			{ value: 'The chosen one', label: 'Chosen One' },
			{ value: 'Quest for power', label: 'Quest for Power' },
			{ value: 'Ancient prophecies', label: 'Prophecy' },
			{ value: 'Magical coming of age', label: 'Coming of Age' }
		],
		'sci-fi': [
			{ value: 'Artificial intelligence', label: 'AI' },
			{ value: 'Time travel paradox', label: 'Time Travel' },
			{ value: 'Space exploration', label: 'Space' },
			{ value: 'Dystopian future', label: 'Dystopia' },
			{ value: 'Alien contact', label: 'First Contact' }
		],
		mystery: [
			{ value: 'Murder investigation', label: 'Murder' },
			{ value: 'Missing person', label: 'Missing Person' },
			{ value: 'Corporate conspiracy', label: 'Conspiracy' },
			{ value: 'Family secrets', label: 'Family Secrets' },
			{ value: 'Cold case', label: 'Cold Case' }
		],
		romance: [
			{ value: 'Second chance love', label: 'Second Chance' },
			{ value: 'Enemies to lovers', label: 'Enemies to Lovers' },
			{ value: 'Forbidden romance', label: 'Forbidden' },
			{ value: 'Friends to lovers', label: 'Friends to Lovers' },
			{ value: 'Love triangle', label: 'Love Triangle' }
		],
		horror: [
			{ value: 'Haunted house', label: 'Haunted House' },
			{ value: 'Psychological terror', label: 'Psychological' },
			{ value: 'Ancient curse', label: 'Curse' },
			{ value: 'Monster hunting', label: 'Monster' },
			{ value: 'Isolation fear', label: 'Isolation' }
		],
		drama: [
			{ value: 'Family dysfunction', label: 'Family' },
			{ value: 'Personal redemption', label: 'Redemption' },
			{ value: 'Moral dilemma', label: 'Moral Dilemma' },
			{ value: 'Loss and grief', label: 'Grief' },
			{ value: 'Identity crisis', label: 'Identity' }
		],
		comedy: [
			{ value: 'Mistaken identity', label: 'Mistaken Identity' },
			{ value: 'Romantic mishaps', label: 'Romantic Comedy' },
			{ value: 'Office comedy', label: 'Workplace' },
			{ value: 'Family chaos', label: 'Family Chaos' },
			{ value: 'Dating disasters', label: 'Dating' }
		],
		adventure: [
			{ value: 'Treasure hunt', label: 'Treasure Hunt' },
			{ value: 'Survival challenge', label: 'Survival' },
			{ value: 'Rescue mission', label: 'Rescue Mission' },
			{ value: 'Lost civilization', label: 'Lost World' },
			{ value: 'Maritime adventure', label: 'Sea Adventure' }
		],
		thriller: [
			{ value: 'Government conspiracy', label: 'Government' },
			{ value: 'Corporate espionage', label: 'Espionage' },
			{ value: 'Assassination plot', label: 'Assassination' },
			{ value: 'Double agent', label: 'Double Agent' },
			{ value: 'Cyber warfare', label: 'Cyber' }
		]
	};

	interface GeneratedStory {
		story: string;
		metadata: {
			genre: string;
			theme: string;
			setting: string;
			tone: string;
			word_count: number;
		};
	}

	let generating_story = $state(false);
	let generated_story: GeneratedStory | null = $state(null);
	let error_message = $state('');

	let selected_genre = $state('fantasy');
	let selected_theme = $state('Good vs evil');
	let selected_setting = $state('fantasy_world');
	let selected_tone = $state('serious');
	let word_count = $state(300);
	let story_context = $state('');

	let streaming_text = $state('');
	let is_streaming = $state(false);
	let stream_completed = $state(false);
	let copied = $state(false);

	let current_themes = $derived(THEMES_BY_GENRE[selected_genre] || []);

	function handle_genre_change(value: string) {
		selected_genre = value;
		const themes = THEMES_BY_GENRE[value] || [];
		if (themes.length > 0 && !themes.some((t) => t.value === selected_theme)) {
			selected_theme = themes[0].value;
		}
	}

	async function generate_story() {
		if (generating_story) return;

		generating_story = true;
		error_message = '';
		generated_story = null;
		streaming_text = '';
		is_streaming = true;
		stream_completed = false;

		const story_section = document.getElementById('story-section');
		story_section?.scrollIntoView({ behavior: 'smooth', block: 'start' });

		try {
			const response = await client.api.marketing['generate-story'].$post(
				{
					json: {
						genre: selected_genre,
						theme: selected_theme,
						setting: selected_setting,
						tone: selected_tone,
						word_count: word_count,
						context: story_context
					}
				},
				{ headers: { Accept: 'text/plain+stream' } }
			);

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

			if (response.body) {
				const reader = response.body.getReader();
				const decoder = new TextDecoder();

				try {
					while (true) {
						const { done, value } = await reader.read();
						if (done) {
							stream_completed = true;
							break;
						}
						const chunk = decoder.decode(value, { stream: true });
						streaming_text += chunk;
						await new Promise((resolve) => setTimeout(resolve, 30));
					}

					generated_story = {
						story: streaming_text,
						metadata: {
							genre: selected_genre,
							theme: selected_theme,
							setting: selected_setting,
							tone: selected_tone,
							word_count: streaming_text.trim().split(/\s+/).length
						}
					};
				} finally {
					reader.releaseLock();
				}
			}
		} catch (error) {
			console.error('Error generating story:', error);
			error_message = error instanceof Error ? error.message : 'Failed to generate story.';
			is_streaming = false;
			streaming_text = '';
		} finally {
			generating_story = false;
			is_streaming = false;
		}
	}

	function copy_story_to_clipboard() {
		if (!generated_story) return;
		navigator.clipboard.writeText(generated_story.story).then(() => {
			copied = true;
			setTimeout(() => (copied = false), 2000);
		});
	}
</script>

<svelte:head>
	<title>AI Story Generator - Free AI Story Ideas & Drafts | Fictioneer</title>
	<meta
		name="description"
		content="Generate AI story ideas and short drafts with genre, theme, and setting controls. Free, fast, and writer-focused."
	/>
	<meta
		name="keywords"
		content="AI story generator, free AI story generator, AI story ideas, AI writing tools, AI fiction generator, AI short story, AI writing assistant"
	/>
	<link rel="canonical" href="https://fictioneer.app/tools/ai-story-generator" />
	<meta property="og:title" content="AI Story Generator - Free Story Ideas & Drafts | Fictioneer" />
	<meta
		property="og:description"
		content="Generate AI story ideas and short drafts with genre, theme, and setting controls."
	/>
	<meta property="og:url" content="https://fictioneer.app/tools/ai-story-generator" />
	<meta property="og:type" content="website" />
	<meta
		name="twitter:title"
		content="AI Story Generator - Free Story Ideas & Drafts | Fictioneer"
	/>
	<meta
		name="twitter:description"
		content="Generate AI story ideas and short drafts with genre, theme, and setting controls."
	/>
</svelte:head>

<main class="mx-auto max-w-6xl px-4 py-16 sm:px-6 lg:py-24">
	<!-- Hero Section -->
	<div class="animate-fade-in-up relative mb-12 text-center">
		<div
			class="aurora-blob-subtle absolute -top-16 left-1/3 h-48 w-48 rounded-full bg-indigo-500/20"
		></div>
		<div
			class="aurora-blob-subtle absolute -top-8 right-1/3 h-32 w-32 rounded-full bg-purple-500/20"
		></div>

		<div class="relative">
			<a
				href={resolve('/tools')}
				class="mb-6 inline-flex items-center gap-2 text-sm text-paper-text-muted transition-colors hover:text-paper-accent"
			>
				<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
					<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"
					></path>
				</svg>
				All Tools
			</a>

			<h1 class="mb-4 font-serif text-4xl tracking-tight text-paper-text sm:text-5xl lg:text-6xl">
				AI Story <span class="gradient-text">Generator</span>
			</h1>
			<p class="mx-auto max-w-2xl text-lg text-paper-text-light">
				Generate AI story ideas and short drafts in seconds. Tune the genre, theme, and tone to
				match your vision.
			</p>
		</div>
	</div>

	<!-- Story Generator Form -->
	<div class="animate-fade-in-up mb-16" style:animation-delay="0.1s">
		<form
			onsubmit={(e) => {
				e.preventDefault();
				generate_story();
			}}
			class="card-elevated overflow-hidden"
		>
			<!-- Genre Selection -->
			<div class="border-b border-paper-border p-6">
				<span class="mb-4 block text-sm font-medium text-paper-text-muted">Genre</span>
				<div class="flex flex-wrap gap-2">
					{#each GENRES as genre (genre.value)}
						<button
							type="button"
							onclick={() => handle_genre_change(genre.value)}
							disabled={generating_story}
							class="group relative overflow-hidden rounded-xl px-4 py-2.5 text-sm font-medium transition-all duration-200 {selected_genre ===
							genre.value
								? 'bg-linear-to-r from-indigo-500 to-purple-500 text-white shadow-md'
								: 'bg-paper-beige text-paper-text-light hover:bg-paper-gray hover:text-paper-text'}"
						>
							<span class="flex items-center gap-2">
								<span class="text-base">{genre.icon}</span>
								{genre.label}
							</span>
						</button>
					{/each}
				</div>
			</div>

			<!-- Theme Selection -->
			<div class="border-b border-paper-border p-6">
				<span class="mb-4 block text-sm font-medium text-paper-text-muted">Theme</span>
				<div class="flex flex-wrap gap-2">
					{#each current_themes as theme (theme.value)}
						<button
							type="button"
							onclick={() => (selected_theme = theme.value)}
							disabled={generating_story}
							class="rounded-full px-4 py-2 text-sm font-medium transition-all duration-200 {selected_theme ===
							theme.value
								? 'bg-paper-accent text-white'
								: 'bg-paper-beige text-paper-text-light hover:bg-paper-gray hover:text-paper-text'}"
						>
							{theme.label}
						</button>
					{/each}
				</div>
			</div>

			<!-- Setting and Tone -->
			<div class="grid border-b border-paper-border sm:grid-cols-2">
				<div class="border-b border-paper-border p-6 sm:border-r sm:border-b-0">
					<span class="mb-4 block text-sm font-medium text-paper-text-muted">Setting</span>
					<div class="flex flex-wrap gap-2">
						{#each SETTINGS as setting (setting.value)}
							<button
								type="button"
								onclick={() => (selected_setting = setting.value)}
								disabled={generating_story}
								class="flex items-center gap-1.5 rounded-lg px-3 py-2 text-sm transition-all duration-200 {selected_setting ===
								setting.value
									? 'bg-paper-accent/10 text-paper-accent ring-1 ring-paper-accent'
									: 'bg-paper-beige text-paper-text-light hover:bg-paper-gray'}"
							>
								<span>{setting.icon}</span>
								{setting.label}
							</button>
						{/each}
					</div>
				</div>

				<div class="p-6">
					<span class="mb-4 block text-sm font-medium text-paper-text-muted">Tone</span>
					<div class="flex flex-wrap gap-2">
						{#each TONES as tone (tone.value)}
							<button
								type="button"
								onclick={() => (selected_tone = tone.value)}
								disabled={generating_story}
								class="flex items-center gap-1.5 rounded-lg px-3 py-2 text-sm transition-all duration-200 {selected_tone ===
								tone.value
									? 'bg-paper-accent/10 text-paper-accent ring-1 ring-paper-accent'
									: 'bg-paper-beige text-paper-text-light hover:bg-paper-gray'}"
							>
								<span>{tone.icon}</span>
								{tone.label}
							</button>
						{/each}
					</div>
				</div>
			</div>

			<!-- Word Count and Context -->
			<div class="grid border-b border-paper-border sm:grid-cols-2">
				<div class="border-b border-paper-border p-6 sm:border-r sm:border-b-0">
					<label for="word-count" class="mb-4 block text-sm font-medium text-paper-text-muted">
						Length: <span class="font-semibold text-paper-accent">{word_count} words</span>
					</label>
					<input
						id="word-count"
						type="range"
						min="100"
						max="800"
						step="50"
						bind:value={word_count}
						disabled={generating_story}
						class="h-2 w-full cursor-pointer appearance-none rounded-lg bg-paper-beige accent-paper-accent"
					/>
					<div class="mt-2 flex justify-between text-xs text-paper-text-muted">
						<span>Short</span>
						<span>Medium</span>
						<span>Long</span>
					</div>
				</div>

				<div class="p-6">
					<label for="context" class="mb-4 block text-sm font-medium text-paper-text-muted">
						Additional Context <span class="font-normal text-paper-text-muted">(optional)</span>
					</label>
					<textarea
						id="context"
						bind:value={story_context}
						placeholder="Add characters, specific scenes, or story ideas..."
						disabled={generating_story}
						class="input min-h-20 resize-none text-sm"
					></textarea>
				</div>
			</div>

			<!-- Generate Button -->
			<div class="bg-paper-beige/30 p-6">
				<button
					type="submit"
					disabled={generating_story}
					class="btn-primary w-full py-4 text-base disabled:cursor-not-allowed disabled:opacity-60"
				>
					{#if generating_story}
						<span class="flex items-center justify-center gap-3">
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
							Writing your story...
						</span>
					{:else}
						<span class="flex items-center justify-center gap-2">
							<svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
								<path
									stroke-linecap="round"
									stroke-linejoin="round"
									stroke-width="2"
									d="M13 10V3L4 14h7v7l9-11h-7z"
								></path>
							</svg>
							Generate Story
						</span>
					{/if}
				</button>
			</div>
		</form>
	</div>

	<!-- Generated Story Display -->
	<div id="story-section" class="animate-fade-in-up" style:animation-delay="0.2s">
		{#if error_message}
			<div class="mb-6 rounded-2xl border border-red-200 bg-red-50 p-5 text-sm text-red-600">
				<div class="flex items-start gap-3">
					<svg class="mt-0.5 h-5 w-5 shrink-0" fill="currentColor" viewBox="0 0 20 20">
						<path
							fill-rule="evenodd"
							d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
							clip-rule="evenodd"
						></path>
					</svg>
					{error_message}
				</div>
			</div>
		{/if}

		{#if is_streaming || generated_story}
			<div class="card-elevated overflow-hidden">
				<!-- Header -->
				<div
					class="flex items-center justify-between border-b border-paper-border bg-paper-beige/30 px-6 py-4"
				>
					<div class="flex items-center gap-3">
						<div
							class="flex h-10 w-10 items-center justify-center rounded-xl bg-linear-to-br from-indigo-500 to-purple-500 text-lg text-white"
						>
							📖
						</div>
						<div>
							<h2 class="font-serif text-lg font-semibold text-paper-text">Your Story</h2>
							{#if generated_story && !is_streaming}
								<p class="text-xs text-paper-text-muted">
									{generated_story.metadata.word_count} words
								</p>
							{/if}
						</div>
					</div>
					{#if generated_story && !is_streaming}
						<button onclick={copy_story_to_clipboard} class="btn-ghost px-4 py-2 text-sm">
							<span class="flex items-center gap-2">
								{#if copied}
									<svg
										class="h-4 w-4 text-paper-lime"
										fill="none"
										stroke="currentColor"
										viewBox="0 0 24 24"
									>
										<path
											stroke-linecap="round"
											stroke-linejoin="round"
											stroke-width="2"
											d="M5 13l4 4L19 7"
										></path>
									</svg>
									Copied!
								{:else}
									<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
										<path
											stroke-linecap="round"
											stroke-linejoin="round"
											stroke-width="2"
											d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z"
										></path>
									</svg>
									Copy
								{/if}
							</span>
						</button>
					{/if}
				</div>

				<!-- Story Content -->
				<div class="p-8 lg:p-12">
					<div
						class="prose mx-auto max-w-none font-serif text-lg leading-loose text-paper-text-light lg:text-xl"
					>
						{#each (is_streaming ? streaming_text : generated_story?.story || '').split('\n\n') as paragraph, i (i)}
							{#if paragraph.trim()}
								<p class="mb-6">{paragraph.replace(/\n/g, ' ')}</p>
							{/if}
						{/each}
						{#if is_streaming && !stream_completed}
							<span class="inline-block h-6 w-1 animate-pulse bg-paper-accent"></span>
						{/if}
					</div>

					<!-- Metadata Tags -->
					{#if generated_story && !is_streaming}
						<div
							class="mt-10 flex flex-wrap justify-center gap-3 border-t border-paper-border pt-8"
						>
							<span class="rounded-full bg-paper-beige px-4 py-1.5 text-sm text-paper-text-muted">
								{GENRES.find((g) => g.value === generated_story?.metadata.genre)?.icon}
								{GENRES.find((g) => g.value === generated_story?.metadata.genre)?.label}
							</span>
							<span class="rounded-full bg-paper-beige px-4 py-1.5 text-sm text-paper-text-muted">
								{generated_story.metadata.theme}
							</span>
							<span class="rounded-full bg-paper-beige px-4 py-1.5 text-sm text-paper-text-muted">
								{TONES.find((t) => t.value === generated_story?.metadata.tone)?.icon}
								{TONES.find((t) => t.value === generated_story?.metadata.tone)?.label}
							</span>
						</div>
					{/if}
				</div>
			</div>
		{:else}
			<!-- Empty State -->
			<div class="card py-20 text-center">
				<div class="mb-6 flex justify-center">
					<div
						class="flex h-20 w-20 items-center justify-center rounded-2xl bg-linear-to-br from-indigo-100 to-purple-100 text-4xl"
					>
						📖
					</div>
				</div>
				<h3 class="mb-2 font-serif text-xl font-semibold text-paper-text">Your story awaits</h3>
				<p class="mx-auto max-w-sm text-paper-text-muted">
					Select your options above and click "Generate Story" to create something unique.
				</p>
			</div>
		{/if}
	</div>

	<!-- Features Section -->
	<div class="animate-fade-in-up mt-20" style:animation-delay="0.3s">
		<h2 class="mb-8 text-center font-serif text-2xl font-semibold text-paper-text">
			Why writers love this tool
		</h2>
		<div class="grid gap-5 sm:grid-cols-3">
			{#each [{ icon: '⚡', title: 'Instant Results', desc: 'Get a complete story in seconds, not hours. Perfect for inspiration or quick drafts.', gradient: 'from-amber-500 to-orange-500' }, { icon: '🎯', title: 'Genre-Specific', desc: 'Each genre has tailored themes and settings designed by writers, for writers.', gradient: 'from-emerald-500 to-teal-500' }, { icon: '✨', title: 'Live Streaming', desc: 'Watch your story appear word by word, just like magic unfolding before your eyes.', gradient: 'from-purple-500 to-pink-500' }] as feature (feature.title)}
				<div class="card group overflow-hidden p-6 transition-all hover:shadow-lg">
					<div
						class="mb-4 flex h-12 w-12 items-center justify-center rounded-xl bg-linear-to-br text-xl transition-transform duration-300 group-hover:scale-110 {feature.gradient}"
					>
						{feature.icon}
					</div>
					<h3 class="mb-2 font-serif text-lg font-semibold text-paper-text">{feature.title}</h3>
					<p class="text-sm leading-relaxed text-paper-text-light">{feature.desc}</p>
				</div>
			{/each}
		</div>
	</div>

	<!-- CTA Section -->
	<div class="animate-fade-in-up mt-16" style:animation-delay="0.4s">
		<div class="card-elevated glow-accent overflow-hidden p-8 text-center lg:p-12">
			<h2 class="mb-4 font-serif text-2xl font-semibold text-paper-text">
				Keep your momentum going
			</h2>
			<p class="mx-auto mb-8 max-w-lg text-paper-text-light">
				Draft longer projects in Fictioneer or jump to the next tool to keep building your world.
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
	</div>
</main>
