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
		' gasped at the sight before her.',
		' found nothing but darkness.',
		' smiled at the familiar face.',
		' heard footsteps approaching quickly.',
		' felt a cold breeze rush past.',
		' saw her childhood home again.',
		' discovered a hidden garden blooming.',
		' stepped into another world entirely.',
		' realized she was too late.',
		' knew everything had changed forever.'
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
			await sleep(300);

			// Type out the completion
			const completion = ai_completions[ai_completion_index];
			for (let i = 0; i <= completion.length; i++) {
				ai_current_text = completion.substring(0, i);
				await sleep(30);
			}

			// Pause to show complete text
			await sleep(2000);

			// Backspace effect
			for (let i = completion.length; i >= 0; i--) {
				ai_current_text = completion.substring(0, i);
				await sleep(15);
			}

			// Move to next completion
			ai_completion_index = (ai_completion_index + 1) % ai_completions.length;
			await sleep(200);
		}
	}

	function sleep(ms: number) {
		return new Promise((resolve) => setTimeout(resolve, ms));
	}
</script>

<section class="relative overflow-hidden px-4 py-24 sm:py-32">
	<!-- Background -->
	<div class="absolute inset-0 bg-linear-to-b from-white via-paper-cream to-white"></div>

	<div class="relative z-10 mx-auto max-w-7xl">
		<!-- Section header -->
		<div class="mb-16 text-center">
			<h2
				class="mb-4 font-serif text-4xl text-paper-text sm:text-5xl lg:text-6xl {mounted
					? 'animate-fade-in-up'
					: 'opacity-0'}"
			>
				Everything you need to <span class="gradient-text">write</span>
			</h2>
			<p class="mx-auto max-w-2xl">
				Powerful features that stay out of your way until you need them
			</p>
		</div>

		<!-- Bento Grid -->
		<div class="grid gap-4 sm:gap-6 lg:grid-cols-3 lg:grid-rows-[repeat(3,minmax(180px,auto))]">
			<!-- Large card - Project Structure -->
			<div
				class="feature-card lg:col-span-2 lg:row-span-2 {visible_cards.has('structure')
					? 'animate-scale-in'
					: 'opacity-0'}"
				data-card-id="structure"
			>
				<div
					class="glass group relative h-full overflow-hidden rounded-2xl p-8 shadow-sm sm:rounded-3xl sm:p-10 lg:p-12"
				>
					<div class="relative z-10 flex h-full flex-col">
						<div class="mb-6">
							<div
								class="mb-4 flex w-full items-center gap-3 rounded-xl bg-linear-to-br from-paper-accent/10 to-paper-accent-light/10 p-3"
							>
								<svg
									class="h-6 w-6 shrink-0 text-paper-accent sm:h-8 sm:w-8"
									fill="none"
									stroke="currentColor"
									stroke-width="1.5"
									viewBox="0 0 24 24"
								>
									<path
										stroke-linecap="round"
										stroke-linejoin="round"
										d="M3.75 12h16.5m-16.5 3.75h16.5M3.75 19.5h16.5M5.625 4.5h12.75a1.875 1.875 0 010 3.75H5.625a1.875 1.875 0 010-3.75z"
									></path>
								</svg>
								<h3 class="font-serif text-xl text-paper-text sm:text-2xl lg:text-3xl">
									Organize with Scenes & Chapters
								</h3>
							</div>
							<p class="max-w-lg text-base text-paper-text-light sm:text-lg">
								Structure your manuscript with nested chapters and scenes.
							</p>
						</div>

						<!-- Visual demo - hierarchical structure: chapters > scenes > paragraphs -->
						<div class="mt-auto">
							<div
								class="relative space-y-4 rounded-xl border border-paper-border bg-white p-6 sm:p-8 lg:p-10"
							>
								<!-- Chapter 1 -->
								<div class="space-y-3">
									<div class="flex items-center gap-3">
										<div
											class="flex h-10 w-10 items-center justify-center rounded-lg border border-paper-border bg-paper-gray"
										>
											<span class="font-bold text-paper-text-muted">1</span>
										</div>
										<div class="flex-1">
											<div class="h-3 rounded-full bg-paper-gray"></div>
										</div>
									</div>
									<!-- Scene 1 -->
									<div class="ml-13 space-y-2">
										<div class="h-2 max-w-[200px] flex-1 rounded-full bg-paper-text-muted/30"></div>
										<!-- Paragraphs in scene 1 -->
										<div class="ml-4 space-y-1">
											<div class="h-1 w-full max-w-[180px] rounded-full bg-paper-text/8"></div>
											<div class="h-1 w-full max-w-40 rounded-full bg-paper-text/8"></div>
											<div class="h-1 w-full max-w-[190px] rounded-full bg-paper-text/8"></div>
										</div>
									</div>
									<!-- Scene 2 -->
									<div class="ml-13 space-y-2">
										<div class="h-2 max-w-[180px] flex-1 rounded-full bg-paper-text-muted/30"></div>
										<!-- Paragraphs in scene 2 -->
										<div class="ml-4 space-y-1">
											<div class="h-1 w-full max-w-[170px] rounded-full bg-paper-text/8"></div>
											<div class="h-1 w-full max-w-[185px] rounded-full bg-paper-text/8"></div>
										</div>
									</div>
								</div>

								<!-- Chapter 2 -->
								<div class="space-y-3">
									<div class="flex items-center gap-3">
										<div
											class="flex h-10 w-10 items-center justify-center rounded-lg border border-paper-border bg-paper-gray"
										>
											<span class="font-bold text-paper-text-muted">2</span>
										</div>
										<div class="flex-1">
											<div class="h-3 rounded-full bg-paper-gray"></div>
										</div>
									</div>
									<!-- Scene 1 -->
									<div class="ml-13 space-y-2">
										<div class="h-2 max-w-[190px] flex-1 rounded-full bg-paper-text-muted/30"></div>
										<!-- Paragraphs in scene 1 -->
										<div class="ml-4 space-y-1">
											<div class="h-1 w-full max-w-[175px] rounded-full bg-paper-text/8"></div>
											<div class="h-1 w-full max-w-[195px] rounded-full bg-paper-text/8"></div>
											<div class="h-1 w-full max-w-[165px] rounded-full bg-paper-text/8"></div>
										</div>
									</div>
								</div>
							</div>
						</div>
					</div>
				</div>
			</div>

			<!-- Small card - AI Completion with animation -->
			<div
				class="feature-card {visible_cards.has('ai') ? 'animate-scale-in' : 'opacity-0'}"
				data-card-id="ai"
				style:animation-delay="0.1s"
			>
				<div
					class="glass group relative h-full overflow-hidden rounded-2xl p-6 shadow-sm sm:rounded-3xl sm:p-8"
				>
					<div class="mb-6">
						<div
							class="mb-4 flex w-full items-center gap-3 rounded-xl bg-linear-to-br from-paper-accent-light/10 to-paper-accent-pink/10 p-3"
						>
							<svg
								class="h-5 w-5 shrink-0 text-paper-accent-light sm:h-6 sm:w-6"
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
							<h3 class="font-serif text-lg text-paper-text sm:text-xl">AI Completion</h3>
						</div>
						<p class="text-sm text-paper-text-light">Break through writer's block instantly</p>
					</div>

					<!-- AI typewriter visualization -->
					<div class="mt-auto">
						<div class="rounded-lg bg-paper-gray/50 p-4">
							<div class="min-h-16 font-mono text-xs leading-relaxed text-paper-text sm:text-sm">
								<span class="text-paper-text-light">{ai_base_text}</span>
								<span class="gradient-text font-medium">{ai_current_text}</span>
								<span
									class="ml-0.5 inline-block h-3 w-0.5 animate-pulse bg-paper-accent align-middle sm:h-4"
								></span>
							</div>
						</div>
					</div>
				</div>
			</div>

			<!-- Small card - Progress Tracking -->
			<div
				class="feature-card {visible_cards.has('progress') ? 'animate-scale-in' : 'opacity-0'}"
				data-card-id="progress"
				style:animation-delay="0.15s"
			>
				<div
					class="glass group relative h-full overflow-hidden rounded-2xl p-6 shadow-sm sm:rounded-3xl sm:p-8"
				>
					<div class="mb-6">
						<div
							class="mb-4 flex w-full items-center gap-3 rounded-xl bg-linear-to-br from-paper-accent/10 to-paper-accent-light/10 p-3"
						>
							<svg
								class="h-5 w-5 shrink-0 text-paper-accent sm:h-6 sm:w-6"
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
							<h3 class="font-serif text-lg text-paper-text sm:text-xl">Track Progress</h3>
						</div>
						<p class="text-sm text-paper-text-light">Daily analytics for your writing journey</p>
					</div>

					<!-- Chart visualization -->
					<div class="mt-auto">
						<div class="flex items-end justify-between gap-2">
							<div class="h-12 w-full rounded-t bg-paper-accent/20"></div>
							<div class="h-20 w-full rounded-t bg-paper-accent/30"></div>
							<div class="h-16 w-full rounded-t bg-paper-accent-light/25"></div>
							<div class="h-24 w-full rounded-t bg-paper-accent-light/40"></div>
							<div class="h-14 w-full rounded-t bg-paper-accent-pink/20"></div>
						</div>
					</div>
				</div>
			</div>

			<!-- Small card - Distraction Free -->
			<div
				class="feature-card lg:col-span-1 lg:row-span-1 {visible_cards.has('distraction-free')
					? 'animate-scale-in'
					: 'opacity-0'}"
				data-card-id="distraction-free"
				style:animation-delay="0.2s"
			>
				<div
					class="glass group relative h-full overflow-hidden rounded-2xl p-6 shadow-sm sm:rounded-3xl sm:p-8"
				>
					<div class="mb-6">
						<div
							class="mb-4 flex w-full items-center gap-3 rounded-xl bg-linear-to-br from-paper-accent/10 to-paper-accent-light/10 p-3"
						>
							<svg
								class="h-5 w-5 shrink-0 text-paper-accent sm:h-6 sm:w-6"
								fill="none"
								stroke="currentColor"
								stroke-width="1.5"
								viewBox="0 0 24 24"
							>
								<path stroke-linecap="round" stroke-linejoin="round" d="M12 20l9-11h-6V4l-9 11h6v5z"
								></path>
							</svg>
							<h3 class="font-serif text-lg text-paper-text sm:text-xl">Distraction Free</h3>
						</div>
						<p class="text-sm text-paper-text-light">Focus on your words, nothing else</p>
					</div>

					<div class="mt-auto">
						<div class="rounded-lg bg-paper-gray/50 p-4">
							<div class="space-y-3">
								<div class="space-y-2">
									<div class="h-1.5 w-3/4 rounded-full bg-paper-text/5"></div>
									<div class="h-1.5 w-4/5 rounded-full bg-paper-text/5"></div>
								</div>
								<div class="space-y-2">
									<div class="h-1.5 w-2/3 rounded-full bg-paper-text/5"></div>
									<div class="h-1.5 w-full rounded-full bg-paper-text/5"></div>
								</div>
								<div class="space-y-2">
									<div class="h-1.5 w-full rounded-full bg-paper-text/10"></div>
									<div class="h-1.5 w-5/6 rounded-full bg-paper-text/10"></div>
								</div>
								<div class="space-y-2">
									<div class="h-1.5 w-3/4 rounded-full bg-paper-text/10"></div>
									<div class="h-1.5 w-4/5 rounded-full bg-paper-text/10"></div>
								</div>
								<div class="space-y-2">
									<div class="h-1.5 w-5/6 rounded-full bg-paper-text/5"></div>
									<div class="h-1.5 w-2/3 rounded-full bg-paper-text/5"></div>
								</div>
								<div class="space-y-2">
									<div class="h-1.5 w-3/4 rounded-full bg-paper-text/5"></div>
									<div class="h-1.5 w-1/2 rounded-full bg-paper-text/5"></div>
								</div>
							</div>
						</div>
					</div>
				</div>
			</div>

			<!-- Small card - Project Notes -->
			<div
				class="feature-card lg:col-span-1 lg:row-span-1 {visible_cards.has('notes')
					? 'animate-scale-in'
					: 'opacity-0'}"
				data-card-id="notes"
				style:animation-delay="0.25s"
			>
				<div
					class="glass group relative h-full overflow-hidden rounded-2xl p-6 shadow-sm sm:rounded-3xl sm:p-8"
				>
					<div class="flex flex-col gap-6">
						<div
							class="mb-4 flex w-full items-center gap-3 rounded-xl bg-linear-to-br from-paper-accent/10 to-paper-accent-light/10 p-3"
						>
							<svg
								class="h-5 w-5 shrink-0 text-paper-accent sm:h-6 sm:w-6"
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
							<h3 class="font-serif text-lg text-paper-text sm:text-xl">Project Notes</h3>
						</div>
						<p class="mb-4 text-sm text-paper-text-light">Keep your story details organized</p>

						<!-- Notes visualization -->
						<div class="mt-auto grid grid-cols-2 gap-2">
							<div class="flex flex-col justify-between rounded-lg bg-paper-accent/10 p-2">
								<div class="space-y-1">
									<div class="h-1 w-full rounded-full bg-paper-accent/30"></div>
									<div class="h-1 w-3/4 rounded-full bg-paper-accent/20"></div>
								</div>
								<div class="mt-2 text-xs font-medium text-paper-accent">Characters</div>
							</div>
							<div class="flex flex-col justify-between rounded-lg bg-paper-accent-light/10 p-2">
								<div class="space-y-1">
									<div class="h-1 w-full rounded-full bg-paper-accent-light/30"></div>
									<div class="h-1 w-2/3 rounded-full bg-paper-accent-light/20"></div>
								</div>
								<div class="mt-2 text-xs font-medium text-paper-accent-light">Plot</div>
							</div>
							<div class="flex flex-col justify-between rounded-lg bg-paper-accent-pink/10 p-2">
								<div class="space-y-1">
									<div class="h-1 w-full rounded-full bg-paper-accent-pink/30"></div>
									<div class="h-1 w-5/6 rounded-full bg-paper-accent-pink/20"></div>
								</div>
								<div class="mt-2 text-xs font-medium text-paper-accent-pink">Research</div>
							</div>
							<div class="flex flex-col justify-between rounded-lg bg-paper-accent/10 p-2">
								<div class="space-y-1">
									<div class="h-1 w-full rounded-full bg-paper-accent/30"></div>
									<div class="h-1 w-1/2 rounded-full bg-paper-accent/20"></div>
								</div>
								<div class="mt-2 text-xs font-medium text-paper-accent">Timeline</div>
							</div>
						</div>
					</div>
				</div>
			</div>

			<!-- Small card - Export Options -->
			<div
				class="feature-card lg:col-span-1 lg:row-span-1 {visible_cards.has('export')
					? 'animate-scale-in'
					: 'opacity-0'}"
				data-card-id="export"
				style:animation-delay="0.3s"
			>
				<div
					class="glass group relative h-full overflow-hidden rounded-2xl p-6 shadow-sm sm:rounded-3xl sm:p-8"
				>
					<div>
						<div
							class="mb-4 flex w-full items-center gap-3 rounded-xl bg-linear-to-br from-paper-accent/10 to-paper-accent-pink/10 p-3"
						>
							<svg
								class="h-5 w-5 shrink-0 text-paper-accent sm:h-6 sm:w-6"
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
							<h3 class="font-serif text-lg text-paper-text sm:text-xl">Export Anywhere</h3>
						</div>
						<p class="mb-6 text-sm text-paper-text-light sm:text-base">
							Professional formats for every need
						</p>
					</div>

					<!-- Export format cards -->
					<div class="flex flex-col gap-2">
						<div class="flex items-center gap-3 rounded-lg bg-paper-gray/50 p-3 shadow-sm">
							<div class="flex h-10 w-10 items-center justify-center rounded bg-white shadow-sm">
								<span class="text-xs font-bold text-paper-text-muted">EPUB</span>
							</div>
							<span class="text-sm text-paper-text-light">E-book format</span>
						</div>
						<div class="flex items-center gap-3 rounded-lg bg-paper-accent/5 p-3 shadow-sm">
							<div class="flex h-10 w-10 items-center justify-center rounded bg-white shadow-sm">
								<span class="text-xs font-bold text-paper-accent">PDF</span>
							</div>
							<span class="text-sm text-paper-text-light">Print ready</span>
						</div>
						<div class="flex items-center gap-3 rounded-lg bg-paper-accent-light/5 p-3 shadow-sm">
							<div class="flex h-10 w-10 items-center justify-center rounded bg-white shadow-sm">
								<span class="text-xs font-bold text-paper-accent-light">RTF</span>
							</div>
							<span class="text-sm text-paper-text-light">Universal format</span>
						</div>
					</div>
				</div>
			</div>
		</div>
	</div>
</section>
