<script lang="ts">
	import { resolve } from '$app/paths';
	import { client } from '$lib/config';

	interface StoryOptions {
		genres: Array<{ value: string; label: string }>;
		settings: Array<{ value: string; label: string }>;
		tones: Array<{ value: string; label: string }>;
		themes_by_genre: Record<string, string[]>;
	}

	const STORY_OPTIONS: StoryOptions = {
		genres: [
			{ value: 'fantasy', label: 'Fantasy' },
			{ value: 'sci-fi', label: 'Science Fiction' },
			{ value: 'mystery', label: 'Mystery' },
			{ value: 'romance', label: 'Romance' },
			{ value: 'horror', label: 'Horror' },
			{ value: 'drama', label: 'Drama' },
			{ value: 'comedy', label: 'Comedy' },
			{ value: 'adventure', label: 'Adventure' },
			{ value: 'thriller', label: 'Thriller' }
		],
		settings: [
			{ value: 'modern', label: 'Modern day' },
			{ value: 'historical', label: 'Historical period' },
			{ value: 'futuristic', label: 'Future/Space' },
			{ value: 'fantasy_world', label: 'Fantasy world' },
			{ value: 'small_town', label: 'Small town' },
			{ value: 'big_city', label: 'Big city' },
			{ value: 'rural', label: 'Rural/Countryside' },
			{ value: 'other', label: 'Other' }
		],
		tones: [
			{ value: 'serious', label: 'Serious' },
			{ value: 'lighthearted', label: 'Lighthearted' },
			{ value: 'dark', label: 'Dark' },
			{ value: 'inspirational', label: 'Inspirational' },
			{ value: 'mysterious', label: 'Mysterious' },
			{ value: 'romantic', label: 'Romantic' },
			{ value: 'humorous', label: 'Humorous' }
		],
		themes_by_genre: {
			fantasy: [
				'Good vs evil',
				'The chosen one',
				'Magic corruption',
				'Quest for power',
				'Ancient prophecies',
				'Dragons and kingdoms',
				'Lost civilizations',
				'Magical coming of age',
				'Elemental balance',
				'Forbidden magic'
			],
			'sci-fi': [
				'Artificial intelligence',
				'Time travel paradox',
				'Space exploration',
				'Dystopian future',
				'Genetic engineering',
				'Robot uprising',
				'Alien contact',
				'Virtual reality',
				'Climate change',
				'Human enhancement'
			],
			mystery: [
				'Murder investigation',
				'Missing person',
				'Corporate conspiracy',
				'Family secrets',
				'Cold case',
				'False identity',
				'Stolen artifacts',
				'Witness protection',
				'Serial killer',
				'Police corruption'
			],
			romance: [
				'Second chance love',
				'Enemies to lovers',
				'Forbidden romance',
				'Long distance love',
				'Arranged marriage',
				'Office romance',
				'Small town love',
				'Celebrity romance',
				'Friends to lovers',
				'Love triangle'
			],
			horror: [
				'Haunted house',
				'Demonic possession',
				'Zombie apocalypse',
				'Ancient curse',
				'Psychological terror',
				'Monster hunting',
				'Cult ritual',
				'Body horror',
				'Isolation fear',
				'Family madness'
			],
			drama: [
				'Family dysfunction',
				'Personal redemption',
				'Moral dilemma',
				'Loss and grief',
				'Social inequality',
				'Addiction recovery',
				'Coming of age',
				'Betrayal',
				'Identity crisis',
				'Forgiveness'
			],
			comedy: [
				'Mistaken identity',
				'Romantic mishaps',
				'Office comedy',
				'Family chaos',
				'Travel disasters',
				'Social awkwardness',
				'Pet antics',
				'Technology fails',
				'Dating disasters',
				'Workplace pranks'
			],
			adventure: [
				'Treasure hunt',
				'Survival challenge',
				'Exotic expedition',
				'Rescue mission',
				'Lost civilization',
				'Natural disasters',
				'Wilderness survival',
				'Underground exploration',
				'Maritime adventure',
				'Mountain climbing'
			],
			thriller: [
				'Government conspiracy',
				'Corporate espionage',
				'Kidnapping',
				'Identity theft',
				'Assassination plot',
				'Data breach',
				'Witness pursuit',
				'Double agent',
				'Financial crime',
				'Cyber warfare'
			]
		}
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

	let story_options: StoryOptions = $state(STORY_OPTIONS);
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

	let current_themes = $derived(story_options?.themes_by_genre[selected_genre] || []);

	function handle_genre_change(value: string) {
		selected_genre = value;
		const themes = story_options?.themes_by_genre[value] || [];
		if (themes.length > 0 && !themes.includes(selected_theme)) {
			selected_theme = themes[0];
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
		navigator.clipboard.writeText(generated_story.story).catch((err) => {
			console.error('Failed to copy story:', err);
		});
	}
</script>

<svelte:head>
	<title>Free AI Story Generator - Create Unique Stories Instantly | Fictioneer</title>
	<meta
		name="description"
		content="Generate unique, creative stories with our free AI story generator. Choose your genre, theme, and setting."
	/>
	<meta
		name="keywords"
		content="AI story generator, free story generator, creative writing, story ideas, fiction generator"
	/>
	<link rel="canonical" href="https://fictioneer.app/tools/ai-story-generator" />
	<meta
		property="og:title"
		content="Free AI Story Generator - Create Unique Stories | Fictioneer"
	/>
	<meta
		property="og:description"
		content="Generate creative stories instantly with AI. Choose your genre, theme, and settings."
	/>
	<meta property="og:url" content="https://fictioneer.app/tools/ai-story-generator" />
	<meta property="og:type" content="website" />
	<meta
		name="twitter:title"
		content="Free AI Story Generator - Create Unique Stories | Fictioneer"
	/>
	<meta name="twitter:description" content="Generate creative stories instantly with AI." />
</svelte:head>

<main class="mx-auto max-w-5xl px-4 py-16 sm:px-6 lg:py-24">
	<!-- Hero Section -->
	<div class="animate-fade-in-up mb-12 text-center">
		<div class="pill mx-auto mb-6 w-max">
			<span class="h-1.5 w-1.5 rounded-full bg-paper-accent"></span>
			Free to use
		</div>

		<h1 class="mb-4 font-serif text-3xl tracking-tight text-paper-text sm:text-4xl lg:text-5xl">
			AI Story <span class="gradient-text">Generator</span>
		</h1>
		<p class="mx-auto max-w-2xl text-lg text-paper-text-light">
			Create unique, engaging stories with AI. Choose your genre, theme, and settings.
		</p>
	</div>

	<!-- Story Generator Form -->
	<div class="animate-fade-in-up mb-16" style:animation-delay="0.1s">
		<div class="card-elevated overflow-hidden p-6 sm:p-8">
			<h2 class="mb-6 text-center font-serif text-xl font-semibold text-paper-text">
				Customize Your Story
			</h2>

			<form
				onsubmit={(e) => {
					e.preventDefault();
					generate_story();
				}}
				class="space-y-6"
			>
				<div class="grid gap-5 sm:grid-cols-2">
					<!-- Genre -->
					<div>
						<label for="genre" class="mb-2 block text-sm font-medium text-paper-text-light"
							>Genre</label
						>
						<select
							id="genre"
							value={selected_genre}
							onchange={(e) => handle_genre_change((e.target as HTMLSelectElement).value)}
							class="input"
							disabled={generating_story}
						>
							{#each story_options.genres as genre (genre.value)}
								<option value={genre.value}>{genre.label}</option>
							{/each}
						</select>
					</div>

					<!-- Theme -->
					<div>
						<label for="theme" class="mb-2 block text-sm font-medium text-paper-text-light"
							>Theme</label
						>
						<select
							id="theme"
							bind:value={selected_theme}
							class="input"
							disabled={generating_story}
						>
							{#each current_themes as theme (theme)}
								<option value={theme}>{theme}</option>
							{/each}
						</select>
					</div>

					<!-- Setting -->
					<div>
						<label for="setting" class="mb-2 block text-sm font-medium text-paper-text-light"
							>Setting</label
						>
						<select
							id="setting"
							bind:value={selected_setting}
							class="input"
							disabled={generating_story}
						>
							{#each story_options.settings as setting (setting.value)}
								<option value={setting.value}>{setting.label}</option>
							{/each}
						</select>
					</div>

					<!-- Tone -->
					<div>
						<label for="tone" class="mb-2 block text-sm font-medium text-paper-text-light"
							>Tone</label
						>
						<select id="tone" bind:value={selected_tone} class="input" disabled={generating_story}>
							{#each story_options.tones as tone (tone.value)}
								<option value={tone.value}>{tone.label}</option>
							{/each}
						</select>
					</div>
				</div>

				<!-- Story Context -->
				<div>
					<label for="story_context" class="mb-2 block text-sm font-medium text-paper-text-light">
						Story Context <span class="text-paper-text-muted">(Optional)</span>
					</label>
					<textarea
						id="story_context"
						bind:value={story_context}
						placeholder="Describe your story idea, characters, or specific details..."
						class="input min-h-24 resize-y"
						disabled={generating_story}
					></textarea>
				</div>

				<!-- Word Count -->
				<div>
					<label for="word_count" class="mb-2 block text-sm font-medium text-paper-text-light">
						Word Count: <span class="font-semibold text-paper-accent">{word_count}</span>
					</label>
					<input
						id="word_count"
						type="range"
						min="100"
						max="800"
						step="50"
						bind:value={word_count}
						class="h-2 w-full cursor-pointer appearance-none rounded-lg bg-paper-beige accent-paper-accent"
						disabled={generating_story}
					/>
					<div class="mt-1 flex justify-between text-xs text-paper-text-muted">
						<span>Short (100)</span>
						<span>Medium (400)</span>
						<span>Long (800)</span>
					</div>
				</div>

				<!-- Generate Button -->
				<button
					type="submit"
					disabled={generating_story}
					class="btn-primary w-full disabled:cursor-not-allowed disabled:opacity-50"
				>
					{#if generating_story}
						<span class="flex items-center justify-center gap-2">
							<svg class="h-4 w-4 animate-spin" fill="none" viewBox="0 0 24 24">
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
							Crafting Your Story...
						</span>
					{:else}
						<span class="flex items-center justify-center gap-2">
							<svg
								class="h-4 w-4"
								fill="none"
								stroke="currentColor"
								stroke-width="2"
								viewBox="0 0 24 24"
							>
								<path stroke-linecap="round" stroke-linejoin="round" d="M13 10V3L4 14h7v7l9-11h-7z"
								></path>
							</svg>
							Generate My Story
						</span>
					{/if}
				</button>
			</form>
		</div>
	</div>

	<!-- Generated Story Display -->
	<div id="story-section" class="animate-fade-in-up" style:animation-delay="0.2s">
		{#if error_message}
			<div class="mb-6 rounded-xl border border-red-200 bg-red-50 p-4">
				<p class="text-sm text-red-600">{error_message}</p>
			</div>
		{/if}

		{#if is_streaming || generated_story}
			<div class="card-elevated overflow-hidden">
				<!-- Header -->
				<div
					class="flex items-center justify-between border-b border-paper-border bg-paper-beige/30 px-6 py-4"
				>
					<h2 class="font-serif text-lg font-semibold text-paper-text">Your Story</h2>
					{#if generated_story && !is_streaming}
						<button onclick={copy_story_to_clipboard} class="btn-ghost px-3 py-1.5 text-sm">
							<span class="flex items-center gap-1.5">
								<svg
									class="h-4 w-4"
									fill="none"
									stroke="currentColor"
									stroke-width="2"
									viewBox="0 0 24 24"
								>
									<path
										stroke-linecap="round"
										stroke-linejoin="round"
										d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z"
									></path>
								</svg>
								Copy
							</span>
						</button>
					{/if}
				</div>

				<!-- Story Content -->
				<div class="p-6 sm:p-8 lg:p-10">
					<div
						class="prose mx-auto max-w-none font-serif text-base leading-relaxed lg:text-lg lg:leading-loose"
					>
						{#each (is_streaming ? streaming_text : generated_story?.story || '').split('\n\n') as paragraph, i (i)}
							<p class="mb-4 text-paper-text-light">{paragraph.replace(/\n/g, ' ')}</p>
						{/each}
						{#if is_streaming && !stream_completed}
							<span class="inline-block h-5 w-0.5 animate-pulse bg-paper-accent"></span>
						{/if}
					</div>

					<!-- Metadata -->
					{#if generated_story && !is_streaming}
						<div
							class="mt-8 flex flex-wrap justify-center gap-4 border-t border-paper-border pt-6 text-sm text-paper-text-muted"
						>
							<span
								><strong class="text-paper-accent">Genre:</strong>
								{story_options?.genres.find((g) => g.value === generated_story?.metadata.genre)
									?.label}</span
							>
							<span
								><strong class="text-paper-accent">Theme:</strong>
								{generated_story.metadata.theme}</span
							>
							<span
								><strong class="text-paper-accent">Words:</strong>
								{generated_story.metadata.word_count}</span
							>
						</div>
					{/if}
				</div>
			</div>
		{:else if !generating_story}
			<div class="card py-16 text-center">
				<div class="mb-4 text-5xl">📖</div>
				<p class="mb-1 text-paper-text-light">Your AI-generated story will appear here</p>
				<p class="text-sm text-paper-text-muted">
					Customize the options and click "Generate My Story"
				</p>
			</div>
		{/if}
	</div>

	<!-- Features Section -->
	<div class="animate-fade-in-up mt-20" style:animation-delay="0.3s">
		<h2 class="mb-8 text-center font-serif text-2xl font-semibold text-paper-text">
			Why Use Our AI Story Generator?
		</h2>
		<div class="grid gap-5 sm:grid-cols-3">
			{#each [{ icon: '🎨', title: 'Creative Inspiration', desc: "Break through writer's block with unique AI-generated ideas." }, { icon: '⚡', title: 'Live Generation', desc: 'Watch your story unfold in real-time with streaming.' }, { icon: '🎯', title: 'Genre-Specific', desc: 'Each genre comes with tailored themes and settings.' }] as feature (feature.title)}
				<div class="card overflow-hidden p-6 text-center">
					<div class="mb-3 text-3xl">{feature.icon}</div>
					<h3 class="mb-2 font-serif text-base font-semibold text-paper-text">{feature.title}</h3>
					<p class="text-sm text-paper-text-light">{feature.desc}</p>
				</div>
			{/each}
		</div>
	</div>

	<!-- CTA Section -->
	<div class="animate-fade-in-up mt-16 text-center" style:animation-delay="0.4s">
		<div class="card-elevated glow-accent overflow-hidden p-8">
			<h2 class="mb-3 font-serif text-xl font-semibold text-paper-text">Ready for More?</h2>
			<p class="mb-6 text-paper-text-light">Discover Fictioneer - the complete writing platform</p>
			<div class="flex flex-wrap justify-center gap-3">
				<a href={resolve('/')} class="btn-primary">Learn More</a>
				<a href={resolve('/tools')} class="btn-secondary">Explore Tools</a>
			</div>
		</div>
	</div>
</main>
