<script lang="ts">
	import { Button, type ButtonRootProps } from 'bits-ui';

	type Props = {
		variant?: 'primary' | 'secondary' | 'destructive' | 'ghost' | 'outline';
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
			'border border-paper-border bg-paper-beige text-paper-text hover:bg-paper-gray focus:ring-paper-accent',
		destructive: 'bg-paper-accent text-white hover:bg-paper-accent-light focus:ring-paper-accent',
		ghost: 'bg-transparent text-paper-text hover:bg-paper-gray focus:ring-paper-accent',
		outline:
			'border border-paper-border bg-transparent text-paper-text hover:bg-paper-beige focus:ring-paper-accent'
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
