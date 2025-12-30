<script lang="ts">
	import { onMount } from 'svelte';
	import { resolve } from '$app/paths';

	let mounted = $state(false);

	onMount(() => {
		mounted = true;
	});
</script>

<section class="relative overflow-hidden px-4 py-24 sm:py-32 lg:py-40">
	<div class="relative z-10 mx-auto max-w-4xl">
		<!-- Card -->
		<div class="card-elevated relative overflow-hidden p-8 text-center sm:p-12 lg:p-16">
			<!-- Decorative gradient -->
			<div
				class="absolute inset-0 bg-gradient-to-br from-paper-accent/5 via-transparent to-paper-iris/5"
			></div>

			<div class="relative">
				<!-- Badge -->
				<div class="pill mx-auto mb-6 w-max">
					<span class="h-1.5 w-1.5 rounded-full bg-paper-lime"></span>
					Ready when inspiration strikes
				</div>

				<!-- Headline -->
				<h2
					class="mb-4 font-serif text-3xl tracking-tight text-paper-text sm:text-4xl lg:text-5xl {mounted
						? 'animate-fade-in-up'
						: 'opacity-0'}"
				>
					Start writing your <span class="gradient-text">masterpiece</span>
				</h2>

				<!-- Description -->
				<p
					class="mx-auto mb-10 max-w-xl text-lg text-paper-text-light {mounted
						? 'animate-fade-in-up'
						: 'opacity-0'}"
					style:animation-delay="0.1s"
				>
					Download Fictioneer today and experience the writing software you've been searching for.
				</p>

				<!-- CTA Buttons -->
				<div
					class="flex flex-col items-center justify-center gap-3 sm:flex-row sm:gap-4 {mounted
						? 'animate-fade-in-up'
						: 'opacity-0'}"
					style:animation-delay="0.2s"
				>
					<a href={resolve('/download')} class="btn-primary w-full sm:w-auto">
						<span class="flex items-center justify-center gap-2">
							Download Free
							<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
								<path
									stroke-linecap="round"
									stroke-linejoin="round"
									stroke-width="2"
									d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"
								></path>
							</svg>
						</span>
					</a>

					<a href="#newsletter" class="btn-ghost w-full sm:w-auto">
						<span class="flex items-center justify-center gap-2">
							Stay Updated
							<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
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
			</div>
		</div>
	</div>
</section>
