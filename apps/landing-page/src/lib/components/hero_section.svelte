<script lang="ts">
	import { resolve } from '$app/paths';
	import logo from '$lib/assets/logo.svg';
</script>

<section class="relative overflow-hidden px-4 py-24 sm:py-32 lg:py-40">
	<!-- Radial gradient overlay -->
	<div class="absolute inset-0" style:background="var(--gradient-radial)"></div>

	<div class="relative z-10 mx-auto max-w-5xl text-center">
		<!-- Logo -->
		<div class="animate-fade-in-down mb-8 flex justify-center">
			<img src={logo} alt="Fictioneer" class="h-16 w-16 sm:h-20 sm:w-20" />
		</div>

		<!-- Main headline -->
		<h1
			class="animate-fade-in-up mb-6 font-serif text-5xl leading-tight tracking-tight text-paper-text sm:text-6xl lg:text-7xl xl:text-8xl"
			style:animation-delay="0.1s"
		>
			Where Stories<br />
			<span class="gradient-text">Come to Life</span>
		</h1>

		<!-- Subheadline -->
		<p
			class="animate-fade-in-up mx-auto mb-12 max-w-2xl text-lg leading-relaxed text-paper-text-light sm:text-xl lg:text-2xl"
			style:animation-delay="0.2s"
		>
			Distraction-free writing software designed for novelists. Available for Windows, Mac, and
			Linux.
		</p>

		<!-- CTA Buttons -->
		<div
			class="animate-fade-in-up mb-16 flex flex-col items-center justify-center gap-4 sm:flex-row"
			style:animation-delay="0.3s"
		>
			<a href={resolve('/download')} class="btn-primary w-full sm:w-auto">
				<span class="flex items-center justify-center gap-2 text-base sm:text-lg">
					Download Free
					<svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
						<path
							stroke-linecap="round"
							stroke-linejoin="round"
							stroke-width="2"
							d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"
						></path>
					</svg>
				</span>
			</a>
		</div>

		<!-- Hero image/screenshot placeholder -->
		<div class="animate-scale-in relative mx-auto max-w-5xl" style:animation-delay="0.4s">
			<div
				class="glass relative overflow-hidden rounded-2xl border border-paper-border p-2 sm:rounded-3xl sm:p-3"
			>
				<!-- Screenshot placeholder -->
				<div
					class="relative aspect-16/10 w-full overflow-hidden rounded-xl bg-paper-gray sm:rounded-2xl"
				>
					<!-- Gradient overlay -->
					<div
						class="absolute inset-0 bg-linear-to-br from-paper-accent/5 via-transparent to-paper-accent-light/5"
					></div>

					<!-- Mock editor content -->
					<div class="relative flex h-full items-center justify-center p-8 sm:p-12 lg:p-16">
						<div class="w-full max-w-2xl space-y-4 text-left">
							<div class="h-3 w-3/4 rounded-full bg-paper-text/10"></div>
							<div class="h-3 w-full rounded-full bg-paper-text/10"></div>
							<div class="h-3 w-5/6 rounded-full bg-paper-text/10"></div>
							<div class="h-3 w-4/5 rounded-full bg-paper-text/10"></div>
							<div class="mt-6 h-3 w-2/3 rounded-full bg-paper-text/10"></div>
							<div class="h-3 w-full rounded-full bg-paper-text/10"></div>
							<div class="h-3 w-3/4 rounded-full bg-paper-text/10"></div>
						</div>
					</div>

					<!-- Floating element -->
					<div
						class="absolute top-8 right-8 rounded-lg bg-white/80 px-4 py-2 shadow-lg backdrop-blur-sm"
					>
						<span class="text-xs text-paper-text-muted">Screenshot placeholder</span>
					</div>
				</div>
			</div>

			<!-- Glow effect -->
			<div
				class="absolute -inset-4 -z-10 bg-linear-to-t from-paper-accent/10 via-transparent to-transparent opacity-50 blur-3xl"
			></div>
		</div>
	</div>
</section>
