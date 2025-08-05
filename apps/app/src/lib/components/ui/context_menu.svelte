<script lang="ts">
	import { ContextMenu } from 'bits-ui';
	import type { Snippet } from 'svelte';

	interface MenuItem {
		value?: string;
		label?: string;
		icon?: string;
		destructive?: boolean;
		separator?: boolean;
	}

	interface Props {
		children: Snippet;
		items?: MenuItem[];
		onSelect?: (value: string) => void;
	}

	let { children, items = [], onSelect }: Props = $props();

	function handle_select(value: string) {
		onSelect?.(value);
	}
</script>

<ContextMenu.Root>
	<ContextMenu.Trigger class="block select-none">
		{@render children()}
	</ContextMenu.Trigger>
	<ContextMenu.Portal>
		<ContextMenu.Content
			class="data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0 data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-95 data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2 z-50 min-w-32 overflow-hidden rounded-md border border-gray-200 bg-white p-1 text-gray-950 shadow-md dark:border-gray-800 dark:bg-gray-950 dark:text-gray-50"
		>
			{#each items as item, index (item.separator ? `separator-${index}` : item.value)}
				{#if item.separator}
					<ContextMenu.Separator class="-mx-1 my-1 h-px bg-gray-100 dark:bg-gray-800" />
				{:else}
					<ContextMenu.Item
						class={`relative flex cursor-default items-center rounded-sm px-2 py-1.5 text-sm transition-colors outline-none select-none data-[highlighted]:bg-gray-100 data-[highlighted]:text-gray-900 dark:data-[highlighted]:bg-gray-800 dark:data-[highlighted]:text-gray-50 ${item.destructive ? 'text-red-600 dark:text-red-400' : ''}`}
						onSelect={() => item.value && handle_select(item.value)}
					>
						{#if item.icon}
							<svg class="mr-2 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
								{#if item.icon === 'edit'}
									<path
										stroke-linecap="round"
										stroke-linejoin="round"
										stroke-width="2"
										d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
									/>
								{:else if item.icon === 'delete'}
									<path
										stroke-linecap="round"
										stroke-linejoin="round"
										stroke-width="2"
										d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
									/>
								{:else if item.icon === 'add'}
									<path
										stroke-linecap="round"
										stroke-linejoin="round"
										stroke-width="2"
										d="M12 6v6m0 0v6m0-6h6m-6 0H6"
									/>
								{/if}
							</svg>
						{/if}
						{item.label || ''}
					</ContextMenu.Item>
				{/if}
			{/each}
		</ContextMenu.Content>
	</ContextMenu.Portal>
</ContextMenu.Root>
