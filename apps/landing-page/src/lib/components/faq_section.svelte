<script lang="ts">
	import type { FaqItem } from '$lib/content/faq_items';
	import { faq_items } from '$lib/content/faq_items';

	let {
		title = 'Frequently Asked Questions',
		intro,
		items = faq_items
	} = $props<{
		title?: string;
		intro?: string;
		items?: FaqItem[];
	}>();
</script>

<section class="mx-auto max-w-4xl">
	<div class="mb-10 text-center">
		<h2 class="animate-fade-in-up text-3xl font-bold text-paper-text" style:animation-delay="0.2s">
			{title}
		</h2>
		{#if intro}
			<p
				class="animate-fade-in-up mt-3 text-base text-paper-text-light/90 sm:text-lg"
				style:animation-delay="0.3s"
			>
				{intro}
			</p>
		{/if}
	</div>

	<div class="space-y-6">
		{#each items as item, idx (item.question)}
			<div
				class="animate-fade-in-up rounded-2xl border border-paper-border bg-paper-cream/30 p-6"
				style:animation-delay={`${0.4 + idx * 0.1}s`}
			>
				<h3 class="mb-2 text-lg font-semibold text-paper-text">{item.question}</h3>
				<p class="text-paper-text-light">{item.answer}</p>
			</div>
		{/each}
	</div>
</section>
