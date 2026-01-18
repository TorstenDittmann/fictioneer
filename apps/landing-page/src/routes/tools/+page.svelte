<script lang="ts">
	import { resolve } from '$app/paths';
	import type { RouteId } from '$app/types';
</script>

<svelte:head>
	<title>Free AI Writing Tools for Stories, Names & Plots | Fictioneer</title>
	<meta
		name="description"
		content="Explore free AI writing tools for stories, plots, character names, titles, and worldbuilding. No signup required."
	/>
	<meta
		name="keywords"
		content="AI writing tools, AI story generator, AI plot generator, AI character name generator, AI book title generator, AI pen name generator, AI worldbuilding tools"
	/>
	<link rel="canonical" href="https://fictioneer.app/tools" />

	<meta
		property="og:title"
		content="Free AI Writing Tools for Stories, Names & Plots | Fictioneer"
	/>
	<meta
		property="og:description"
		content="Explore free AI writing tools for stories, plots, character names, titles, and worldbuilding."
	/>
	<meta property="og:url" content="https://fictioneer.app/tools" />
	<meta property="og:type" content="website" />

	<meta
		name="twitter:title"
		content="Free AI Writing Tools for Stories, Names & Plots | Fictioneer"
	/>
	<meta
		name="twitter:description"
		content="Explore free AI writing tools for stories, plots, character names, titles, and worldbuilding."
	/>
</svelte:head>

