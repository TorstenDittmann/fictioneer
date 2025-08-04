<script lang="ts">
	import { Button as BitsButton } from 'bits-ui';

	interface Props {
		variant?: 'primary' | 'secondary' | 'destructive' | 'ghost';
		size?: 'sm' | 'md' | 'lg';
		disabled?: boolean;
		loading?: boolean;
		type?: 'button' | 'submit' | 'reset';
		onclick?: (event: MouseEvent) => void;
		class?: string;
		title?: string;
		ariaLabel?: string;
		children?: import('svelte').Snippet;
	}

	let {
		variant = 'ghost',
		size = 'md',
		disabled = false,
		loading = false,
		type = 'button',
		onclick,
		class: additional_class = '',
		title = '',
		ariaLabel = '',
		children
	}: Props = $props();

	const base_classes =
		'inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 disabled:pointer-events-none disabled:opacity-50';

	const variant_classes = {
		primary:
			'bg-blue-600 text-white ring-offset-white hover:bg-blue-700 focus:ring-blue-500 dark:ring-offset-gray-950',
		secondary:
			'border border-gray-200 bg-white text-gray-700 ring-offset-white hover:bg-gray-100 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-300 dark:ring-offset-gray-800 dark:hover:bg-gray-600 dark:focus:ring-gray-600',
		destructive:
			'border border-red-800 bg-red-950 text-red-50 ring-offset-gray-950 hover:bg-red-800 focus:ring-red-300 dark:border-red-800 dark:bg-red-950 dark:text-red-50 dark:hover:bg-red-800 dark:focus:ring-red-300',
		ghost:
			'bg-transparent text-gray-500 hover:bg-gray-100 hover:text-gray-900 focus:ring-gray-400 dark:text-gray-400 dark:hover:bg-gray-700 dark:hover:text-gray-100 dark:focus:ring-gray-600'
	};

	const size_classes = {
		sm: 'h-8 w-8 text-xs',
		md: 'h-10 w-10 text-sm',
		lg: 'h-12 w-12 text-base'
	};

	const button_classes = `${base_classes} ${variant_classes[variant]} ${size_classes[size]} ${additional_class}`;
</script>

<BitsButton.Root
	{type}
	{title}
	aria-label={ariaLabel}
	class={button_classes}
	{onclick}
	disabled={disabled || loading}
>
	{#if loading}
		<svg class="h-4 w-4 animate-spin" viewBox="0 0 24 24">
			<circle
				class="opacity-25"
				cx="12"
				cy="12"
				r="10"
				stroke="currentColor"
				stroke-width="4"
				fill="none"
			/>
			<path
				class="opacity-75"
				fill="currentColor"
				d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
			/>
		</svg>
	{:else if children}
		{@render children()}
	{/if}
</BitsButton.Root>
