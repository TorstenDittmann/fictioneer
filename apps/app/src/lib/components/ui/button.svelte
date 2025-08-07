<script lang="ts">
	import { Button, type ButtonRootProps } from 'bits-ui';

	type Props = {
		variant?: 'primary' | 'secondary' | 'destructive' | 'ghost';
		children?: import('svelte').Snippet;
	} & ButtonRootProps;

	let {
		variant = 'primary',
		class: additional_class = '',
		children,
		...rest_props
	}: Props = $props();

	const variant_classes = {
		primary: 'bg-paper-accent text-white hover:bg-paper-accent-light focus:ring-paper-accent',
		secondary:
			'border border-gray-200 bg-white text-gray-700 hover:bg-gray-100 focus:ring-gray-500',
		destructive: 'bg-red-600 text-white hover:bg-red-700 focus:ring-red-500',
		ghost: 'bg-transparent text-gray-700 hover:bg-gray-100 focus:ring-gray-400'
	};
</script>

<Button.Root
	class="inline-flex items-center justify-center rounded-md px-4 py-2 text-sm font-medium transition-colors focus:ring-2 focus:ring-offset-2 focus:outline-none disabled:opacity-50 {variant_classes[
		variant
	]} {additional_class}"
	{...rest_props}
>
	{#if children}
		{@render children()}
	{/if}
</Button.Root>
