<script lang="ts">
	import { onMount } from 'svelte';
	import { SvelteSet } from 'svelte/reactivity';

	let mounted = $state(false);
	let visible_cards = new SvelteSet<string>();

	// AI animation state
	let ai_current_text = $state('');
	let ai_typing = $state(false);
	let ai_completion_index = $state(0);

	const ai_base_text = 'She opened the door and';
	const ai_completions = [
		" gasped at her grandmother's journal, secrets hidden for decades finally revealed.",
		" found a 1952 newspaper clipping mentioning her grandfather's mysterious disappearance.",
		" smiled recognizing her ancestor's brilliant inventions, centuries ahead of their time.",
		" heard footsteps. An old man warned: they'll come for you if found.",
		' felt cold air and heard whispers from the shadows saying: not yet.'
	];

	const streak_bars = [
		{ height: '4rem', opacity: 0.2 },
		{ height: '6rem', opacity: 0.35 },
		{ height: '4.5rem', opacity: 0.25 },
		{ height: '7rem', opacity: 0.4 },
		{ height: '5.5rem', opacity: 0.3 },
		{ height: '6.5rem', opacity: 0.35 },
		{ height: '5rem', opacity: 0.28 },
		{ height: '7.5rem', opacity: 0.45 },
		{ height: '6rem', opacity: 0.38 },
		{ height: '5rem', opacity: 0.3 }
	];

	onMount(() => {
		mounted = true;

		const observer = new IntersectionObserver(
			(entries) => {
				entries.forEach((entry) => {
					if (entry.isIntersecting) {
						const id = entry.target.getAttribute('data-card-id');
						if (id) {
							visible_cards.add(id);
							if (id === 'ai' && !ai_typing) {
								start_ai_typing();
							}
						}
					}
				});
			},
			{ threshold: 0.1, rootMargin: '0px 0px -50px 0px' }
		);

		document.querySelectorAll('.feature-card').forEach((el) => {
			observer.observe(el);
		});

		return () => observer.disconnect();
	});

	function start_ai_typing() {
		ai_typing = true;
		typewriter_effect();
	}

	async function typewriter_effect() {
		while (ai_typing) {
			ai_current_text = '';
			await sleep(100);

			const completion = ai_completions[ai_completion_index];
			for (let i = 0; i <= completion.length; i++) {
				ai_current_text = completion.substring(0, i);
				await sleep(25);
			}

			await sleep(3000);

			for (let i = completion.length; i >= 0; i--) {
				ai_current_text = completion.substring(0, i);
				await sleep(15);
			}

			ai_completion_index = (ai_completion_index + 1) % ai_completions.length;
			await sleep(100);
		}
	}

	function sleep(ms: number) {
		return new Promise((resolve) => setTimeout(resolve, ms));
	}
</script>

