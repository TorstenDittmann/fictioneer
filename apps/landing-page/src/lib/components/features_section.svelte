<script lang="ts">
	import { onMount } from 'svelte';
	import { SvelteSet } from 'svelte/reactivity';

	let mounted = $state(false);
	let visible_features = $state(new Set());
	let ai_current_text = $state('');
	let ai_completion_index = $state(0);
	let ai_typing = $state(false);

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

		// Intersection observer for feature animations
		const observer = new IntersectionObserver(
			(entries) => {
				entries.forEach((entry) => {
					if (entry.isIntersecting) {
						visible_features.add(entry.target.id);
						visible_features = new SvelteSet(visible_features);

						// Start AI typing animation when visible
						if (entry.target.id === 'ai-assistant' && !ai_typing) {
							startAiTyping();
						}
					}
				});
			},
			{ threshold: 0.2, rootMargin: '0px 0px -100px 0px' }
		);

		document.querySelectorAll('.feature-item').forEach((el) => {
			observer.observe(el);
		});

		return () => observer.disconnect();
	});

	function startAiTyping() {
		ai_typing = true;
		typewriterEffect();
	}

	async function typewriterEffect() {
		while (ai_typing) {
			// Reset to base text
			ai_current_text = '';
			await sleep(300);

			// Type out the completion
			const completion = ai_completions[ai_completion_index];
			for (let i = 0; i <= completion.length; i++) {
				ai_current_text = completion.substring(0, i);
				await sleep(25);
			}

			// Pause to show complete text
			await sleep(1500);

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

	const features = [
		{
			id: 'distraction-free',
			title: 'Distraction Free Writing',
			description:
				'A pristine canvas for your words. Our minimalist interface melts away, leaving only you and your story in perfect harmony.',
			icon: 'M12 20l9-11h-6V4l-9 11h6v5z',
			gradient: 'from-paper-accent/20 to-paper-accent-light/20'
		},
		{
			id: 'ai-assistant',
			title: 'AI Writing Companion',
			description:
				'Break through creative barriers with an AI that understands context and respects your unique voice. Never face a blank page alone.',
			icon: 'M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z',
			gradient: 'from-paper-accent/20 to-paper-accent-light/20'
		},
		{
			id: 'progress-tracking',
			title: 'Progress Analytics',
			description:
				'Track your journey with beautiful visualizations. Word counts, writing streaks, and milestone celebrations.',
			icon: 'M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z',
			gradient: 'from-paper-accent-light/20 to-paper-accent/20'
		},
		{
			id: 'seamless-export',
			title: 'Professional Export',
			description:
				'One click to manuscript ready formats. Export to EPUB, RTF, or PDF with industry standard formatting.',
			icon: 'M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z',
			gradient: 'from-paper-accent-light/20 to-paper-accent/20'
		}
	];
</script>

<section id="features" class="relative overflow-hidden py-20 sm:py-32">
	<!-- Background gradient -->
	<div
		class="absolute inset-0 bg-gradient-to-b from-paper-white/20 via-paper-cream/30 to-paper-white/20"
	></div>

	<!-- Decorative elements -->
	<div
		class="absolute top-0 left-0 h-px w-full bg-gradient-to-r from-transparent via-paper-border/50 to-transparent"
	></div>
	<div
		class="absolute bottom-0 left-0 h-px w-full bg-gradient-to-r from-transparent via-paper-border/50 to-transparent"
	></div>

	<!-- Full width on mobile, constrained on desktop -->
	<div class="relative px-4 lg:mx-auto lg:max-w-7xl lg:px-8">
		<!-- Section header -->
		<div class="mb-16 text-center sm:mb-20">
			<h2
				class="mb-4 font-serif text-3xl text-paper-text sm:mb-6 sm:text-4xl md:text-6xl {mounted
					? 'animate-fade-in-up'
					: 'opacity-0'}"
			>
				Crafted for <span class="gradient-text">Storytellers</span>
			</h2>
			<p
				class="mx-auto max-w-3xl text-lg text-paper-text-light sm:text-xl {mounted
					? 'animate-fade-in-up'
					: 'opacity-0'}"
				style="animation-delay: 0.2s"
			>
				Every pixel, every interaction, every feature meticulously designed to amplify your creative
				flow
			</p>
		</div>

		<!-- Features list - full width on mobile -->
		<div class="space-y-16 sm:space-y-24">
			{#each features as feature, i (feature.id)}
				<div id={feature.id} class="feature-item group relative">
					<!-- Full width mobile layout, alternating desktop layout -->
					<div
						class="flex flex-col gap-8 sm:gap-12 lg:items-center {i % 2 === 0
							? 'lg:flex-row'
							: 'lg:flex-row-reverse'} lg:gap-20"
					>
						<!-- Content - full width on mobile -->
						<div
							class="w-full text-center lg:flex-1 lg:text-left {visible_features.has(feature.id)
								? i % 2 === 0
									? 'animate-slide-in-left'
									: 'animate-slide-in-right'
								: 'opacity-0'}"
						>
							<div
								class="mb-4 inline-flex h-12 w-12 items-center justify-center rounded-xl bg-gradient-to-br {feature.gradient} border border-paper-border/20 backdrop-blur-sm sm:mb-6 sm:h-16 sm:w-16 sm:rounded-2xl"
							>
								<svg
									class="h-6 w-6 text-paper-accent sm:h-8 sm:w-8"
									fill="none"
									stroke="currentColor"
									stroke-width="1.5"
									viewBox="0 0 24 24"
								>
									<path stroke-linecap="round" stroke-linejoin="round" d={feature.icon}></path>
								</svg>
							</div>

							<h3 class="mb-3 font-serif text-2xl text-paper-text sm:mb-4 sm:text-3xl md:text-4xl">
								{feature.title}
							</h3>

							<p
								class="mx-auto max-w-2xl text-base leading-relaxed text-paper-text-light sm:text-lg md:text-xl lg:mx-0"
							>
								{feature.description}
							</p>
						</div>

						<!-- Visual placeholder - full width on mobile -->
						<div
							class="w-full lg:flex-1 {visible_features.has(feature.id)
								? 'animate-scale-in'
								: 'opacity-0'}"
							style="animation-delay: 0.1s"
						>
							<div class="relative mx-auto aspect-[4/3] max-w-full sm:max-w-md lg:max-w-lg">
								<!-- Glass card -->
								<div
									class="glass relative flex h-full items-center justify-center overflow-hidden rounded-2xl p-6 sm:rounded-3xl sm:p-8"
								>
									<!-- Animated gradient background -->
									<div
										class="absolute inset-0 bg-gradient-to-br {feature.gradient} opacity-30"
									></div>

									<!-- Feature visualization -->
									<div class="relative z-10 flex h-full w-full items-center justify-center">
										{#if feature.id === 'distraction-free'}
											<!-- Minimalist editor visualization -->
											<div class="w-full space-y-2 sm:space-y-3">
												{#each [0.75, 1, 0.85, 0.65] as width, idx (width)}
													<div
														class="h-1.5 rounded-full bg-paper-text/20 transition-all duration-700 sm:h-2 {visible_features.has(
															feature.id
														)
															? ''
															: 'scale-x-0'}"
														style="width: {width * 100}%; animation-delay: {0.3 +
															idx * 0.1}s; transform-origin: left"
													></div>
												{/each}
											</div>
										{:else if feature.id === 'ai-assistant'}
											<!-- AI typewriter effect with fixed positioning -->
											<div class="flex h-full w-full items-center">
												<div class="w-full px-2 sm:px-4">
													<div
														class="min-h-[2.5rem] text-left font-mono text-xs leading-relaxed sm:min-h-[3rem] sm:text-sm"
													>
														<span class="text-paper-text">{ai_base_text}</span>
														<span class="text-paper-accent">{ai_current_text}</span>
														<span
															class="ml-0.5 inline-block h-3 w-0.5 animate-pulse bg-paper-accent align-middle sm:h-4"
														></span>
													</div>
												</div>
											</div>
										{:else if feature.id === 'progress-tracking'}
											<!-- Stats visualization -->
											<div class="w-full space-y-3 sm:space-y-4">
												<div class="flex items-end justify-between gap-1 sm:gap-2">
													{#each [16, 24, 20, 28, 18] as height, idx (height)}
														<div
															class="w-1/5 rounded-t bg-paper-accent/40 transition-all duration-700 {visible_features.has(
																feature.id
															)
																? ''
																: 'scale-y-0'}"
															style="height: {height * 2.5}px; animation-delay: {0.3 +
																idx * 0.1}s; transform-origin: bottom"
														></div>
													{/each}
												</div>
												<div class="h-px w-full bg-paper-text/20"></div>
											</div>
										{:else if feature.id === 'seamless-export'}
											<!-- Export visualization - horizontal layout -->
											<div class="flex w-full items-center justify-center gap-4 sm:gap-6">
												<!-- EPUB -->
												<div
													class="flex h-14 w-10 items-center justify-center rounded bg-paper-text/20 sm:h-20 sm:w-16 {visible_features.has(
														feature.id
													)
														? 'animate-scale-in'
														: 'opacity-0'}"
													style="animation-delay: 0.2s"
												>
													<span class="text-xs text-paper-text/50">EPUB</span>
												</div>

												<!-- RTF -->
												<div
													class="flex h-14 w-10 items-center justify-center rounded bg-paper-accent/20 sm:h-20 sm:w-16 {visible_features.has(
														feature.id
													)
														? 'animate-scale-in'
														: 'opacity-0'}"
													style="animation-delay: 0.4s"
												>
													<span class="text-xs text-paper-text/70">RTF</span>
												</div>

												<!-- PDF -->
												<div
													class="flex h-14 w-10 items-center justify-center rounded bg-paper-accent/30 sm:h-20 sm:w-16 {visible_features.has(
														feature.id
													)
														? 'animate-scale-in'
														: 'opacity-0'}"
													style="animation-delay: 0.6s"
												>
													<span class="text-xs text-paper-text/90">PDF</span>
												</div>
											</div>
										{/if}
									</div>
								</div>
							</div>
						</div>
					</div>

					{#if i < features.length - 1}
						<!-- Separator -->
						<div class="mt-16 flex justify-center sm:mt-24">
							<div
								class="h-12 w-px bg-gradient-to-b from-transparent via-paper-border/30 to-transparent sm:h-16"
							></div>
						</div>
					{/if}
				</div>
			{/each}
		</div>
	</div>
</section>