{#snippet toolCard(
	title: string,
	description: string,
	icon: string,
	features: string[],
	href: Extract<RouteId, `/tools/${string}`>,
	gradient: string,
	index: number
)}
	<a
		href={resolve(href)}
		class="animate-fade-in-up group relative overflow-hidden rounded-2xl transition-all duration-300 hover:scale-[1.02]"
		style:animation-delay="{0.2 + index * 0.05}s"
	>
		<div class="card-elevated h-full p-6">
			<!-- Icon with gradient background -->
			<div class="relative mb-4">
				<div
					class="absolute -inset-2 rounded-2xl bg-linear-to-br opacity-0 blur-xl transition-opacity duration-300 group-hover:opacity-40 {gradient}"
				></div>
				<div
					class="relative flex h-14 w-14 items-center justify-center rounded-xl bg-linear-to-br text-2xl transition-transform duration-300 group-hover:scale-110 {gradient}"
				>
					{icon}
				</div>
			</div>

			<h3 class="mb-2 font-serif text-lg font-semibold text-paper-text">
				{title}
			</h3>
			<p class="mb-4 text-sm leading-relaxed text-paper-text-light">
				{description}
			</p>

			<!-- Features as pills -->
			<div class="flex flex-wrap gap-1.5">
				{#each features as feature, i (i)}
					<span class="rounded-full bg-paper-beige px-2 py-0.5 text-xs text-paper-text-muted">
						{feature}
					</span>
				{/each}
			</div>

			<!-- Arrow indicator -->
			<div
				class="mt-4 flex items-center gap-1 text-sm font-medium text-paper-accent opacity-0 transition-all duration-300 group-hover:translate-x-1 group-hover:opacity-100"
			>
				Try it
				<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
					<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"
					></path>
				</svg>
			</div>
		</div>
	</a>
{/snippet}

<main class="mx-auto max-w-7xl px-4 py-16 sm:px-6 lg:py-24">
	<!-- Hero Section -->
	<div class="animate-fade-in-up relative mb-20 text-center">
		<!-- Decorative elements -->
		<div
			class="aurora-blob-subtle absolute -top-20 left-1/4 h-64 w-64 rounded-full bg-paper-accent/20"
		></div>
		<div
			class="aurora-blob-subtle absolute -top-10 right-1/4 h-48 w-48 rounded-full bg-paper-iris/20"
		></div>

		<div class="relative">
			<div class="mb-6 flex items-center justify-center gap-3">
				<span class="pill">
					<span class="h-1.5 w-1.5 animate-pulse rounded-full bg-paper-lime"></span>
					Free to use
				</span>
				<span class="pill">
					<span class="h-1.5 w-1.5 rounded-full bg-paper-accent"></span>
					No signup required
				</span>
			</div>

			<h1 class="mb-6 font-serif text-4xl tracking-tight text-paper-text sm:text-5xl lg:text-6xl">
				Free <span class="gradient-text">AI Writing Tools</span> for Instant Ideas
			</h1>
			<p class="mx-auto mb-10 max-w-2xl text-lg leading-relaxed text-paper-text-light lg:text-xl">
				Draft AI story ideas, name characters, outline plots, and shape new worlds in minutes with
				free, writer-first generators.
			</p>

			<!-- Stats row -->
			<div class="flex flex-wrap items-center justify-center gap-8 text-sm">
				<div class="flex items-center gap-2">
					<span class="text-2xl font-bold text-paper-accent">8</span>
					<span class="text-paper-text-muted">Free Tools</span>
				</div>
				<div class="h-4 w-px bg-paper-border"></div>
				<div class="flex items-center gap-2">
					<span class="text-2xl font-bold text-paper-accent">9</span>
					<span class="text-paper-text-muted">Story Genres</span>
				</div>
				<div class="h-4 w-px bg-paper-border"></div>
				<div class="flex items-center gap-2">
					<span class="text-2xl font-bold text-paper-accent">0</span>
					<span class="text-paper-text-muted">Signups Needed</span>
				</div>
			</div>
		</div>
	</div>

	<!-- Featured Tool -->
	<div class="animate-fade-in-up mb-16" style:animation-delay="0.1s">
		<a
			href={resolve('/tools/ai-story-generator')}
			class="group relative block overflow-hidden rounded-3xl"
		>
			<!-- Gradient background -->
			<div
				class="absolute inset-0 bg-linear-to-br from-indigo-500 via-purple-500 to-pink-500 opacity-90 transition-opacity duration-500 group-hover:opacity-100"
			></div>

			<!-- Animated pattern -->
			<div
				class="absolute inset-0 opacity-20"
				style="background-image: radial-gradient(circle at 20% 50%, white 1px, transparent 1px), radial-gradient(circle at 80% 50%, white 1px, transparent 1px); background-size: 60px 60px;"
			></div>

			<!-- Content -->
			<div class="relative flex flex-col items-center px-8 py-16 text-center text-white lg:py-20">
				<span
					class="mb-4 rounded-full bg-white/20 px-4 py-1.5 text-sm font-medium backdrop-blur-sm"
				>
					Most Popular
				</span>
				<span class="mb-4 text-6xl transition-transform duration-300 group-hover:scale-110">
					📚
				</span>
				<h2 class="mb-3 font-serif text-3xl font-bold lg:text-4xl">AI Story Generator</h2>
				<p class="mb-6 max-w-lg text-lg text-white/90">
					Spin up complete short stories with custom genres, tones, and settings. Watch the draft
					arrive in real time.
				</p>
				<div class="flex flex-wrap justify-center gap-3">
					{#each ['Fantasy', 'Sci-Fi', 'Romance', 'Mystery', 'Horror', '+4 more'] as genre (genre)}
						<span class="rounded-full bg-white/20 px-3 py-1 text-sm backdrop-blur-sm">
							{genre}
						</span>
					{/each}
				</div>
				<div
					class="mt-8 flex items-center gap-2 font-semibold transition-transform duration-300 group-hover:translate-x-2"
				>
					Try it free
					<svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
						<path
							stroke-linecap="round"
							stroke-linejoin="round"
							stroke-width="2"
							d="M17 8l4 4m0 0l-4 4m4-4H3"
						/>
					</svg>
				</div>
			</div>
		</a>
	</div>

	<!-- Tools Grid -->
	<div class="mb-20">
		<h2
			class="animate-fade-in-up mb-8 text-center font-serif text-2xl font-semibold text-paper-text"
			style:animation-delay="0.15s"
		>
			All Writing Tools
		</h2>

		<div class="grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
			{@render toolCard(
				'Plot Generator',
				'Craft structured story beats with AI-driven arcs, conflicts, and twist ideas.',
				'🎭',
				['Story arcs', 'Conflict ideas', 'Twist suggestions'],
				'/tools/plot-generator',
				'from-violet-500 to-fuchsia-600',
				0
			)}

			{@render toolCard(
				'Character Names',
				'Generate genre-aware names with origins, meanings, and stylistic flair.',
				'👤',
				['6 origins', '5 styles', 'Name meanings'],
				'/tools/character-name-generator',
				'from-emerald-500 to-teal-600',
				1
			)}

			{@render toolCard(
				'Book Titles',
				'Create market-ready titles with keywords, hooks, and genre signals.',
				'📖',
				['Genre-aware', 'Marketing hooks', 'Multiple options'],
				'/tools/book-title-generator',
				'from-amber-500 to-orange-600',
				2
			)}

			{@render toolCard(
				'Pen Names',
				'Build a memorable author persona with tailored tone and taglines.',
				'✍️',
				['Genre matching', 'Brand taglines', 'Initial styles'],
				'/tools/pen-name-generator',
				'from-rose-500 to-pink-600',
				3
			)}

			{@render toolCard(
				'Town Names',
				'Invent vivid settlements with region, vibe, and world style controls.',
				'🏘️',
				['Fantasy & realistic', 'Region flavors', 'Population sizes'],
				'/tools/town-name-generator',
				'from-cyan-500 to-blue-600',
				4
			)}

			{@render toolCard(
				'Fan Fiction',
				'Generate canon-friendly prompts with tone, ship style, and AU control.',
				'⭐',
				['Any fandom', 'Ship dynamics', 'Canon alignment'],
				'/tools/fan-fiction-story-generator',
				'from-yellow-500 to-amber-600',
				5
			)}

			{@render toolCard(
				'Adult Stories',
				'Mature story seeds with consent-first controls, tropes, and heat levels.',
				'🔞',
				['Steam levels', 'Trope selection', 'Consent-first'],
				'/tools/adult-story-generator',
				'from-red-500 to-rose-600',
				6
			)}
		</div>
	</div>

	<!-- CTA Section -->
	<div class="animate-fade-in-up" style:animation-delay="0.5s">
		<div class="relative overflow-hidden rounded-3xl">
			<!-- Background -->
			<div class="absolute inset-0 bg-linear-to-br from-paper-beige to-paper-gray"></div>
			<div class="absolute inset-0 opacity-50" style:background="var(--gradient-mesh)"></div>

			<div class="relative px-8 py-16 text-center">
				<h2 class="mb-4 font-serif text-2xl font-semibold text-paper-text lg:text-3xl">
					Ready to write your next masterpiece?
				</h2>
				<p class="mx-auto mb-8 max-w-lg text-paper-text-light">
					Fictioneer is a distraction-free desktop app with AI assistance built right in. Take your
					writing to the next level.
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
							Download Free
						</span>
					</a>
					<a href={resolve('/')} class="btn-ghost">Learn More</a>
				</div>
			</div>
		</div>
	</div>
</main>