<section id="features" class="relative overflow-hidden px-4 py-24 sm:py-32 lg:py-40">
	<div class="relative z-10 mx-auto max-w-6xl">
		<!-- Section Header -->
		<div class="mb-16 text-center lg:mb-20">
			<div class="pill animate-fade-in mx-auto mb-6 w-max">
				<span class="h-1.5 w-1.5 rounded-full bg-paper-accent"></span>
				Precision tools for modern authors
			</div>

			<h2
				class="font-serif text-3xl tracking-tight text-paper-text sm:text-4xl lg:text-5xl {mounted
					? 'animate-fade-in-up'
					: 'opacity-0'}"
			>
				Everything you need to <span class="gradient-text">write</span>
			</h2>

			<p
				class="mx-auto mt-4 max-w-2xl text-lg text-paper-text-light {mounted
					? 'animate-fade-in-up'
					: 'opacity-0'}"
				style:animation-delay="0.1s"
			>
				Powerful features that stay out of your way until you need them
			</p>
		</div>

		<!-- Bento Grid -->
		<div class="grid gap-4 lg:grid-cols-12 lg:grid-rows-[auto_auto_auto] lg:gap-5">
			<!-- AI Completion - Full Width -->
			<div
				class="feature-card lg:col-span-12 {visible_cards.has('ai')
					? 'animate-scale-in'
					: 'opacity-0'}"
				data-card-id="ai"
			>
				<div class="card-elevated overflow-hidden p-6 lg:p-8">
					<div class="flex flex-col gap-6 lg:flex-row lg:items-start lg:gap-8">
						<!-- Info -->
						<div class="lg:w-1/3">
							<div class="feature-icon mb-4">
								<svg
									class="h-5 w-5"
									fill="none"
									stroke="currentColor"
									stroke-width="1.5"
									viewBox="0 0 24 24"
								>
									<path
										stroke-linecap="round"
										stroke-linejoin="round"
										d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z"
									></path>
								</svg>
							</div>
							<h3 class="mb-2 font-serif text-xl font-semibold text-paper-text lg:text-2xl">
								AI Completion
							</h3>
							<p class="text-sm leading-relaxed text-paper-text-light lg:text-base">
								Break through writer's block with intelligent suggestions that match your voice and
								style.
							</p>
						</div>

						<!-- Demo -->
						<div class="flex-1">
							<div class="rounded-2xl border border-paper-border bg-paper-cream/60 p-5 lg:p-6">
								<div class="mb-4 flex items-center justify-between">
									<span class="text-xs font-medium tracking-wide text-paper-text-muted uppercase"
										>Live Preview</span
									>
									<span class="flex items-center gap-2 text-xs font-medium text-paper-accent">
										<span class="h-1.5 w-1.5 animate-pulse rounded-full bg-paper-accent"></span>
										AI Active
									</span>
								</div>

								<div
									class="rounded-xl bg-paper-beige/50 p-4 lg:p-5"
									style:font-family="'iA Writer Duo', monospace"
								>
									<div class="min-h-16 text-sm leading-relaxed text-paper-text lg:text-base">
										<span class="text-paper-text-light">{ai_base_text}</span>
										<span class="font-medium text-paper-accent">{ai_current_text}</span>
										<span
											class="ml-0.5 inline-block h-4 w-0.5 animate-pulse bg-paper-accent align-middle"
										></span>
									</div>
								</div>

								<div class="mt-4 flex flex-wrap gap-2">
									<span
										class="rounded-lg bg-paper-accent/10 px-3 py-1.5 text-xs font-medium text-paper-text"
										>Tone</span
									>
									<span
										class="rounded-lg bg-paper-iris/10 px-3 py-1.5 text-xs font-medium text-paper-text"
										>Continuity</span
									>
									<span
										class="rounded-lg bg-paper-accent-pink/10 px-3 py-1.5 text-xs font-medium text-paper-text"
										>Ideas</span
									>
								</div>
							</div>
						</div>
					</div>
				</div>
			</div>

			<!-- Organize with Scenes & Chapters - 6 cols -->
			<div
				class="feature-card lg:col-span-7 {visible_cards.has('structure')
					? 'animate-scale-in'
					: 'opacity-0'}"
				data-card-id="structure"
				style:animation-delay="0.08s"
			>
				<div class="card-elevated h-full overflow-hidden p-6">
					<div class="feature-icon mb-4">
						<svg
							class="h-5 w-5"
							fill="none"
							stroke="currentColor"
							stroke-width="1.5"
							viewBox="0 0 24 24"
						>
							<path
								stroke-linecap="round"
								stroke-linejoin="round"
								d="M3.75 12h16.5M5.625 4.5h12.75a1.875 1.875 0 010 3.75H5.625a1.875 1.875 0 010-3.75zM3.75 19.5h16.5"
							></path>
						</svg>
					</div>
					<h3 class="mb-2 font-serif text-lg font-semibold text-paper-text lg:text-xl">
						Organize with Scenes & Chapters
					</h3>
					<p class="mb-5 text-sm text-paper-text-light">
						Structure your manuscript with nested chapters and scenes.
					</p>

					<!-- Mini Sidebar Demo -->
					<div class="rounded-xl border border-paper-border bg-paper-cream/60 p-4">
						<div class="space-y-2">
							<div class="flex items-center gap-2">
								<div
									class="flex h-7 w-7 items-center justify-center rounded-lg bg-paper-beige text-[10px] font-bold text-paper-text-muted"
								>
									1
								</div>
								<div class="flex-1">
									<div class="h-2 w-3/4 rounded bg-paper-text/10"></div>
								</div>
							</div>
							<div class="ml-8 space-y-1.5">
								<div class="flex items-center gap-2 rounded-lg bg-paper-accent/10 px-2.5 py-1.5">
									<span class="h-1.5 w-1.5 rounded-full bg-paper-accent"></span>
									<span class="text-[11px] font-medium text-paper-text">Scene 1</span>
								</div>
								<div class="flex items-center gap-2 px-2.5 py-1.5">
									<span class="h-1.5 w-1.5 rounded-full bg-paper-text-muted/30"></span>
									<span class="text-[11px] text-paper-text-muted">Scene 2</span>
								</div>
							</div>
							<div class="flex items-center gap-2">
								<div
									class="flex h-7 w-7 items-center justify-center rounded-lg bg-paper-beige text-[10px] font-bold text-paper-text-muted"
								>
									2
								</div>
								<div class="flex-1">
									<div class="h-2 w-1/2 rounded bg-paper-text/10"></div>
								</div>
							</div>
						</div>
					</div>
				</div>
			</div>

			<!-- Track Progress - 3 cols -->
			<div
				class="feature-card lg:col-span-5 {visible_cards.has('progress')
					? 'animate-scale-in'
					: 'opacity-0'}"
				data-card-id="progress"
				style:animation-delay="0.12s"
			>
				<div class="card-elevated h-full overflow-hidden p-6">
					<div class="feature-icon mb-4">
						<svg
							class="h-5 w-5"
							fill="none"
							stroke="currentColor"
							stroke-width="1.5"
							viewBox="0 0 24 24"
						>
							<path
								stroke-linecap="round"
								stroke-linejoin="round"
								d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
							></path>
						</svg>
					</div>
					<h3 class="mb-2 font-serif text-lg font-semibold text-paper-text lg:text-xl">
						Track Progress
					</h3>
					<p class="mb-5 text-sm text-paper-text-light">
						Monitor your writing streaks and word counts.
					</p>

					<!-- Streak Chart -->
					<div class="rounded-xl border border-paper-border bg-paper-cream/60 p-4">
						<div class="mb-3 flex items-center justify-between">
							<span class="text-xs font-medium text-paper-text-muted">Writing Streak</span>
							<span
								class="rounded-full bg-paper-accent/10 px-2.5 py-1 text-xs font-semibold text-paper-accent"
								>21 days</span
							>
						</div>
						<div class="flex h-28 items-end gap-1.5">
							{#each streak_bars as bar, index (index)}
								<div
									class="flex-1 rounded-t-md bg-paper-accent"
									style:height={bar.height}
									style:opacity={bar.opacity}
								></div>
							{/each}
						</div>
					</div>
				</div>
			</div>

			<!-- Distraction Free - 4 cols -->
			<div
				class="feature-card lg:col-span-4 {visible_cards.has('distraction-free')
					? 'animate-scale-in'
					: 'opacity-0'}"
				data-card-id="distraction-free"
				style:animation-delay="0.15s"
			>
				<div class="card-elevated h-full overflow-hidden p-6">
					<div class="feature-icon mb-4">
						<svg
							class="h-5 w-5"
							fill="none"
							stroke="currentColor"
							stroke-width="1.5"
							viewBox="0 0 24 24"
						>
							<path stroke-linecap="round" stroke-linejoin="round" d="M12 20l9-11h-6V4l-9 11h6v5z"
							></path>
						</svg>
					</div>
					<h3 class="mb-2 font-serif text-lg font-semibold text-paper-text lg:text-xl">
						Distraction Free
					</h3>
					<p class="mb-5 text-sm text-paper-text-light">
						Focus on your words with a clean interface.
					</p>

					<div class="rounded-xl border border-paper-border bg-paper-cream/60 p-4">
						<div class="space-y-2">
							{#each [70, 85, 75, 90, 80] as width (width)}
								<div class="h-2 rounded bg-paper-text/8" style:width="{width}%"></div>
							{/each}
						</div>
						<div
							class="mt-4 flex items-center justify-between rounded-lg bg-paper-beige/60 px-3 py-2"
						>
							<span class="text-[10px] font-medium tracking-wide text-paper-text-muted uppercase"
								>Focus Mode</span
							>
							<span
								class="rounded-full bg-paper-accent/15 px-2 py-0.5 text-[10px] font-semibold text-paper-accent"
								>On</span
							>
						</div>
					</div>
				</div>
			</div>

			<!-- Project Notes - 4 cols -->
			<div
				class="feature-card lg:col-span-4 {visible_cards.has('notes')
					? 'animate-scale-in'
					: 'opacity-0'}"
				data-card-id="notes"
				style:animation-delay="0.2s"
			>
				<div class="card-elevated h-full overflow-hidden p-6">
					<div class="feature-icon mb-4">
						<svg
							class="h-5 w-5"
							fill="none"
							stroke="currentColor"
							stroke-width="1.5"
							viewBox="0 0 24 24"
						>
							<path
								stroke-linecap="round"
								stroke-linejoin="round"
								d="M19.5 14.25v-2.625a3.375 3.375 0 00-3.375-3.375h-1.5A1.125 1.125 0 0113.5 7.125v-1.5a3.375 3.375 0 00-3.375-3.375H8.25m0 12.75h7.5m-7.5 3H12M10.5 2.25H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 00-9-9z"
							></path>
						</svg>
					</div>
					<h3 class="mb-2 font-serif text-lg font-semibold text-paper-text lg:text-xl">
						Project Notes
					</h3>
					<p class="mb-5 text-sm text-paper-text-light">Keep your story details organized.</p>

					<div class="grid grid-cols-2 gap-2">
						{#each [{ name: 'Characters', color: 'paper-accent' }, { name: 'Plot', color: 'paper-iris' }, { name: 'Research', color: 'paper-accent-pink' }, { name: 'Timeline', color: 'paper-accent' }] as note (note.name)}
							<div class="rounded-xl border border-paper-border bg-paper-cream/60 p-3">
								<div class="mb-2 space-y-1">
									<div class="h-1.5 w-full rounded bg-{note.color}/25"></div>
									<div class="h-1.5 w-2/3 rounded bg-{note.color}/15"></div>
								</div>
								<span class="text-[10px] font-medium text-paper-text-muted">{note.name}</span>
							</div>
						{/each}
					</div>
				</div>
			</div>

			<!-- Export Anywhere - 4 cols -->
			<div
				class="feature-card lg:col-span-4 {visible_cards.has('export')
					? 'animate-scale-in'
					: 'opacity-0'}"
				data-card-id="export"
				style:animation-delay="0.25s"
			>
				<div class="card-elevated h-full overflow-hidden p-6">
					<div class="feature-icon mb-4">
						<svg
							class="h-5 w-5"
							fill="none"
							stroke="currentColor"
							stroke-width="1.5"
							viewBox="0 0 24 24"
						>
							<path
								stroke-linecap="round"
								stroke-linejoin="round"
								d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
							></path>
						</svg>
					</div>
					<h3 class="mb-2 font-serif text-lg font-semibold text-paper-text lg:text-xl">
						Export Anywhere
					</h3>
					<p class="mb-5 text-sm text-paper-text-light">Professional formats for every need.</p>

					<div class="space-y-2">
						{#each [{ format: 'EPUB', label: 'E-book' }, { format: 'PDF', label: 'Print ready' }, { format: 'RTF', label: 'Universal' }] as item (item.format)}
							<div
								class="flex items-center gap-3 rounded-xl border border-paper-border bg-paper-cream/60 p-3"
							>
								<div class="flex h-8 w-8 items-center justify-center rounded-lg bg-paper-beige">
									<span class="text-[10px] font-bold text-paper-accent">{item.format}</span>
								</div>
								<span class="text-xs text-paper-text-light">{item.label}</span>
							</div>
						{/each}
					</div>
				</div>
			</div>
		</div>
	</div>
</section>
