<script lang="ts">
	import { Button, type ButtonRootProps } from 'bits-ui';

	let { class: additional_class = '', children, ...rest_props }: ButtonRootProps = $props();
</script>

<Button.Root
	class="inline-flex h-10 w-10 items-center justify-center rounded-md text-sm font-medium transition-colors hover:bg-background-tertiary focus:ring-2 focus:ring-accent focus:outline-none disabled:opacity-50 {additional_class}"
	{...rest_props}
>
	{#if children}
		{@render children()}
	{/if}
</Button.Root>
