<script lang="ts">
	import '@fontsource/ia-writer-duo/400.css';
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
		" found a 1952 newspaper clipping mentioning her grandfather's mysterious disappearance that day.",
		" smiled recognizing her ancestor's brilliant inventions, centuries ahead of their time.",
		" heard footsteps. An old man warned: they'll come for you if found.",
		' felt cold air and heard whispers from the shadows saying: not yet.',
		' saw her childhood home transformed, rooms arranged impossibly, memories suddenly questioned.',
		' discovered a compartment matching her wrist tattoo, filled with impossible artifacts.',
		' stepped into a crystalline city among stars where beings welcomed her back.',
		' realized too late as infinite versions of herself ran out of time.',
		' knew her past and future were connected in an impossible causal loop.'
	];

	const streak_bars = [
		{ height: '5rem', color: 'bg-paper-accent/20' },
		{ height: '7.4rem', color: 'bg-paper-accent/35' },
		{ height: '5.5rem', color: 'bg-paper-accent-light/25' },
		{ height: '8.4rem', color: 'bg-paper-accent/40' },
		{ height: '6.6rem', color: 'bg-paper-accent-pink/25' },
		{ height: '7.2rem', color: 'bg-paper-accent/30' },
		{ height: '5.5rem', color: 'bg-paper-accent-light/30' },
		{ height: '8.2rem', color: 'bg-paper-accent-pink/30' },
		{ height: '7.4rem', color: 'bg-paper-accent/40' },
		{ height: '6rem', color: 'bg-paper-accent-light/30' }
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

							// Start AI typing animation when AI card becomes visible
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
			// Reset to empty
			ai_current_text = '';
			await sleep(100);

			// Type out the completion
			const completion = ai_completions[ai_completion_index];
			for (let i = 0; i <= completion.length; i++) {
				ai_current_text = completion.substring(0, i);
				await sleep(20);
			}

			// Pause to show complete text
			await sleep(2500);

			// Backspace effect
			for (let i = completion.length; i >= 0; i--) {
				ai_current_text = completion.substring(0, i);
				await sleep(10);
			}

			// Move to next completion
			ai_completion_index = (ai_completion_index + 1) % ai_completions.length;
			await sleep(100);
		}
	}

	function sleep(ms: number) {
		return new Promise((resolve) => setTimeout(resolve, ms));
	}
</script>

