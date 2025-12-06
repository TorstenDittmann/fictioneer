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

<div class="relative min-h-screen overflow-hidden">
	<!-- Background -->
	<div class="absolute inset-0" style:background="var(--gradient-mesh)"></div>
	<div
		class="aurora-blob-subtle top-[10%] left-[10%] h-[350px] w-[350px] rounded-full bg-paper-accent/15"
	></div>
	<div
		class="aurora-blob-subtle right-[15%] bottom-[20%] h-[400px] w-[400px] rounded-full bg-paper-iris/10"
	></div>

	<div class="relative z-10 mx-auto max-w-4xl px-4 py-16 sm:px-6 lg:py-24">
		<!-- Hero -->
		<div class="mb-12 text-center">
			<div class="pill animate-fade-in mx-auto mb-6 w-max">
				<span class="h-1.5 w-1.5 rounded-full bg-paper-accent"></span>
				Help center
			</div>
		</div>

		<!-- FAQ Section -->
		<FaqSection intro="Common questions about Fictioneer and the AI Tools subscription." />

		<!-- Contact CTA -->
		<div class="animate-fade-in-up mx-auto mt-16 max-w-xl text-center" style:animation-delay="0.5s">
			<div class="card-elevated overflow-hidden p-8">
				<div
					class="absolute inset-0 bg-gradient-to-br from-paper-accent/5 via-transparent to-paper-iris/5"
				></div>
				<div class="relative">
					<h2 class="mb-3 font-serif text-xl font-semibold text-paper-text">Still need help?</h2>
					<p class="mb-6 text-paper-text-light">
						Reach out and we'll point you in the right direction.
					</p>
					<div class="flex flex-wrap justify-center gap-3">
						<a href="mailto:hello@fictioneer.app" class="btn-ghost"> Email support </a>
						<a href={resolve('/pricing')} class="btn-primary"> View pricing </a>
					</div>
				</div>
			</div>
		</div>
	</div>
</div>
