<script lang="ts">
	import { resolve } from '$app/paths';
	import { config, api_endpoints } from '$lib/config';

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

	// Form state
	let selected_genre = $state('fantasy');
	let selected_theme = $state('Good vs evil');

	let selected_setting = $state('fantasy_world');
	let selected_tone = $state('serious');
	let word_count = $state(300);
	let story_context = $state('');

	// Streaming state
	let streaming_text = $state('');
	let is_streaming = $state(false);
	let stream_completed = $state(false);

	// Reference for scrolling to results
	let story_section: HTMLElement;

	// Derived state for current themes
	let current_themes = $derived(story_options?.themes_by_genre[selected_genre] || []);

	// Update selected theme when genre changes
	$effect(() => {
		if (
			story_options &&
			selected_genre &&
			current_themes.length > 0 &&
			!current_themes.includes(selected_theme)
		) {
			selected_theme = current_themes[0];
		}
	});

	async function generate_story() {
		if (generating_story) return;

		generating_story = true;
		error_message = '';
		generated_story = null;
		streaming_text = '';
		is_streaming = true;
		stream_completed = false;

		// Scroll to story section immediately
		if (story_section) {
			story_section.scrollIntoView({
				behavior: 'smooth',
				block: 'start'
			});
		}

		try {
			const response = await fetch(
				`${config.intelligence_api.base_url}${api_endpoints.story_generator.generate}`,
				{
					method: 'POST',
					headers: {
						'Content-Type': 'application/json',
						Accept: 'text/plain+stream'
					},
					body: JSON.stringify({
						genre: selected_genre,
						theme: selected_theme,
						setting: selected_setting,
						tone: selected_tone,
						word_count: word_count,
						context: story_context
					})
				}
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

			// Handle streaming response
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

						// Add a small delay for typewriter effect
						await new Promise((resolve) => setTimeout(resolve, 30));
					}

					// Create final story object
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
			error_message =
				error instanceof Error ? error.message : 'Failed to generate story. Please try again.';
			is_streaming = false;
			streaming_text = '';
		} finally {
			generating_story = false;
			is_streaming = false;
		}
	}

	function copy_story_to_clipboard() {
		if (!generated_story) return;

		navigator.clipboard
			.writeText(generated_story.story)
			.then(() => {
				// Could add a toast notification here
			})
			.catch((err) => {
				console.error('Failed to copy story:', err);
			});
	}
</script>

<svelte:head>
	<title>Free AI Story Generator - Create Unique Stories Instantly | Fictioneer</title>
	<meta
		name="description"
		content="Generate unique, creative stories with our free AI story generator. Choose your genre, theme, characters, and setting. Perfect for writers looking for inspiration or fun creative exercises."
	/>
	<meta
		name="keywords"
		content="AI story generator, free story generator, creative writing, story ideas, fiction generator, writing prompts, AI writing tool"
	/>
	<link rel="canonical" href="https://fictioneer.app/tools/ai-story-generator" />

	<!-- Open Graph -->
	<meta
		property="og:title"
		content="Free AI Story Generator - Create Unique Stories | Fictioneer"
	/>
	<meta
		property="og:description"
		content="Generate creative stories instantly with AI. Choose your genre, theme, and settings to create unique fiction."
	/>
	<meta property="og:url" content="https://fictioneer.app/tools/ai-story-generator" />
	<meta property="og:type" content="website" />

	<!-- Twitter -->
	<meta
		name="twitter:title"
		content="Free AI Story Generator - Create Unique Stories | Fictioneer"
	/>
	<meta
		name="twitter:description"
		content="Generate creative stories instantly with AI. Choose your genre, theme, and settings to create unique fiction."
	/>
</svelte:head>

