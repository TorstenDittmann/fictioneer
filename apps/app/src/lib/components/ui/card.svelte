<script lang="ts">
	interface Props {
		class?: string;
		children?: import('svelte').Snippet;
	}

	let { class: additional_class = '', children }: Props = $props();
</script>

<div
	class="rounded-lg border bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800 {additional_class}"
>
	{#if children}
		{@render children()}
	{/if}
</div>
