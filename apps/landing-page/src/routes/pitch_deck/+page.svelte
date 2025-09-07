<script lang="ts">
	// Static pitch deck page styled like the landing sections
	const sections = [
		{
			id: 'problem',
			n: '01',
			title: 'Problem',
			points: [
				'Writing a novel or story is intimidating and overwhelming.',
				'Most existing tools are either too complex for beginners or too simplistic for serious writers.',
				'AI tools exist, but they lack focus on storytelling structure and the creative process.'
			]
		},
		{
			id: 'solution',
			n: '02',
			title: 'Solution',
			lead: 'Fictioneer – an AI-powered creative writing companion.',
			points: [
				'Distraction-free editor designed for storytelling.',
				'AI assistance for plot, characters, tone, and pacing.',
				'Helps both novelists and casual storytellers stay motivated and productive.'
			]
		},
		{
			id: 'market',
			n: '03',
			title: 'Market Opportunity',
			points: [
				'Global writing software market: $X billion (growing with AI adoption).',
				'200M+ aspiring writers worldwide.',
				'Rising demand for AI-assisted creativity tools.'
			]
		},
		{
			id: 'product',
			n: '04',
			title: 'Product',
			points: [
				'Clean, intuitive editor.',
				'AI co-author features: prompts, character building, plot scaffolding.',
				'Progress tracking and motivational nudges.',
				'Professional export and publishing options.'
			],
			note: 'Currently in early development – core features built, preparing for beta.'
		},
		{
			id: 'traction',
			n: '05',
			title: 'Traction',
			points: [
				'Founder previously built OmniaWrite, an open-source writing tool with 50K weekly active devices at its peak.',
				'Strong existing community and proof of demand.',
				'Fictioneer builds on this foundation with AI and a sustainable subscription model.'
			]
		},
		{
			id: 'business_model',
			n: '06',
			title: 'Business Model',
			points: [
				'Subscription-based revenue at launch.',
				'Tiered plans for novelists and casual storytellers.',
				'Potential future upsells: collaboration tools, premium AI features, publishing services.'
			]
		},
		{
			id: 'gtm',
			n: '07',
			title: 'Go-To-Market Strategy',
			points: [
				'Re-engage OmniaWrite community.',
				'Targeted outreach in writing forums, creative communities, journaling groups.',
				'Content marketing: story prompts, writing guides, webinars.',
				'Partnerships with creative writing programs and communities.'
			]
		},
		{
			id: 'competition',
			n: '08',
			title: 'Competition',
			points: [
				'Scrivener, Ulysses: powerful but not AI-driven.',
				'Jasper, Sudowrite: AI-driven but lack depth in storytelling structure.',
				'Fictioneer’s edge: combines intuitive design, storytelling focus, and AI co-authoring.'
			]
		},
		{
			id: 'financials',
			n: '09',
			title: 'Financial Projections',
			points: [
				'Year 1: Beta launch, focus on feedback and early subscriptions.',
				'Year 2: Scale to 5,000+ paying subscribers.',
				'Target $1M+ ARR in Year 3.'
			]
		},
		{
			id: 'team',
			n: '10',
			title: 'Team',
			points: [
				'Torsten Dittmann – solo founder, designer, and developer.',
				'Proven track record: creator of OmniaWrite and Founding Engineer at Appwrite.',
				'Looking to expand team with AI/UX expertise post-acceleration.'
			]
		},
		{
			id: 'ask',
			n: '11',
			title: 'Ask',
			points: [
				'Seeking accelerator support for mentorship, growth strategy, and fundraising preparation.',
				'Goal: launch Fictioneer beta, refine product–market fit, and scale subscriptions.'
			]
		},
		{
			id: 'vision',
			n: '12',
			title: 'Vision',
			lead: 'Empower anyone-from career novelists to casual storytellers-to tell their stories with the help of AI. Fictioneer makes writing more accessible, structured, and joyful.'
		}
	];
</script>

<svelte:head>
	<title>Fictioneer Pitch Deck</title>
	<meta name="robots" content="noindex, follow" />
</svelte:head>

<div class="min-h-screen bg-paper-beige">
	<header class="relative overflow-hidden px-4 py-16 sm:py-20">
		<div
			class="absolute inset-0 bg-gradient-to-br from-paper-beige via-paper-cream/50 to-paper-white/30"
		></div>
		<div class="absolute inset-0" style="background: var(--gradient-radial)"></div>
		<div class="relative mx-auto max-w-5xl text-center">
			<h1
				class="animate-fade-in-up mb-3 font-serif text-4xl leading-[0.9] tracking-tight sm:text-6xl md:text-7xl"
			>
				<span class="text-paper-text">Fictioneer</span>
				<span class="gradient-text mt-2 block text-3xl sm:text-5xl">Pitch Deck</span>
			</h1>
			<p
				class="animate-fade-in-up mx-auto mt-4 max-w-2xl text-base text-paper-text-light/90 sm:text-lg md:text-xl"
				style="animation-delay: 0.1s"
			>
				A concise overview of the problem, solution, and path forward.
			</p>
			<div class="animate-fade-in-up mt-8" style="animation-delay: 0.15s">
				<a href="/" class="btn-primary hover-lift inline-flex items-center gap-2">
					<span>Back to Home</span>
					<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
						<path
							stroke-linecap="round"
							stroke-linejoin="round"
							stroke-width="2"
							d="M15 19l-7-7 7-7"
						></path>
					</svg>
				</a>
			</div>
		</div>
	</header>

	<main class="relative px-4 pb-24 sm:pb-32">
		<div
			class="absolute top-0 left-0 h-px w-full bg-gradient-to-r from-transparent via-paper-border/50 to-transparent"
		></div>
		<div class="mx-auto grid max-w-5xl gap-8 sm:gap-10">
			{#each sections as s, i (s.id)}
				<section id={s.id} class="group relative scroll-mt-24">
					<div class="glass animate-scale-in rounded-2xl p-6 sm:rounded-3xl sm:p-8">
						<div class="mb-4 flex items-baseline justify-between">
							<h2 class="font-serif text-2xl sm:text-3xl md:text-4xl">
								<span class="text-paper-text">{s.title}</span>
							</h2>
							<span class="gradient-text text-lg font-bold tracking-widest">{s.n}</span>
						</div>

						{#if s.lead}
							<p class="mb-4 text-base text-paper-text sm:text-lg md:text-xl">
								<strong class="text-paper-accent">{s.lead}</strong>
							</p>
						{/if}

						{#if s.points}
							<ul class="list-disc space-y-2 pl-5 text-paper-text-light sm:text-lg">
								{#each s.points as p, i (i)}
									<li>{p}</li>
								{/each}
							</ul>
						{/if}

						{#if s.note}
							<p
								class="mt-4 rounded-lg border border-paper-border/30 bg-paper-white/10 p-3 text-sm text-paper-text-muted sm:text-base"
							>
								{s.note}
							</p>
						{/if}
					</div>

					{#if i < sections.length - 1}
						<div class="mt-8 flex justify-center sm:mt-10">
							<div
								class="h-12 w-px bg-gradient-to-b from-transparent via-paper-border/30 to-transparent sm:h-16"
							></div>
						</div>
					{/if}
				</section>
			{/each}
		</div>
	</main>
</div>
