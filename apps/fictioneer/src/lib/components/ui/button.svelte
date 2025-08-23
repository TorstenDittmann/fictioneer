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
		primary: 'bg-accent text-text-inverse hover:bg-accent-hover focus:ring-accent',
		secondary:
			'border border-border bg-background-tertiary text-text hover:bg-surface focus:ring-accent',
		destructive: 'bg-accent text-text-inverse hover:bg-accent-hover focus:ring-accent',
		ghost: 'bg-transparent text-text hover:bg-surface focus:ring-accent',
		outline:
			'border border-border bg-transparent text-text hover:bg-background-tertiary focus:ring-accent'
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
