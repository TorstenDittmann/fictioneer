<script lang="ts">
	interface Props {
		variant?: 'default' | 'outline' | 'filled';
		padding?: 'none' | 'sm' | 'md' | 'lg';
		class?: string;
		children?: import('svelte').Snippet;
	}

	let {
		variant = 'default',
		padding = 'md',
		class: additional_class = '',
		children
	}: Props = $props();

	const base_classes = 'rounded-lg transition-colors';

	const variant_classes = {
		default: 'border bg-white shadow-sm dark:border-gray-700 dark:bg-gray-800',
		outline: 'border-2 border-gray-200 bg-transparent dark:border-gray-600',
		filled: 'bg-gray-50 border border-gray-200 dark:bg-gray-700 dark:border-gray-600'
	};

	const padding_classes = {
		none: '',
		sm: 'p-3',
		md: 'p-6',
		lg: 'p-8'
	};

	const card_classes = `${base_classes} ${variant_classes[variant]} ${padding_classes[padding]} ${additional_class}`;
</script>

<div class={card_classes}>
	{#if children}
		{@render children()}
	{/if}
</div>
