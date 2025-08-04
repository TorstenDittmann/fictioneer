<script lang="ts">
	interface Props {
		orientation?: 'horizontal' | 'vertical';
		size?: 'sm' | 'md' | 'lg';
		class?: string;
		children?: import('svelte').Snippet;
	}

	let {
		orientation = 'horizontal',
		size = 'md',
		class: additional_class = '',
		children
	}: Props = $props();

	const base_classes = 'inline-flex rounded-md shadow-sm';

	const orientation_classes = {
		horizontal: 'flex-row',
		vertical: 'flex-col'
	};

	const size_classes = {
		sm: '[&>*]:h-8 [&>*]:px-3 [&>*]:text-xs',
		md: '[&>*]:h-10 [&>*]:px-4 [&>*]:text-sm',
		lg: '[&>*]:h-12 [&>*]:px-6 [&>*]:text-base'
	};

	const spacing_classes =
		orientation === 'horizontal'
			? '[&>*:not(:first-child)]:ml-[-1px] [&>*:not(:first-child)]:rounded-l-none [&>*:not(:last-child)]:rounded-r-none [&>*:first-child]:rounded-r-none [&>*:last-child]:rounded-l-none'
			: '[&>*:not(:first-child)]:mt-[-1px] [&>*:not(:first-child)]:rounded-t-none [&>*:not(:last-child)]:rounded-b-none [&>*:first-child]:rounded-b-none [&>*:last-child]:rounded-t-none';

	const button_group_classes = `${base_classes} ${orientation_classes[orientation]} ${size_classes[size]} ${spacing_classes} ${additional_class}`;
</script>

<div class={button_group_classes} role="group">
	{#if children}
		{@render children()}
	{/if}
</div>
