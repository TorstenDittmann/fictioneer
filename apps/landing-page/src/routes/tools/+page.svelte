<script lang="ts">
	import { resolve } from '$app/paths';
	import type { RouteId } from '$app/types';

	type Tool = {
		title: string;
		description: string;
		icon: string;
		features: string[];
	} & (
		| {
				status: 'available';
				href: RouteId;
		  }
		| {
				status: 'coming_soon';
		  }
	);

	const tools: Tool[] = [
		{
			title: 'AI Story Generator',
			description:
				'Generate unique, creative stories with AI. Choose your genre, theme, characters, and setting to create engaging fiction instantly.',
			href: '/tools/ai-story-generator',
			icon: '📚',
			status: 'available',
			features: [
				'Genre-specific themes',
				'Customizable settings',
				'Live streaming',
				'Adjustable length'
			]
		},
		{
			title: 'Character Name Generator',
			description:
				'Create memorable character names for your stories. Generate names by genre, origin, or cultural background.',
			icon: '👤',
			status: 'coming_soon',
			features: ['Cultural origins', 'Genre-specific', 'Meaning included', 'Bulk generation']
		},
		{
			title: 'Plot Generator',
			description:
				"Overcome writer's block with AI-generated plot ideas and story structures tailored to your preferred genre.",
			icon: '🎭',
			status: 'coming_soon',
			features: ['Story arcs', 'Conflict ideas', 'Character motivations', 'Twist suggestions']
		},
		{
			title: 'Book Title Generator',
			description:
				"Generate compelling book titles that capture your story's essence and attract readers.",
			icon: '📖',
			status: 'coming_soon',
			features: ['Genre-aware', 'Multiple options', 'SEO optimized', 'Trademark check']
		},
		{
			title: 'Pen Name Generator',
			description:
				'Create the perfect pseudonym for your writing career with our AI-powered pen name generator.',
			icon: '✍️',
			status: 'coming_soon',
			features: ['Genre matching', 'Availability check', 'Cultural styles', 'Gender options']
		},
		{
			title: 'Town Name Generator',
			description: 'Generate realistic town and city names for your fictional worlds and stories.',
			icon: '🏘️',
			status: 'coming_soon',
			features: [
				'Geographic styles',
				'Fantasy & realistic',
				'Cultural influences',
				'Size variations'
			]
		},
		{
			title: 'Fan Fiction Story Generator',
			description:
				'Create fan fiction stories based on your favorite universes with AI assistance.',
			icon: '⭐',
			status: 'coming_soon',
			features: ['Popular fandoms', 'Character relationships', 'Canon compliance', 'AU scenarios']
		},
		{
			title: 'Adult Story Generator',
			description:
				'Generate mature, sophisticated stories for adult audiences with nuanced themes and complex characters.',
			icon: '🔞',
			status: 'coming_soon',
			features: ['Mature themes', 'Complex characters', 'Relationship dynamics', 'Age verification']
		}
	];
</script>

