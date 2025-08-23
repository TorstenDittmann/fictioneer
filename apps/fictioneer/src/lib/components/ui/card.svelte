<script lang="ts">
	import type { ClassValue } from 'svelte/elements';

	interface Props {
		class?: ClassValue;
		children?: import('svelte').Snippet;
	}

	let { class: additional_class = '', children }: Props = $props();
</script>

<div
	class="rounded-lg border border-border bg-background-secondary p-6 shadow-sm {additional_class}"
>
	{#if children}
		{@render children()}
	{/if}
</div>
