<script lang="ts">
	import type { HTMLTextareaAttributes } from 'svelte/elements';

	interface Props extends HTMLTextareaAttributes {
		value?: string;
		class?: string;
	}

	let { value = $bindable(''), class: additional_class = '', ...rest_props }: Props = $props();
</script>

<textarea
	bind:value
	class="flex min-h-[80px] w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text ring-offset-background placeholder:text-text-muted focus:ring-2 focus:ring-accent focus:ring-offset-2 focus:outline-none disabled:cursor-not-allowed disabled:opacity-50 {additional_class}"
	{...rest_props}
></textarea>
