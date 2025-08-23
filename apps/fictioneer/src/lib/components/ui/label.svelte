<script lang="ts">
	import type { HTMLLabelAttributes } from 'svelte/elements';

	interface Props extends HTMLLabelAttributes {
		class?: string;
		children?: import('svelte').Snippet;
	}

	let { class: additional_class = '', children, ...rest_props }: Props = $props();
</script>

<label class="text-sm font-medium text-text-secondary {additional_class}" {...rest_props}>
	{#if children}
		{@render children()}
	{/if}
</label>
