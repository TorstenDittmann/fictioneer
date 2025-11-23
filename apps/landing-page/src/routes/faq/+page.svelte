<script lang="ts">
	import { resolve } from '$app/paths';
	import FaqSection from '$lib/components/faq_section.svelte';
</script>

<svelte:head>
	<title>FAQ - Fictioneer</title>
	<meta
		name="description"
		content="Get answers to the most common questions about Fictioneer, pricing, refunds, and billing."
	/>
</svelte:head>

<div class="min-h-screen bg-paper-beige pt-16 pb-20">
	<div class="mx-auto max-w-6xl px-6">
		<FaqSection
			intro="These are the same questions we hear when writers explore Fictioneer and the AI Tools subscription."
		/>

		<div
			class="animate-fade-in-up mx-auto mt-16 max-w-4xl rounded-2xl border border-paper-accent/40 bg-paper-cream/60 p-8 text-center shadow-lg"
			style:animation-delay="0.6s"
		>
			<h2 class="mb-3 text-2xl font-bold text-paper-text">Still need help?</h2>
			<p class="mb-6 text-paper-text-light">
				Reach out and we'll point you in the right direction. We read every message.
			</p>
			<div class="flex flex-wrap justify-center gap-3">
				<a
					href="mailto:hello@fictioneer.app"
					class="inline-flex items-center gap-2 rounded-lg border border-paper-border px-6 py-3 text-sm font-medium text-paper-text hover:bg-paper-gray/40"
				>
					Email support
				</a>
				<a
					href={resolve('/pricing')}
					class="inline-flex items-center gap-2 rounded-lg bg-paper-accent px-6 py-3 text-sm font-semibold text-paper-beige hover:bg-paper-accent-light"
				>
					Pricing overview
				</a>
			</div>
		</div>
	</div>
</div>
