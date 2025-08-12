<script lang="ts">
	import logo from '$lib/assets/logo.svg';

	function scrollToWaitlist() {
		document.getElementById('waitlist')?.scrollIntoView({ behavior: 'smooth' });
	}
</script>

<section
	class="relative flex min-h-screen items-center justify-center overflow-hidden px-4 py-16 sm:py-20"
>
	<!-- Gradient background -->
	<div
		class="absolute inset-0 bg-gradient-to-br from-paper-beige via-paper-cream/50 to-paper-white/30"
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

		<!-- App name -->
		<div class="animate-fade-in mb-6 sm:mb-8" style="animation-delay: 0.05s">
			<h2
				class="font-serif text-3xl tracking-wide text-paper-accent sm:text-4xl md:text-5xl lg:text-6xl"
			>
				Fictioneer
			</h2>
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

		<!-- CTA Button -->
		<div class="animate-fade-in-up flex items-center justify-center" style="animation-delay: 0.4s">
			<button onclick={scrollToWaitlist} class="btn-primary hover-lift group">
				<span class="flex items-center gap-2 text-sm sm:text-base">
					Join the Waitlist
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
							d="M13 7l5 5m0 0l-5 5m5-5H6"
						></path>
					</svg>
				</span>
			</button>
		</div>

		<!-- Stats -->
		<div
			class="animate-fade-in-up mx-auto mt-16 grid max-w-2xl grid-cols-3 gap-4 sm:mt-20 sm:gap-8"
			style="animation-delay: 0.5s"
		>
			<div class="text-center">
				<div class="gradient-text text-2xl font-bold sm:text-3xl md:text-4xl">Early</div>
				<div class="mt-1 text-xs text-paper-text-muted sm:text-sm">Access</div>
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
