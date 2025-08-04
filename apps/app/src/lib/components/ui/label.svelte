<script lang="ts">
	interface Props {
		for?: string;
		required?: boolean;
		class?: string;
		children?: import('svelte').Snippet;
	}

	let {
		for: htmlFor = '',
		required = false,
		class: additional_class = '',
		children
	}: Props = $props();

	const base_classes =
		'text-sm font-medium leading-none text-gray-700 peer-disabled:cursor-not-allowed peer-disabled:opacity-70 dark:text-gray-300';
	const label_classes = `${base_classes} ${additional_class}`;
</script>

<label for={htmlFor} class={label_classes}>
	{#if children}
		{@render children()}
	{/if}
	{#if required}
		<span class="text-red-500">*</span>
	{/if}
</label>
