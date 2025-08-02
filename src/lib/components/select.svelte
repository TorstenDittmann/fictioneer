<script lang="ts">
	import { Select, type WithoutChildren } from 'bits-ui';

	type SelectItem = {
		value: string;
		label: string;
		disabled?: boolean;
	};

	type Props = {
		value?: string;
		placeholder?: string;
		items: SelectItem[];
		content_props?: WithoutChildren<Select.ContentProps>;
		class?: string;
		onValueChange?: (value: string) => void;
	};

	let {
		value = $bindable(),
		items,
		content_props,
		placeholder = 'Select an option...',
		class: class_name = '',
		onValueChange
	}: Props = $props();

	const selected_label = $derived(items.find((item) => item.value === value)?.label);
</script>

<Select.Root bind:value type="single" {onValueChange}>
	<Select.Trigger
		class="inline-flex h-10 w-full items-center justify-between rounded-md border border-[var(--paper-border)] bg-[var(--paper-white)] px-3 py-2 text-sm text-[var(--paper-text)] placeholder:text-[var(--paper-text-muted)] focus:ring-2 focus:ring-[var(--paper-accent)] focus:ring-offset-2 focus:outline-none disabled:cursor-not-allowed disabled:opacity-50 {class_name}"
		aria-label={placeholder}
	>
		<span class="truncate text-[var(--paper-text)]">
			{selected_label || placeholder}
		</span>
		<svg
			class="h-4 w-4 text-[var(--paper-text-muted)]"
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
			class="data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0 data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-95 data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2 relative z-50 max-h-96 min-w-32 overflow-hidden rounded-md border border-[var(--paper-border)] bg-[var(--paper-white)] text-[var(--paper-text)] shadow-md"
			sideOffset={4}
			{...content_props}
		>
			<Select.ScrollUpButton
				class="flex cursor-default items-center justify-center py-1 text-[var(--paper-text-muted)]"
			>
				<svg
					class="h-4 w-4 text-[var(--paper-text-muted)]"
					xmlns="http://www.w3.org/2000/svg"
					viewBox="0 0 24 24"
					fill="none"
					stroke="currentColor"
					stroke-width="2"
					stroke-linecap="round"
					stroke-linejoin="round"
				>
					<path d="m18 15-6-6-6 6" />
				</svg>
			</Select.ScrollUpButton>

			<Select.Viewport class="p-1">
				{#each items as item (item.value)}
					<Select.Item
						class="relative flex w-full cursor-default items-center rounded-sm py-1.5 pr-2 pl-8 text-sm text-[var(--paper-text)] outline-none select-none hover:bg-[var(--paper-beige)] data-[disabled]:pointer-events-none data-[disabled]:opacity-50 data-[highlighted]:bg-[var(--paper-beige)]"
						value={item.value}
						label={item.label}
						disabled={item.disabled}
					>
						{#snippet children({ selected })}
							{#if selected}
								<span class="absolute left-2 flex h-3.5 w-3.5 items-center justify-center">
									<svg
										class="h-4 w-4 text-[var(--paper-accent)]"
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

			<Select.ScrollDownButton
				class="flex cursor-default items-center justify-center py-1 text-[var(--paper-text-muted)]"
			>
				<svg
					class="h-4 w-4 text-[var(--paper-text-muted)]"
					xmlns="http://www.w3.org/2000/svg"
					viewBox="0 0 24 24"
					fill="none"
					stroke="currentColor"
					stroke-width="2"
					stroke-linecap="round"
					stroke-linejoin="round"
				>
					<path d="m6 9 6 6 6-6" />
				</svg>
			</Select.ScrollDownButton>
		</Select.Content>
	</Select.Portal>
</Select.Root>