<svelte:head>
	<title>Free AI Writing Tools - Story Generators & Writing Assistants | Fictioneer</title>
	<meta
		name="description"
		content="Discover our collection of free AI writing tools. Generate stories, characters, plots, book titles, and more. Perfect for writers, authors, and creative minds seeking inspiration."
	/>
	<meta
		name="keywords"
		content="AI writing tools, story generator, character generator, plot generator, book title generator, pen name generator, writing assistant, free writing tools"
	/>
	<link rel="canonical" href="https://fictioneer.app/tools" />

	<!-- Open Graph -->
	<meta
		property="og:title"
		content="Free AI Writing Tools - Story Generators & More | Fictioneer"
	/>
	<meta
		property="og:description"
		content="Explore our suite of free AI writing tools. Generate stories, characters, plots, and more to fuel your creativity."
	/>
	<meta property="og:url" content="https://fictioneer.app/tools" />
	<meta property="og:type" content="website" />

	<!-- Twitter -->
	<meta
		name="twitter:title"
		content="Free AI Writing Tools - Story Generators & More | Fictioneer"
	/>
	<meta
		name="twitter:description"
		content="Explore our suite of free AI writing tools. Generate stories, characters, plots, and more to fuel your creativity."
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
					<span class="text-lg text-paper-text-light">AI Writing Tools</span>
				</div>
				<nav class="hidden space-x-6 md:flex">
					<a
						href={resolve('/')}
						class="transition-smooth text-paper-text-light hover:text-paper-accent">Home</a
					>
					<a
						href="#features"
						class="transition-smooth text-paper-text-light hover:text-paper-accent">Features</a
					>
					<a href="#pricing" class="transition-smooth text-paper-text-light hover:text-paper-accent"
						>Pricing</a
					>
				</nav>
			</div>
		</div>
	</header>

	<main class="relative z-10 mx-auto max-w-7xl px-4 py-12 sm:px-6 lg:px-8">
		<!-- Hero Section -->
		<div class="animate-fade-in-up mb-20 text-center">
			<div class="mb-6">
				<span class="animate-float text-6xl">🎨</span>
			</div>
			<h1 class="mb-6 font-serif text-4xl font-bold md:text-6xl">
				<span class="text-paper-text">Free AI</span>
				<span class="gradient-text mt-2 block">Writing Tools</span>
			</h1>
			<p class="mx-auto mb-8 max-w-3xl text-xl leading-relaxed text-paper-text-light">
				Unleash your creativity with our collection of AI-powered writing tools. Generate stories,
				characters, plots, and more to fuel your imagination and overcome writer's block.
			</p>
			<div class="flex flex-wrap items-center justify-center gap-4 text-sm text-paper-text-muted">
				<span class="glass rounded-full border border-paper-accent/30 px-4 py-2">
					<span class="text-paper-accent">✨</span> Completely Free
				</span>
				<span class="glass rounded-full border border-paper-accent/30 px-4 py-2">
					<span class="text-paper-accent">🤖</span> AI-Powered
				</span>
				<span class="glass rounded-full border border-paper-accent/30 px-4 py-2">
					<span class="text-paper-accent">🚀</span> No Registration
				</span>
			</div>
		</div>

		<!-- Tools Grid -->
		<div class="mb-20 grid gap-8 md:grid-cols-2 lg:grid-cols-3">
			{#each tools as tool, index (tool.title)}
				<div
					class="glass hover-lift transition-smooth group animate-fade-in relative rounded-2xl border border-paper-border p-8"
					style:animation-delay="{index * 0.1}s"
				>
					{#if tool.status === 'coming_soon'}
						<div class="absolute top-4 right-4">
							<span
								class="glass rounded-full border border-paper-accent/30 bg-paper-accent/20 px-3 py-1 text-xs font-medium text-paper-accent"
							>
								Coming Soon
							</span>
						</div>
					{/if}

					<div class="mb-6 text-center">
						<div class="animate-glow-pulse mb-4 text-4xl">{tool.icon}</div>
						<h3 class="mb-3 font-serif text-xl font-semibold text-paper-text">{tool.title}</h3>
						<p class="text-sm leading-relaxed text-paper-text-light">{tool.description}</p>
					</div>

					<!-- Features List -->
					<ul class="mb-6 space-y-2">
						{#each tool.features as feature (feature)}
							<li class="flex items-center text-sm text-paper-text-light">
								<svg
									class="mr-2 h-4 w-4 shrink-0 text-paper-accent"
									fill="currentColor"
									viewBox="0 0 20 20"
								>
									<path
										fill-rule="evenodd"
										d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
										clip-rule="evenodd"
									/>
								</svg>
								{feature}
							</li>
						{/each}
					</ul>

					<!-- Action Button -->
					{#if tool.status === 'available'}
						<a
							href={resolve(tool.href)}
							class="btn-primary hover-lift block w-full px-6 py-3 text-center font-semibold"
						>
							Try It Free
						</a>
					{:else}
						<button
							disabled
							class="glass block w-full cursor-not-allowed rounded-lg border border-paper-border px-6 py-3 text-center font-semibold text-paper-text-muted"
						>
							Coming Soon
						</button>
					{/if}
				</div>
			{/each}
		</div>
	</main>
</div>