<div class="min-h-screen bg-paper-beige">
	<!-- Gradient background overlay -->
	<div
		class="absolute inset-0 bg-linear-to-br from-paper-beige via-paper-cream/50 to-paper-white/30"
	></div>
	<div class="absolute inset-0" style:background="var(--gradient-radial)"></div>

	<!-- Header -->
	<header class="glass relative z-10 border-b border-paper-border">
		<div class="mx-auto max-w-7xl px-4 py-6 sm:px-6 lg:px-8">
			<div class="flex items-center justify-between">
				<div class="flex items-center space-x-3">
					<a
						href={resolve('/')}
						class="gradient-text transition-smooth font-serif text-2xl font-bold hover:scale-105"
					>
						Fictioneer
					</a>
					<span class="text-paper-text-muted">|</span>
					<span class="text-lg text-paper-text-light">AI Story Generator</span>
				</div>
				<nav class="hidden space-x-6 md:flex">
					<a
						href={resolve('/')}
						class="transition-smooth text-paper-text-light hover:text-paper-accent">Home</a
					>
					<a
						href={resolve('/tools')}
						class="transition-smooth text-paper-text-light hover:text-paper-accent">More Tools</a
					>
				</nav>
			</div>
		</div>
	</header>

	<main class="relative z-10 mx-auto max-w-7xl px-4 py-12 sm:px-6 lg:px-8">
		<!-- Hero Section -->
		<div class="animate-fade-in-up mb-16 text-center">
			<div class="mb-6">
				<span class="animate-float text-6xl">📚</span>
			</div>
			<h1 class="mb-6 font-serif text-4xl font-bold md:text-6xl">
				<span class="text-paper-text">AI Story</span>
				<span class="gradient-text mt-2 block">Generator</span>
			</h1>
			<p class="mx-auto mb-8 max-w-3xl text-xl leading-relaxed text-paper-text-light">
				Create unique, engaging stories with the power of AI. Choose your genre, theme, characters,
				and setting to generate creative fiction instantly.
			</p>
			<div class="flex flex-wrap items-center justify-center gap-4 text-sm text-paper-text-muted">
				<span class="glass rounded-full border border-paper-accent/30 px-4 py-2">
					<span class="text-paper-accent">✨</span> Completely Free
				</span>
			</div>
		</div>

		<!-- Story Generator Form -->
		<div class="mb-16">
			<div
				class="glass hover-lift animate-fade-in-up mx-auto max-w-4xl rounded-2xl border border-paper-border p-8"
			>
				<h2 class="mb-8 text-center font-serif text-2xl font-semibold text-paper-text">
					Customize Your Story
				</h2>

				<div class="animate-fade-in-up">
					<form
						onsubmit={(e) => {
							e.preventDefault();
							generate_story();
						}}
						class="space-y-8"
					>
						<!-- Form Grid -->
						<div class="grid gap-6 md:grid-cols-2">
							<!-- Genre Selection -->
							<div class="animate-fade-in" style:animation-delay="0.1s">
								<label for="genre" class="mb-3 block text-sm font-medium text-paper-text-light">
									Genre
								</label>
								<select
									id="genre"
									bind:value={selected_genre}
									class="glass transition-smooth w-full appearance-none rounded-lg border border-paper-border bg-paper-cream/50 px-4 py-3 text-paper-text focus:border-paper-accent focus:ring-2 focus:ring-paper-accent/20"
									disabled={generating_story}
								>
									{#each story_options.genres as genre (genre.value)}
										<option value={genre.value}>{genre.label}</option>
									{/each}
								</select>
							</div>

							<!-- Theme Selection -->
							<div class="animate-fade-in" style:animation-delay="0.2s">
								<label for="theme" class="mb-3 block text-sm font-medium text-paper-text-light">
									Theme
								</label>
								<select
									id="theme"
									bind:value={selected_theme}
									class="glass transition-smooth w-full appearance-none rounded-lg border border-paper-border bg-paper-cream/50 px-4 py-3 text-paper-text focus:border-paper-accent focus:ring-2 focus:ring-paper-accent/20"
									disabled={generating_story}
								>
									{#each current_themes as theme (theme)}
										<option value={theme}>{theme}</option>
									{/each}
								</select>
							</div>

							<!-- Setting -->
							<div class="animate-fade-in" style:animation-delay="0.3s">
								<label for="setting" class="mb-3 block text-sm font-medium text-paper-text-light">
									Setting
								</label>
								<select
									id="setting"
									bind:value={selected_setting}
									class="glass transition-smooth w-full appearance-none rounded-lg border border-paper-border bg-paper-cream/50 px-4 py-3 text-paper-text focus:border-paper-accent focus:ring-2 focus:ring-paper-accent/20"
									disabled={generating_story}
								>
									{#each story_options.settings as setting (setting.value)}
										<option value={setting.value}>{setting.label}</option>
									{/each}
								</select>
							</div>

							<!-- Tone -->
							<div class="animate-fade-in" style:animation-delay="0.4s">
								<label for="tone" class="mb-3 block text-sm font-medium text-paper-text-light">
									Tone
								</label>
								<select
									id="tone"
									bind:value={selected_tone}
									class="glass transition-smooth w-full appearance-none rounded-lg border border-paper-border bg-paper-cream/50 px-4 py-3 text-paper-text focus:border-paper-accent focus:ring-2 focus:ring-paper-accent/20"
									disabled={generating_story}
								>
									{#each story_options.tones as tone (tone.value)}
										<option value={tone.value}>{tone.label}</option>
									{/each}
								</select>
							</div>
						</div>

						<!-- Story Context -->
						<div class="animate-fade-in" style:animation-delay="0.5s">
							<label
								for="story_context"
								class="mb-3 block text-sm font-medium text-paper-text-light"
							>
								Story Context <span class="text-paper-text-muted">(Optional)</span>
							</label>
							<textarea
								id="story_context"
								bind:value={story_context}
								placeholder="Describe your story idea, characters, or any specific details you'd like included..."
								class="glass transition-smooth min-h-20 w-full resize-y rounded-lg border border-paper-border bg-paper-cream/50 px-4 py-3 text-paper-text focus:border-paper-accent focus:ring-2 focus:ring-paper-accent/20"
								disabled={generating_story}
							></textarea>
							<div class="mt-1 text-xs text-paper-text-muted">
								Add specific characters, plot points, or setting details to customize your story
							</div>
						</div>

						<!-- Word Count -->
						<div class="animate-fade-in" style:animation-delay="0.6s">
							<label for="word_count" class="mb-3 block text-sm font-medium text-paper-text-light">
								Approximate Word Count: <span class="gradient-text font-semibold"
									>{word_count} words</span
								>
							</label>
							<input
								id="word_count"
								type="range"
								min="100"
								max="800"
								step="50"
								bind:value={word_count}
								class="slider h-2 w-full cursor-pointer appearance-none rounded-lg bg-paper-gray/50"
								disabled={generating_story}
							/>
							<div class="mt-2 flex justify-between text-xs text-paper-text-muted">
								<span>Short (100)</span>
								<span>Medium (400)</span>
								<span>Long (800)</span>
							</div>
						</div>

						<!-- Generate Button -->
						<div class="animate-fade-in" style:animation-delay="0.7s">
							<button
								type="submit"
								disabled={generating_story}
								class="btn-primary hover-lift w-full px-6 py-4 font-semibold disabled:transform-none disabled:cursor-not-allowed disabled:opacity-50"
							>
								{#if generating_story}
									<span class="flex items-center justify-center">
										<svg
											class="mr-3 -ml-1 h-5 w-5 animate-spin"
											xmlns="http://www.w3.org/2000/svg"
											fill="none"
											viewBox="0 0 24 24"
										>
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
									<span class="flex items-center justify-center"> ✨ Generate My Story </span>
								{/if}
							</button>
						</div>
					</form>
				</div>
			</div>
		</div>

		<!-- Generated Story Display -->
		<div class="animate-fade-in-up" bind:this={story_section}>
			<div class="mb-8 flex items-center justify-center">
				<h2 class="text-center font-serif text-3xl font-semibold text-paper-text">
					Your Generated Story
				</h2>
				{#if generated_story && !is_streaming}
					<button
						onclick={copy_story_to_clipboard}
						class="glass transition-smooth ml-6 rounded-lg border border-paper-accent/30 px-4 py-2 text-sm text-paper-text-light hover:border-paper-accent hover:bg-paper-accent/10"
					>
						<span class="flex items-center gap-2"> 📋 Copy Story </span>
					</button>
				{/if}
			</div>

			{#if error_message}
				<div
					class="glass mx-auto mb-6 max-w-4xl rounded-lg border border-red-400/30 bg-red-400/10 p-4"
				>
					<p class="text-sm text-red-400">{error_message}</p>
				</div>
			{/if}

			{#if is_streaming || generated_story}
				<div class="animate-fade-in space-y-6">
					<!-- Book-style Story Display -->
					<div class="animate-fade-in">
						<!-- Story Text with Book-like Styling -->
						<div
							class="mx-auto max-w-5xl rounded-3xl border border-paper-accent/20 bg-linear-to-br from-paper-white/10 to-paper-cream/20 p-8 shadow-2xl md:p-16"
						>
							<div class="story-page">
								<div
									class="typewriter story-content text-justify font-serif text-sm leading-relaxed text-paper-text-light md:text-base md:leading-loose lg:text-lg"
								>
									{#each (is_streaming ? streaming_text : generated_story?.story || '').split('\n\n') as paragraph, i (i)}
										<p class="mb-6">{paragraph.replace(/\n/g, ' ')}</p>
									{/each}
									{#if is_streaming && !stream_completed}
										<span class="blinking-cursor">|</span>
									{/if}
								</div>
							</div>

							<!-- Story Metadata (only show when complete) -->
							{#if generated_story && !is_streaming}
								<div class="mt-12 border-t border-paper-accent/20 pt-8">
									<div class="flex flex-wrap justify-center gap-6 text-sm text-paper-text-muted">
										<span
											><strong class="text-paper-accent">Genre:</strong>
											{story_options?.genres.find(
												(g) => g.value === generated_story?.metadata.genre
											)?.label}
										</span>
										<span
											><strong class="text-paper-accent">Theme:</strong>
											{generated_story.metadata.theme}
										</span>
										<span
											><strong class="text-paper-accent">Setting:</strong>
											{story_options?.settings.find(
												(s) => s.value === generated_story?.metadata.setting
											)?.label}
										</span>
										<span
											><strong class="text-paper-accent">Words:</strong>
											<span class="gradient-text font-semibold"
												>{generated_story.metadata.word_count}</span
											>
										</span>
									</div>
								</div>
							{/if}
						</div>
					</div>
				</div>
			{:else if !generating_story}
				<div class="py-16 text-center">
					<div class="animate-float mb-6 text-6xl">📖</div>
					<p class="mb-2 text-lg text-paper-text-light">Your AI-generated story will appear here</p>
					<p class="text-sm text-paper-text-muted">
						Customize the options and click "Generate My Story" to begin
					</p>
				</div>
			{:else}
				<div class="py-16 text-center">
					<div class="animate-glow-pulse">
						<div class="mb-6 text-6xl">✍️</div>
						<p class="mb-2 text-lg text-paper-text-light">Crafting your unique story...</p>
						<p class="text-sm text-paper-text-muted">Watch as your story unfolds word by word</p>
					</div>
				</div>
			{/if}
		</div>

		<!-- Features Section -->
		<div class="animate-fade-in-up mt-24" style:animation-delay="0.8s">
			<h2 class="mb-16 text-center font-serif text-3xl font-bold text-paper-text">
				Why Use Our AI Story Generator?
			</h2>
			<div class="grid gap-8 md:grid-cols-3">
				<div class="glass hover-lift rounded-xl border border-paper-border p-8 text-center">
					<div class="gradient-text mb-4 text-4xl">🎨</div>
					<h3 class="mb-3 font-serif text-xl font-semibold text-paper-text">
						Creative Inspiration
					</h3>
					<p class="leading-relaxed text-paper-text-light">
						Break through writer's block with unique story ideas and creative prompts generated by
						AI.
					</p>
				</div>
				<div class="glass hover-lift rounded-xl border border-paper-border p-8 text-center">
					<div class="gradient-text mb-4 text-4xl">⚡</div>
					<h3 class="mb-3 font-serif text-xl font-semibold text-paper-text">Live Generation</h3>
					<p class="leading-relaxed text-paper-text-light">
						Watch your story come to life in real-time with our streaming typewriter effect.
					</p>
				</div>
				<div class="glass hover-lift rounded-xl border border-paper-border p-8 text-center">
					<div class="gradient-text mb-4 text-4xl">🎯</div>
					<h3 class="mb-3 font-serif text-xl font-semibold text-paper-text">Genre-Specific</h3>
					<p class="leading-relaxed text-paper-text-light">
						Each genre comes with tailored themes and settings for authentic storytelling.
					</p>
				</div>
			</div>
		</div>

		<!-- CTA Section -->
		<div
			class="glass animate-fade-in-up glow mt-24 rounded-2xl border border-paper-accent/30 p-12 text-center"
			style:animation-delay="1s"
		>
			<h2 class="mb-4 font-serif text-3xl font-bold text-paper-text">
				Ready for More Writing Tools?
			</h2>
			<p class="mb-8 text-xl text-paper-text-light opacity-90">
				Discover Fictioneer - the complete writing platform for novelists
			</p>
			<div class="flex flex-col justify-center gap-4 sm:flex-row">
				<a href={resolve('/')} class="btn-primary hover-lift"> Learn More About Fictioneer </a>
				<a
					href={resolve('/tools')}
					class="glass transition-smooth rounded-lg border-2 border-paper-accent px-8 py-3 font-semibold text-paper-accent hover:bg-paper-accent hover:text-paper-beige"
				>
					Explore More AI Tools
				</a>
			</div>
		</div>
	</main>
</div>

<style>
	/* Custom slider styles */
	.slider::-webkit-slider-thumb {
		appearance: none;
		height: 20px;
		width: 20px;
		border-radius: 50%;
		background: linear-gradient(135deg, var(--color-paper-accent), var(--color-paper-accent-light));
		cursor: pointer;
		border: 2px solid var(--color-paper-beige);
		box-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
	}

	.slider::-moz-range-thumb {
		height: 20px;
		width: 20px;
		border-radius: 50%;
		background: linear-gradient(135deg, var(--color-paper-accent), var(--color-paper-accent-light));
		cursor: pointer;
		border: 2px solid var(--color-paper-beige);
		box-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
	}

	/* Book-style story page styling */
	.story-page {
		position: relative;
		min-height: 300px;
	}

	/* Story content formatting */
	.story-content p:last-child {
		margin-bottom: 0;
	}

	.story-page::before {
		content: '';
		position: absolute;
		top: -20px;
		left: -20px;
		right: -20px;
		bottom: -20px;
		background: linear-gradient(
			135deg,
			rgba(196, 164, 124, 0.03) 0%,
			rgba(196, 164, 124, 0.08) 50%,
			rgba(196, 164, 124, 0.03) 100%
		);
		border-radius: 20px;
		z-index: -1;
	}

	/* Enhanced typography for book-like reading */
	@media (min-width: 768px) {
		.story-page .typewriter {
			text-indent: 2em;
			hyphens: auto;
			word-spacing: 0.1em;
			letter-spacing: 0.02em;
		}
	}

	/* Paragraph spacing for story content */
	.story-page .typewriter {
		line-height: 1.8;
	}

	@media (min-width: 1024px) {
		.story-page .typewriter {
			line-height: 2;
		}
	}

	/* Custom select styling */
	select {
		background-image: url("data:image/svg+xml;charset=UTF-8,%3csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='%23c4a47c' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3e%3cpolyline points='6,9 12,15 18,9'%3e%3c/polyline%3e%3c/svg%3e");
		background-repeat: no-repeat;
		background-position: right 1rem center;
		background-size: 1rem;
		padding-right: 3rem;
	}

	/* Option styling */
	option {
		background-color: var(--color-paper-cream);
		color: var(--color-paper-text);
		padding: 0.5rem;
	}

	option:checked {
		background-color: var(--color-paper-accent);
		color: var(--color-paper-beige);
	}

	/* Typewriter effect */
	.typewriter {
		overflow: visible;
		border-right: 2px solid transparent;
		min-height: 200px;
	}

	.blinking-cursor {
		color: var(--color-paper-accent);
		animation: blink 1.2s infinite;
		font-weight: bold;
		margin-left: 2px;
	}

	@keyframes blink {
		0%,
		50% {
			opacity: 1;
		}
		51%,
		100% {
			opacity: 0;
		}
	}

	/* Smooth text appearance during streaming */
	.typewriter {
		transition: all 0.1s ease-out;
	}

	/* Animation delays for staggered entrance */
	.animate-fade-in:nth-child(1) {
		animation-delay: 0.1s;
	}
	.animate-fade-in:nth-child(2) {
		animation-delay: 0.2s;
	}
	.animate-fade-in:nth-child(3) {
		animation-delay: 0.3s;
	}
	.animate-fade-in:nth-child(4) {
		animation-delay: 0.4s;
	}
	.animate-fade-in:nth-child(5) {
		animation-delay: 0.5s;
	}
	.animate-fade-in:nth-child(6) {
		animation-delay: 0.6s;
	}
	.animate-fade-in:nth-child(7) {
		animation-delay: 0.7s;
	}
</style>
