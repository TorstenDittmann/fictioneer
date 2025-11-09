<script lang="ts">
	import { resolve } from '$app/paths';
	import logo from '$lib/assets/logo.svg';

	function scrollToNewsletter() {
		document.getElementById('newsletter')?.scrollIntoView({ behavior: 'smooth' });
	}
</script>

<section
	class="relative flex min-h-screen items-center justify-center overflow-hidden px-4 py-16 sm:py-20"
>
	<!-- Gradient background -->
	<div
		class="absolute inset-0 bg-linear-to-br from-paper-beige via-paper-cream/50 to-paper-white/30"
	></div>

	<!-- Radial gradient overlay -->
	<div class="absolute inset-0" style="background: var(--gradient-radial)"></div>

	<div class="relative z-10 mx-auto max-w-6xl text-center">
		<!-- Logo with spin animation -->
		<div class="animate-fade-in-down mb-4 flex justify-center sm:mb-6">
			<div class="relative">
				<img
					src={logo}
					alt="Fictioneer"
					class="animate-rotate-slow relative h-16 w-16 sm:h-20 sm:w-20 md:h-24 md:w-24"
				/>
			</div>
		</div>

		<!-- Main headline -->
		<h1
			class="animate-fade-in-up mb-6 font-serif text-4xl leading-[0.9] tracking-tight sm:text-5xl md:text-7xl lg:text-8xl"
			style="animation-delay: 0.2s"
		>
			<span class="block text-paper-text">Where Stories</span>
			<span class="gradient-text mt-1 block text-5xl sm:mt-2 sm:text-6xl md:text-8xl lg:text-9xl"
				>Come to Life</span
			>
		</h1>

		<!-- Tagline -->
		<p
			class="animate-fade-in-up mx-auto mb-10 max-w-3xl text-base leading-relaxed text-paper-text-light/90 sm:mb-12 sm:text-lg md:text-xl lg:text-2xl"
			style="animation-delay: 0.3s"
		>
			The writing environment designed for novelists who demand focus, flow, and creative freedom.
		</p>

		<!-- CTA Buttons -->
		<div
			class="animate-fade-in-up flex flex-wrap items-center justify-center gap-4"
			style:animation-delay="0.4s"
		>
			<a href={resolve('/download')} class="btn-primary hover-lift group">
				<span class="flex items-center gap-2 text-sm sm:text-base">
					Download Free
					<svg
						class="h-4 w-4 transition-transform group-hover:translate-x-1 sm:h-5 sm:w-5"
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
			<button
				onclick={scrollToNewsletter}
				class="group rounded-lg border-2 border-paper-accent px-6 py-3 font-medium text-paper-accent transition-all hover:bg-paper-accent/10 sm:px-8 sm:py-4"
			>
				<span class="flex items-center gap-2 text-sm sm:text-base"> Stay Updated </span>
			</button>
		</div>

		<!-- Stats -->
		<div
			class="animate-fade-in-up mx-auto mt-16 grid max-w-2xl grid-cols-3 gap-4 sm:mt-20 sm:gap-8"
			style="animation-delay: 0.5s"
		>
			<div class="text-center">
				<div class="gradient-text text-2xl font-bold sm:text-3xl md:text-4xl">Free</div>
				<div class="mt-1 text-xs text-paper-text-muted sm:text-sm">Forever</div>
			</div>
			<div class="text-center">
				<div class="gradient-text text-2xl font-bold sm:text-3xl md:text-4xl">100%</div>
				<div class="mt-1 text-xs text-paper-text-muted sm:text-sm">Privacy First</div>
			</div>
			<div class="text-center">
				<div class="gradient-text text-2xl font-bold sm:text-3xl md:text-4xl">Zero</div>
				<div class="mt-1 text-xs text-paper-text-muted sm:text-sm">Distractions</div>
			</div>
		</div>

		<!-- Scroll indicator -->
		<div class="animate-fade-in mt-16 sm:mt-20" style="animation-delay: 0.6s">
			<div class="flex flex-col items-center gap-2 text-paper-text-muted">
				<span class="text-xs tracking-widest uppercase">Scroll</span>
				<svg
					class="h-4 w-4 animate-bounce sm:h-5 sm:w-5"
					fill="none"
					stroke="currentColor"
					viewBox="0 0 24 24"
				>
					<path
						stroke-linecap="round"
						stroke-linejoin="round"
						stroke-width="2"
						d="M19 14l-7 7m0 0l-7-7m7 7V3"
					></path>
				</svg>
			</div>
		</div>
	</div>
</section>