<section id="features" class="relative overflow-hidden px-4 py-24 sm:py-32">
	<div class="absolute inset-0 bg-gradient-to-b from-white via-paper-cream/70 to-white"></div>
	<div class="absolute inset-0" style:background="var(--gradient-radial)"></div>
	<div class="aurora-blob left-10 top-10 h-56 w-56 bg-[rgba(124,140,255,0.2)]"></div>
	<div class="aurora-blob right-6 bottom-0 h-64 w-64 bg-[rgba(161,241,210,0.18)]"></div>
	<div class="pointer-events-none absolute inset-x-12 top-12 rounded-[32px] border border-white/35 bg-white/30 shadow-[0_20px_60px_rgba(15,23,42,0.08)] backdrop-blur-3xl"></div>

	<div class="relative z-10 mx-auto max-w-7xl">
		<div class="mb-12 text-center">
			<div class="pill mx-auto w-max shadow-md">
				<span class="h-2 w-2 rounded-full bg-paper-accent shadow-[0_0_10px_rgba(124,140,255,0.5)]"></span>
				Precision tools for modern authors
			</div>
			<h2
				class="mt-6 mb-3 font-serif text-4xl text-paper-text sm:text-5xl lg:text-6xl {mounted
					? 'animate-fade-in-up'
					: 'opacity-0'}"
			>
				Everything you need to <span class="gradient-text">write</span>
			</h2>
			<p class="mx-auto max-w-3xl text-base text-paper-text-light sm:text-lg">
				Powerful features that stay out of your way until you need them
			</p>
		</div>

		<div class="grid gap-5 sm:gap-6 lg:gap-7 lg:auto-rows-[minmax(210px,auto)] lg:grid-cols-12">
			<div
				class="feature-card lg:col-span-12 {visible_cards.has('ai') ? 'animate-scale-in' : 'opacity-0'}"
				data-card-id="ai"
			>
				<div class="glass relative h-full overflow-hidden rounded-3xl p-6 shadow-xl sm:p-7">
					<div class="absolute inset-0 bg-gradient-to-br from-paper-accent-light/25 via-white/40 to-paper-accent-pink/15"></div>
					<div class="relative flex h-full flex-col gap-4">
						<div class="flex items-center justify-between gap-3">
							<div class="flex items-center gap-3">
								<div class="flex h-11 w-11 items-center justify-center rounded-2xl bg-paper-accent/15 text-paper-accent">
									<svg class="h-5 w-5" fill="none" stroke="currentColor" stroke-width="1.6" viewBox="0 0 24 24">
										<path
											stroke-linecap="round"
											stroke-linejoin="round"
											d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z"
										></path>
									</svg>
								</div>
								<div>
									<h3 class="font-serif text-xl text-paper-text sm:text-2xl">AI Completion</h3>
									<p class="text-sm text-paper-text-light">Break through writer's block instantly</p>
								</div>
							</div>
						</div>

							<div class="mt-auto rounded-2xl border border-white/60 bg-white/70 p-5 shadow-inner shadow-white/60">
								<div class="flex items-center justify-between text-xs font-semibold uppercase tracking-[0.16em] text-paper-text-muted">
									<span>Type as you think</span>
									<span class="flex items-center gap-2 text-paper-text">
										<span class="h-2 w-2 rounded-full bg-paper-accent animate-pulse"></span>
										Live
									</span>
								</div>
								<div class="mt-4 rounded-xl bg-paper-gray/50 p-4" style="font-family: 'iA Writer Duo', monospace;">
									<div class="min-h-20 text-sm leading-relaxed text-paper-text">
										<span class="text-paper-text-light">{ai_base_text}</span>
										<span class="gradient-text-strong font-semibold">{ai_current_text}</span>
										<span class="ml-1 inline-block h-4 w-0.5 animate-pulse bg-paper-accent align-middle"></span>
									</div>
								</div>
							<div class="mt-4 grid grid-cols-3 gap-3 text-[11px] font-semibold uppercase tracking-[0.14em] text-paper-text">
								<div class="rounded-lg bg-paper-accent/15 px-3 py-2 text-center">Tone</div>
								<div class="rounded-lg bg-paper-accent-light/15 px-3 py-2 text-center">Continuity</div>
								<div class="rounded-lg bg-paper-accent-pink/15 px-3 py-2 text-center">Ideas</div>
							</div>
						</div>
					</div>
				</div>
			</div>

			<div
				class="feature-card lg:col-span-6 {visible_cards.has('structure')
					? 'animate-scale-in'
					: 'opacity-0'}"
				data-card-id="structure"
				style:animation-delay="0.08s"
			>
				<div class="glass-strong relative h-full overflow-hidden rounded-3xl p-7 shadow-xl sm:p-8">
					<div class="absolute inset-0 bg-gradient-to-br from-paper-accent/10 via-white/40 to-paper-accent-light/10"></div>
					<div class="relative flex h-full flex-col gap-6">
						<div class="flex flex-wrap items-start justify-between gap-4">
							<div class="flex items-center gap-3">
								<div class="flex h-12 w-12 items-center justify-center rounded-2xl bg-gradient-to-br from-paper-accent/20 to-paper-accent-light/20 text-paper-accent">
									<svg class="h-6 w-6" fill="none" stroke="currentColor" stroke-width="1.6" viewBox="0 0 24 24">
										<path
											stroke-linecap="round"
											stroke-linejoin="round"
											d="M3.75 12h16.5M5.625 4.5h12.75a1.875 1.875 0 010 3.75H5.625a1.875 1.875 0 010-3.75zM3.75 19.5h16.5"
										></path>
									</svg>
								</div>
								<div>
									<h3 class="font-serif text-2xl text-paper-text">Organize with Scenes & Chapters</h3>
									<p class="text-sm text-paper-text-light sm:text-base">
										Structure your manuscript with nested chapters and scenes.
									</p>
								</div>
							</div>
						</div>

						<div class="grid gap-5 lg:grid-cols-2">
							<div class="rounded-2xl border border-white/60 bg-white/70 p-4 shadow-inner shadow-white/50">
								<p class="text-xs font-semibold uppercase tracking-[0.18em] text-paper-text-muted">Manuscript map</p>
								<div class="mt-3 space-y-3">
									<div class="flex items-center gap-3">
										<div class="flex h-10 w-10 items-center justify-center rounded-xl bg-paper-gray text-sm font-bold text-paper-text-muted">Ch 1</div>
										<div class="flex-1 space-y-2">
											<div class="h-2.5 w-3/4 rounded-full bg-paper-text/10"></div>
											<div class="h-2 w-5/6 rounded-full bg-paper-text/8"></div>
										</div>
									</div>
									<div class="ml-12 space-y-2">
										<div class="flex items-center gap-2 rounded-lg bg-paper-accent/10 px-3 py-2 text-xs font-semibold text-paper-text">
											<span class="h-2 w-2 rounded-full bg-paper-accent"></span>
											Scene 1
										</div>
										<div class="ml-3 space-y-1">
											<div class="h-1.5 w-10/12 rounded-full bg-paper-text/10"></div>
											<div class="h-1.5 w-9/12 rounded-full bg-paper-text/10"></div>
										</div>
									</div>
									<div class="ml-12 space-y-2">
										<div class="flex items-center gap-2 rounded-lg bg-paper-accent-light/10 px-3 py-2 text-xs font-semibold text-paper-text">
											<span class="h-2 w-2 rounded-full bg-paper-accent-light"></span>
											Scene 2
										</div>
										<div class="ml-3 space-y-1">
											<div class="h-1.5 w-11/12 rounded-full bg-paper-text/10"></div>
											<div class="h-1.5 w-8/12 rounded-full bg-paper-text/8"></div>
										</div>
									</div>
								</div>
							</div>
							<div class="flex flex-col gap-4 rounded-2xl border border-white/60 bg-white/70 p-4 shadow-inner shadow-white/50">
								<div class="flex items-center justify-between text-sm font-semibold text-paper-text">
									<span class="soft-gradient-text">Scene flow</span>
									<div class="rounded-full bg-paper-accent/10 px-3 py-1 text-xs text-paper-text">Balanced</div>
								</div>
								<div class="space-y-2">
									<div class="h-2.5 w-full rounded-full bg-paper-text/10"></div>
									<div class="h-2.5 w-11/12 rounded-full bg-paper-text/10"></div>
									<div class="h-2.5 w-10/12 rounded-full bg-paper-text/10"></div>
									<div class="h-2.5 w-9/12 rounded-full bg-paper-text/8"></div>
								</div>
								<div class="rounded-xl border border-paper-gray/70 bg-paper-gray/50 p-3">
									<p class="text-xs font-semibold uppercase tracking-[0.16em] text-paper-text-muted">Draft status</p>
									<div class="mt-2 grid grid-cols-3 gap-2 text-[10px] font-semibold uppercase tracking-[0.14em] text-paper-text">
										<div class="rounded-lg bg-paper-accent/15 px-3 py-2 text-center">Outline</div>
										<div class="rounded-lg bg-paper-accent-light/15 px-3 py-2 text-center">Draft</div>
										<div class="rounded-lg bg-paper-accent-pink/15 px-3 py-2 text-center">Polish</div>
									</div>
								</div>
							</div>
						</div>
					</div>
					<div class="pointer-events-none absolute -inset-8 -z-10 bg-gradient-to-tr from-paper-accent/15 via-paper-accent-light/12 to-paper-accent-pink/12 blur-3xl"></div>
				</div>
			</div>

			<div
				class="feature-card lg:col-span-3 {visible_cards.has('progress') ? 'animate-scale-in' : 'opacity-0'}"
				data-card-id="progress"
				style:animation-delay="0.12s"
			>
				<div class="glass relative h-full overflow-hidden rounded-3xl p-6 shadow-xl sm:p-7">
					<div class="absolute inset-0 bg-gradient-to-bl from-paper-accent/10 via-white/40 to-paper-accent-light/10"></div>
					<div class="relative flex h-full flex-col gap-5">
						<div class="flex items-center justify-between gap-3">
							<div class="flex items-center gap-3">
								<div class="flex h-11 w-11 items-center justify-center rounded-2xl bg-paper-accent/15 text-paper-accent">
									<svg class="h-5 w-5" fill="none" stroke="currentColor" stroke-width="1.6" viewBox="0 0 24 24">
										<path
											stroke-linecap="round"
											stroke-linejoin="round"
											d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
										/>
									</svg>
								</div>
								<div>
									<h3 class="font-serif text-xl text-paper-text sm:text-2xl">Track Progress</h3>
								</div>
							</div>
						</div>
						<div class="flex flex-1 flex-col rounded-2xl border border-white/60 bg-white/70 p-4 pb-0 shadow-inner shadow-white/50">
							<div class="flex items-center justify-between text-xs font-semibold uppercase tracking-[0.16em] text-paper-text-muted">
								<span>Streak</span>
								<span class="rounded-full bg-paper-accent/15 px-3 py-1 text-paper-text">21 days</span>
							</div>
							<div class="mt-4 flex flex-1 items-end gap-3">
								{#each streak_bars as bar}
									<div class={`flex-1 rounded-t-lg ${bar.color}`} style={`height:${bar.height};`}></div>
								{/each}
							</div>
						</div>
					</div>
				</div>
			</div>

			<div
				class="feature-card lg:col-span-3 {visible_cards.has('distraction-free') ? 'animate-scale-in' : 'opacity-0'}"
				data-card-id="distraction-free"
				style:animation-delay="0.15s"
			>
				<div class="glass relative h-full overflow-hidden rounded-3xl p-6 shadow-xl sm:p-7">
					<div class="absolute inset-0 bg-gradient-to-tr from-paper-accent/12 via-white/50 to-paper-accent-light/12"></div>
					<div class="relative flex h-full flex-col gap-3 sm:gap-4">
						<div class="flex items-start justify-between gap-3">
							<div class="flex items-center gap-3">
								<div class="flex h-11 w-11 items-center justify-center rounded-2xl bg-paper-accent/15 text-paper-accent">
									<svg class="h-5 w-5" fill="none" stroke="currentColor" stroke-width="1.6" viewBox="0 0 24 24">
										<path stroke-linecap="round" stroke-linejoin="round" d="M12 20l9-11h-6V4l-9 11h6v5z"></path>
									</svg>
								</div>
								<div>
									<h3 class="font-serif text-xl text-paper-text sm:text-2xl">Distraction Free</h3>
								</div>
							</div>
						</div>
						<div class="mt-auto rounded-2xl border border-white/60 bg-white/70 p-4 shadow-inner shadow-white/60">
							<div class="space-y-2">
								<div class="space-y-1.5">
									<div class="h-1.5 w-3/4 rounded-full bg-paper-text/8"></div>
									<div class="h-1.5 w-4/5 rounded-full bg-paper-text/8"></div>
								</div>
								<div class="space-y-1.5">
									<div class="h-1.5 w-2/3 rounded-full bg-paper-text/8"></div>
									<div class="h-1.5 w-full rounded-full bg-paper-text/8"></div>
								</div>
								<div class="space-y-1.5">
									<div class="h-1.5 w-full rounded-full bg-paper-text/10"></div>
									<div class="h-1.5 w-5/6 rounded-full bg-paper-text/10"></div>
								</div>
								<div class="space-y-1.5">
									<div class="h-1.5 w-3/4 rounded-full bg-paper-text/10"></div>
									<div class="h-1.5 w-4/5 rounded-full bg-paper-text/10"></div>
								</div>
							</div>
							<div class="mt-4 flex items-center justify-between rounded-xl border border-paper-gray/80 bg-paper-gray/50 px-4 py-2.5 text-xs font-semibold uppercase tracking-[0.16em] text-paper-text">
								<span>Focus mode</span>
								<span class="rounded-full bg-paper-accent/20 px-3 py-1 text-paper-text">On</span>
							</div>
						</div>
					</div>
				</div>
			</div>

			<div
				class="feature-card lg:col-span-6 {visible_cards.has('notes') ? 'animate-scale-in' : 'opacity-0'}"
				data-card-id="notes"
				style:animation-delay="0.2s"
			>
				<div class="glass relative h-full overflow-hidden rounded-3xl p-6 shadow-xl sm:p-7">
					<div class="absolute inset-0 bg-gradient-to-tr from-paper-accent/12 via-white/55 to-paper-accent-light/18"></div>
					<div class="relative flex h-full flex-col gap-3 sm:gap-4">
						<div class="flex items-start justify-between gap-3">
							<div class="flex items-center gap-3">
								<div class="flex h-11 w-11 items-center justify-center rounded-2xl bg-paper-accent/15 text-paper-accent">
									<svg class="h-5 w-5" fill="none" stroke="currentColor" stroke-width="1.6" viewBox="0 0 24 24">
										<path
											stroke-linecap="round"
											stroke-linejoin="round"
											d="M19.5 14.25v-2.625a3.375 3.375 0 00-3.375-3.375h-1.5A1.125 1.125 0 0113.5 7.125v-1.5a3.375 3.375 0 00-3.375-3.375H8.25m0 12.75h7.5m-7.5 3H12M10.5 2.25H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 00-9-9z"
										/>
									</svg>
								</div>
								<div>
									<h3 class="font-serif text-xl text-paper-text sm:text-2xl">Project Notes</h3>
									<p class="text-sm text-paper-text-light">Keep your story details organized</p>
								</div>
							</div>
						</div>
						<div class="mt-auto grid grid-cols-2 gap-2.5">
							<div class="flex flex-col justify-between rounded-2xl border border-white/60 bg-white/70 p-3 shadow-inner shadow-white/60">
								<div class="space-y-2">
									<div class="h-2 w-full rounded-full bg-paper-accent/30"></div>
									<div class="h-2 w-3/4 rounded-full bg-paper-accent/20"></div>
								</div>
								<div class="mt-2 text-xs font-semibold text-paper-accent">Characters</div>
							</div>
							<div class="flex flex-col justify-between rounded-2xl border border-white/60 bg-white/70 p-3 shadow-inner shadow-white/60">
								<div class="space-y-2">
									<div class="h-2 w-full rounded-full bg-paper-accent-light/30"></div>
									<div class="h-2 w-2/3 rounded-full bg-paper-accent-light/20"></div>
								</div>
								<div class="mt-2 text-xs font-semibold text-paper-accent-light">Plot</div>
							</div>
							<div class="flex flex-col justify-between rounded-2xl border border-white/60 bg-white/70 p-3 shadow-inner shadow-white/60">
								<div class="space-y-2">
									<div class="h-2 w-full rounded-full bg-paper-accent-pink/30"></div>
									<div class="h-2 w-5/6 rounded-full bg-paper-accent-pink/20"></div>
								</div>
								<div class="mt-2 text-xs font-semibold text-paper-accent-pink">Research</div>
							</div>
							<div class="flex flex-col justify-between rounded-2xl border border-white/60 bg-white/70 p-3 shadow-inner shadow-white/60">
								<div class="space-y-2">
									<div class="h-2 w-full rounded-full bg-paper-accent/30"></div>
									<div class="h-2 w-1/2 rounded-full bg-paper-accent/20"></div>
								</div>
								<div class="mt-2 text-xs font-semibold text-paper-accent">Timeline</div>
							</div>
							<div class="flex flex-col justify-between rounded-2xl border border-white/60 bg-white/70 p-3 shadow-inner shadow-white/60">
								<div class="space-y-2">
									<div class="h-2 w-full rounded-full bg-paper-accent-light/30"></div>
									<div class="h-2 w-4/5 rounded-full bg-paper-accent-light/20"></div>
								</div>
								<div class="mt-2 text-xs font-semibold text-paper-accent-light">Scenes</div>
							</div>
							<div class="flex flex-col justify-between rounded-2xl border border-white/60 bg-white/70 p-3 shadow-inner shadow-white/60">
								<div class="space-y-2">
									<div class="h-2 w-full rounded-full bg-paper-accent-pink/30"></div>
									<div class="h-2 w-2/3 rounded-full bg-paper-accent-pink/20"></div>
								</div>
								<div class="mt-2 text-xs font-semibold text-paper-accent-pink">Dialogue</div>
							</div>
						</div>
					</div>
				</div>
			</div>

			<div
				class="feature-card lg:col-span-6 {visible_cards.has('export') ? 'animate-scale-in' : 'opacity-0'}"
				data-card-id="export"
				style:animation-delay="0.25s"
			>
				<div class="glass relative h-full overflow-hidden rounded-3xl p-6 shadow-xl sm:p-7">
					<div class="absolute inset-0 bg-gradient-to-br from-paper-accent/12 via-white/55 to-paper-accent-pink/15"></div>
					<div class="relative flex h-full flex-col gap-4">
						<div class="flex items-center gap-3">
							<div class="flex h-11 w-11 items-center justify-center rounded-2xl bg-paper-accent/15 text-paper-accent">
								<svg class="h-5 w-5" fill="none" stroke="currentColor" stroke-width="1.6" viewBox="0 0 24 24">
									<path
										stroke-linecap="round"
										stroke-linejoin="round"
										d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
									></path>
								</svg>
							</div>
							<div>
								<h3 class="font-serif text-xl text-paper-text sm:text-2xl">Export Anywhere</h3>
								<p class="text-sm text-paper-text-light">Professional formats for every need</p>
							</div>
						</div>
						<div class="flex flex-col gap-2.5">
							<div class="flex items-center gap-3 rounded-2xl border border-white/60 bg-white/70 p-3 shadow-inner shadow-white/60">
								<div class="flex h-10 w-10 items-center justify-center rounded-xl bg-white">
									<span class="text-xs font-bold text-paper-text-muted">EPUB</span>
								</div>
								<div class="flex-1 text-sm text-paper-text">E-book format</div>
								<span class="rounded-full bg-paper-accent/15 px-3 py-1 text-[11px] font-semibold uppercase tracking-[0.14em] text-paper-text">Share</span>
							</div>
							<div class="flex items-center gap-3 rounded-2xl border border-white/60 bg-white/70 p-3 shadow-inner shadow-white/60">
								<div class="flex h-10 w-10 items-center justify-center rounded-xl bg-white">
									<span class="text-xs font-bold text-paper-accent">PDF</span>
								</div>
								<div class="flex-1 text-sm text-paper-text">Print ready</div>
								<span class="rounded-full bg-paper-accent-light/15 px-3 py-1 text-[11px] font-semibold uppercase tracking-[0.14em] text-paper-text">Pitch</span>
							</div>
							<div class="flex items-center gap-3 rounded-2xl border border-white/60 bg-white/70 p-3 shadow-inner shadow-white/60">
								<div class="flex h-10 w-10 items-center justify-center rounded-xl bg-white">
									<span class="text-xs font-bold text-paper-accent-light">RTF</span>
								</div>
								<div class="flex-1 text-sm text-paper-text">Universal format</div>
								<span class="rounded-full bg-paper-accent-pink/15 px-3 py-1 text-[11px] font-semibold uppercase tracking-[0.14em] text-paper-text">Share</span>
							</div>
						</div>
					</div>
				</div>
			</div>
		</div>
	</div>
</section>
