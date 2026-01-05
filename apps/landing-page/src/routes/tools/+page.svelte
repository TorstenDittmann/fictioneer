<script lang="ts">
	import { resolve } from '$app/paths';
	import type { RouteId } from '$app/types';
</script>

<svelte:head>
	<title>Free AI Writing Tools - Story Generators & Writing Assistants | Fictioneer</title>
	<meta
		name="description"
		content="Discover our collection of free AI writing tools. Generate stories, characters, plots, book titles, and more."
	/>
	<meta
		name="keywords"
		content="AI writing tools, story generator, character generator, plot generator, book title generator, pen name generator, writing assistant"
	/>
	<link rel="canonical" href="https://fictioneer.app/tools" />

	<meta
		property="og:title"
		content="Free AI Writing Tools - Story Generators & More | Fictioneer"
	/>
	<meta
		property="og:description"
		content="Explore our suite of free AI writing tools. Generate stories, characters, plots, and more."
	/>
	<meta property="og:url" content="https://fictioneer.app/tools" />
	<meta property="og:type" content="website" />

	<meta
		name="twitter:title"
		content="Free AI Writing Tools - Story Generators & More | Fictioneer"
	/>
	<meta
		name="twitter:description"
		content="Explore our suite of free AI writing tools. Generate stories, characters, plots, and more."
	/>
</svelte:head>

{#snippet toolCard(
	title: string,
	description: string,
	icon: string,
	features: string[],
	href: Extract<RouteId, `/tools/${string}`>
)}
	<div
		class="animate-fade-in-up card-elevated group relative overflow-hidden p-6 transition-all duration-300 hover:scale-[1.02]"
	>
		<div class="mb-4 text-center">
			<div class="mb-3 text-4xl">{icon}</div>
			<h3 class="mb-2 font-serif text-lg font-semibold text-paper-text">{title}</h3>
			<p class="text-sm leading-relaxed text-paper-text-light">{description}</p>
		</div>

		<ul class="mb-5 space-y-2">
			{#each features as feature (feature)}
				<li class="flex items-center text-sm text-paper-text-light">
					<svg
						class="mr-2 h-3.5 w-3.5 shrink-0 text-paper-accent"
						fill="none"
						stroke="currentColor"
						stroke-width="2"
						viewBox="0 0 24 24"
					>
						<path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7"></path>
					</svg>
					{feature}
				</li>
			{/each}
		</ul>

		<a href={resolve(href)} class="btn-primary block w-full text-center text-sm"> Try It Free </a>
	</div>
{/snippet}

<main class="mx-auto max-w-6xl px-4 py-16 sm:px-6 lg:py-24">
	<!-- Hero Section -->
	<div class="animate-fade-in-up mb-16 text-center">
		<div class="pill mx-auto mb-6 w-max">
			<span class="h-1.5 w-1.5 rounded-full bg-paper-accent"></span>
			Free to use
		</div>

		<h1 class="mb-4 font-serif text-3xl tracking-tight text-paper-text sm:text-4xl lg:text-5xl">
			Free AI <span class="gradient-text">Writing Tools</span>
		</h1>
		<p class="mx-auto mb-8 max-w-2xl text-lg text-paper-text-light">
			Unleash your creativity with our collection of AI-powered writing tools. Generate stories,
			characters, plots, and more.
		</p>

		<div class="flex flex-wrap items-center justify-center gap-3">
			<span
				class="rounded-full border border-paper-border bg-paper-cream/60 px-4 py-2 text-sm text-paper-text-light backdrop-blur-sm"
			>
				<span class="mr-1.5 text-paper-accent">✨</span> Completely Free
			</span>
			<span
				class="rounded-full border border-paper-border bg-paper-cream/60 px-4 py-2 text-sm text-paper-text-light backdrop-blur-sm"
			>
				<span class="mr-1.5 text-paper-accent">🤖</span> AI-Powered
			</span>
			<span
				class="rounded-full border border-paper-border bg-paper-cream/60 px-4 py-2 text-sm text-paper-text-light backdrop-blur-sm"
			>
				<span class="mr-1.5 text-paper-accent">🚀</span> No Registration
			</span>
		</div>
	</div>

	<!-- Tools Grid -->
	<div class="mb-20 grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
		{@render toolCard(
			'AI Story Generator',
			'Generate unique, creative stories with AI. Choose your genre, theme, and setting.',
			'📚',
			['Genre-specific themes', 'Customizable settings', 'Live streaming', 'Adjustable length'],
			'/tools/ai-story-generator'
		)}

		{@render toolCard(
			'Character Name Generator',
			'Create memorable character names by genre, origin, or cultural background.',
			'👤',
			['Cultural origins', 'Genre-specific', 'Meaning included', 'Bulk generation'],
			'/tools/character-name-generator'
		)}

		{@render toolCard(
			'Plot Generator',
			"Overcome writer's block with AI-generated plot ideas tailored to your genre.",
			'🎭',
			['Story arcs', 'Conflict ideas', 'Character motivations', 'Twist suggestions'],
			'/tools/plot-generator'
		)}

		{@render toolCard(
			'Book Title Generator',
			"Generate compelling book titles that capture your story's essence.",
			'📖',
			['Genre-aware', 'Multiple options', 'SEO optimized', 'Trademark check'],
			'/tools/book-title-generator'
		)}

		{@render toolCard(
			'Pen Name Generator',
			'Create the perfect pseudonym for your writing career with AI.',
			'✍️',
			['Genre matching', 'Availability check', 'Cultural styles', 'Gender options'],
			'/tools/pen-name-generator'
		)}

		{@render toolCard(
			'Town Name Generator',
			'Generate realistic town and city names for your fictional worlds.',
			'🏘️',
			['Geographic styles', 'Fantasy & realistic', 'Cultural influences', 'Size variations'],
			'/tools/town-name-generator'
		)}

		{@render toolCard(
			'Fan Fiction Story Generator',
			'Create fan fiction stories based on your favorite universes.',
			'⭐',
			['Popular fandoms', 'Character relationships', 'Canon compliance', 'AU scenarios'],
			'/tools/fan-fiction-story-generator'
		)}

		{@render toolCard(
			'Adult Story Generator',
			'Generate mature stories for adult audiences with nuanced themes.',
			'🔞',
			['Mature themes', 'Complex characters', 'Relationship dynamics', 'Age verification'],
			'/tools/adult-story-generator'
		)}
	</div>
</main>
