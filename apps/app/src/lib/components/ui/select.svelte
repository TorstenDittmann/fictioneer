<script lang="ts">
	import { Select } from 'bits-ui';

	interface SelectItem {
		value: string;
		label: string;
		disabled?: boolean;
	}

	interface Props {
		value?: string;
		items: SelectItem[];
		placeholder?: string;
		class?: string;
		disabled?: boolean;
		required?: boolean;
		name?: string;
		open?: boolean;
		onOpenChange?: (open: boolean) => void;
		onValueChange?: (value: string) => void;
		children?: import('svelte').Snippet;
	}

	let {
		value = $bindable(),
		items,
		placeholder = 'Select an option...',
		class: additional_class = '',
		disabled = false,
		required = false,
		name,
		open,
		onOpenChange,
		onValueChange,
		children
	}: Props = $props();

	const selected_item = $derived(items.find((item) => item.value === value));
</script>

<Select.Root
	type="single"
	bind:value
	{disabled}
	{required}
	{name}
	{open}
	{onOpenChange}
	{onValueChange}
>
	<Select.Trigger
		class="inline-flex h-10 w-full items-center justify-between rounded-md border border-gray-200 bg-white px-3 py-2 text-sm ring-offset-white placeholder:text-gray-500 focus:ring-2 focus:ring-gray-500 focus:ring-offset-2 focus:outline-none disabled:cursor-not-allowed disabled:opacity-50 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-100 dark:ring-offset-gray-800 dark:placeholder:text-gray-400 dark:focus:ring-gray-600 {additional_class}"
	>
		<span class="truncate">
			{selected_item?.label || placeholder}
		</span>
		<svg
			class="h-4 w-4 text-gray-500 dark:text-gray-400"
			xmlns="http://www.w3.org/2000/svg"
			viewBox="0 0 24 24"
			fill="none"
			stroke="currentColor"
			stroke-width="2"
			stroke-linecap="round"
			stroke-linejoin="round"
		>
			<path d="m7 15 5 5 5-5" />
			<path d="m7 9 5-5 5 5" />
		</svg>
	</Select.Trigger>

	<Select.Portal>
		<Select.Content
			class="relative z-50 max-h-96 min-w-32 overflow-hidden rounded-md border border-gray-200 bg-white text-gray-900 shadow-md dark:border-gray-700 dark:bg-gray-800 dark:text-gray-100"
		>
			<Select.Viewport class="p-1">
				{#each items as item (item.value)}
					<Select.Item
						class="relative flex w-full cursor-default items-center rounded-sm py-1.5 pr-2 pl-8 text-sm outline-none select-none hover:bg-gray-100 data-[disabled]:pointer-events-none data-[disabled]:opacity-50 data-[highlighted]:bg-gray-100 dark:hover:bg-gray-700 dark:data-[highlighted]:bg-gray-700"
						value={item.value}
						disabled={item.disabled}
					>
						{#snippet children({ selected })}
							{#if selected}
								<span class="absolute left-2 flex h-3.5 w-3.5 items-center justify-center">
									<svg
										class="h-4 w-4 text-gray-600 dark:text-gray-400"
										xmlns="http://www.w3.org/2000/svg"
										viewBox="0 0 24 24"
										fill="none"
										stroke="currentColor"
										stroke-width="2"
										stroke-linecap="round"
										stroke-linejoin="round"
									>
										<path d="M20 6 9 17l-5-5" />
									</svg>
								</span>
							{/if}
							{item.label}
						{/snippet}
					</Select.Item>
				{/each}
			</Select.Viewport>
		</Select.Content>
	</Select.Portal>
</Select.Root>

{#if children}
	{@render children()}
{/if}
