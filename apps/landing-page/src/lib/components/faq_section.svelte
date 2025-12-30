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

	let open_index = $state<number | null>(null);

	function toggle(index: number) {
		open_index = open_index === index ? null : index;
	}
</script>

<section class="mx-auto max-w-3xl">
	<!-- Header -->
	<div class="mb-10 text-center">
		<h2
			class="animate-fade-in-up font-serif text-2xl font-semibold text-paper-text sm:text-3xl"
			style:animation-delay="0.1s"
		>
			{title}
		</h2>
		{#if intro}
			<p class="animate-fade-in-up mt-3 text-paper-text-light" style:animation-delay="0.15s">
				{intro}
			</p>
		{/if}
	</div>

	<!-- FAQ Items -->
	<div class="space-y-3">
		{#each items as item, idx (item.question)}
			<div
				class="animate-fade-in-up overflow-hidden rounded-2xl border border-paper-border bg-paper-cream/60 backdrop-blur-sm transition-all duration-200"
				style:animation-delay="{0.2 + idx * 0.05}s"
			>
				<button
					onclick={() => toggle(idx)}
					class="flex w-full items-center justify-between gap-4 p-5 text-left transition-colors hover:bg-paper-beige/30"
					aria-expanded={open_index === idx}
				>
					<span class="text-base font-semibold text-paper-text">{item.question}</span>
					<svg
						class="h-5 w-5 shrink-0 text-paper-text-muted transition-transform duration-200"
						class:rotate-180={open_index === idx}
						fill="none"
						stroke="currentColor"
						viewBox="0 0 24 24"
					>
						<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"
						></path>
					</svg>
				</button>

				{#if open_index === idx}
					<div class="border-t border-paper-border bg-paper-beige/20 px-5 py-4">
						<p class="text-sm leading-relaxed text-paper-text-light">{item.answer}</p>
					</div>
				{/if}
			</div>
		{/each}
	</div>
</section>
