<script lang="ts">
	import { resolve } from '$app/paths';
</script>

<svelte:head>
	<title>Contact - Fictioneer</title>
	<meta
		name="description"
		content="Get in touch with the Fictioneer team. Send feedback, report bugs, or request features."
	/>
</svelte:head>

<div class="mx-auto max-w-3xl px-4 py-16 sm:px-6 lg:py-24">
	<!-- Hero -->
	<div class="mb-12 text-center">
		<div class="pill animate-fade-in mx-auto mb-6 w-max">
			<span class="h-1.5 w-1.5 rounded-full bg-paper-accent"></span>
			Support
		</div>
		<h1 class="animate-fade-in-up font-serif text-4xl font-bold text-paper-text">Contact Us</h1>
		<p class="animate-fade-in-up mt-4 text-paper-text-light" style:animation-delay="0.1s">
			We'd love to hear from you
		</p>
	</div>

	<!-- Content -->
	<div class="prose prose-paper animate-fade-in-up" style:animation-delay="0.2s">
		<div class="card-elevated space-y-8 p-8">
			<section class="text-center">
				<p class="text-paper-text-light">
					Have feedback, found a bug, or want to request a feature? Send us an email and we'll get
					back to you as soon as possible.
				</p>

				<a
					href="mailto:support@fictioneer.app"
					class="mt-6 inline-flex items-center gap-3 rounded-xl border border-paper-accent/20 bg-paper-accent/5 px-8 py-4 text-xl font-medium text-paper-accent transition-all hover:border-paper-accent/40 hover:bg-paper-accent/10"
				>
					<svg
						width="24"
						height="24"
						viewBox="0 0 24 24"
						fill="none"
						stroke="currentColor"
						stroke-width="2"
					>
						<rect width="20" height="16" x="2" y="4" rx="2" />
						<path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7" />
					</svg>
					support@fictioneer.app
				</a>
			</section>
		</div>
	</div>

	<!-- Back Link -->
	<div class="mt-8 text-center">
		<a href={resolve('/')} class="btn-ghost">Back to home</a>
	</div>
</div>
