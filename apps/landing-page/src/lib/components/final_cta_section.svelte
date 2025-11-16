<script lang="ts">
	import { onMount } from 'svelte';
	import { resolve } from '$app/paths';

	let mounted = $state(false);

	onMount(() => {
		mounted = true;
	});
</script>

<section class="relative overflow-hidden px-4 py-24 sm:py-32 lg:py-40">
	<!-- Background with gradient -->
	<div class="absolute inset-0 bg-linear-to-b from-white via-paper-gray/20 to-white"></div>

	<!-- Radial gradient overlay -->
	<div class="absolute inset-0" style:background="var(--gradient-radial)"></div>

	<div class="relative z-10 mx-auto max-w-4xl text-center">
		<h2
			class="mb-6 font-serif text-4xl text-paper-text sm:text-5xl lg:text-6xl xl:text-7xl {mounted
				? 'animate-fade-in-up'
				: 'opacity-0'}"
		>
			Start writing your
			<span class="gradient-text">masterpiece</span>
		</h2>

		<p
			class="mx-auto mb-12 max-w-2xl text-lg text-paper-text-light sm:text-xl lg:text-2xl {mounted
				? 'animate-fade-in-up'
				: 'opacity-0'}"
			style:animation-delay="0.1s"
		>
			Download Fictioneer today and experience the writing software you've been searching for.
			Available for Windows, Mac, and Linux. Free forever, no strings attached.
		</p>

		<!-- CTA buttons -->
		<div
			class="flex flex-col items-center justify-center gap-4 sm:flex-row {mounted
				? 'animate-fade-in-up'
				: 'opacity-0'}"
			style:animation-delay="0.2s"
		>
			<a href={resolve('/download')} class="btn-primary hover-lift group w-full sm:w-auto">
				<span class="flex items-center justify-center gap-2 text-base sm:text-lg">
					Download Free
					<svg
						class="h-5 w-5 transition-transform group-hover:translate-y-1"
						fill="none"
						stroke="currentColor"
						viewBox="0 0 24 24"
					>
						<path
							stroke-linecap="round"
							stroke-linejoin="round"
							stroke-width="2"
							d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"
						></path>
					</svg>
				</span>
			</a>

			<a
				href="#newsletter"
				class="group w-full rounded-lg border-2 border-paper-accent bg-white px-8 py-3 font-medium text-paper-accent shadow-sm transition-all hover:bg-paper-accent/5 sm:w-auto"
			>
				<span class="flex items-center justify-center gap-2 text-base sm:text-lg">
					Stay Updated
					<svg
						class="h-5 w-5 transition-transform group-hover:translate-x-1"
						fill="none"
						stroke="currentColor"
						viewBox="0 0 24 24"
					>
						<path
							stroke-linecap="round"
							stroke-linejoin="round"
							stroke-width="2"
							d="M13 7l5 5m0 0l-5 5m5-5H6"
						></path>
					</svg>
				</span>
			</a>
		</div>

		<!-- Trust indicators -->
		<div
			class="mt-16 flex flex-wrap items-center justify-center gap-6 text-sm text-paper-text-muted sm:gap-8 {mounted
				? 'animate-fade-in'
				: 'opacity-0'}"
			style:animation-delay="0.3s"
		>
			<div class="flex items-center gap-2">
				<svg class="h-5 w-5 text-paper-accent" fill="currentColor" viewBox="0 0 20 20">
					<path
						fill-rule="evenodd"
						d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
						clip-rule="evenodd"
					></path>
				</svg>
				<span>No credit card required</span>
			</div>

			<div class="flex items-center gap-2">
				<svg class="h-5 w-5 text-paper-accent" fill="currentColor" viewBox="0 0 20 20">
					<path
						fill-rule="evenodd"
						d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
						clip-rule="evenodd"
					></path>
				</svg>
				<span>Free forever</span>
			</div>

			<div class="flex items-center gap-2">
				<svg class="h-5 w-5 text-paper-accent" fill="currentColor" viewBox="0 0 20 20">
					<path
						fill-rule="evenodd"
						d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
						clip-rule="evenodd"
					></path>
				</svg>
				<span>100% private</span>
			</div>
		</div>
	</div>
</section>
