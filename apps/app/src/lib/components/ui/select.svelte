<script lang="ts">
	import { Select } from 'bits-ui';

	interface SelectItem {
		value: string;
		label: string;
		disabled?: boolean;
	}

	interface Props {
		value?: string;
		placeholder?: string;
		items: SelectItem[];
		disabled?: boolean;
		required?: boolean;
		label?: string;
		hint?: string;
		error?: string;
		id?: string;
		class?: string;
		onValueChange?: (value: string) => void;
	}

	let {
		value = $bindable(),
		placeholder = 'Select an option...',
		items,
		disabled = false,
		required = false,
		label = '',
		hint = '',
		error = '',
		id = '',
		class: additional_class = '',
		onValueChange
	}: Props = $props();

	let select_id = id || `select-${Math.random().toString(36).substring(2, 9)}`;
	const selected_label = $derived(items.find((item) => item.value === value)?.label);

	const trigger_classes = error
		? 'border-red-300 bg-white text-gray-900 focus:ring-red-500 dark:border-red-600 dark:bg-gray-700 dark:text-gray-100 dark:focus:ring-red-600'
		: 'border-gray-200 bg-white text-gray-900 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-100 dark:focus:ring-blue-600';

	const base_trigger_classes = `inline-flex h-10 w-full items-center justify-between rounded-md border px-3 py-2 text-sm ring-offset-white placeholder:text-gray-500 focus:outline-none focus:ring-2 focus:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50 dark:ring-offset-gray-800 dark:placeholder:text-gray-400 ${trigger_classes} ${additional_class}`;
</script>

{#if label}
	<div class="grid gap-2">
		<label
			for={select_id}
			class="text-sm leading-none font-medium text-gray-700 peer-disabled:cursor-not-allowed peer-disabled:opacity-70 dark:text-gray-300"
		>
			{label}
			{#if required}
				<span class="text-red-500">*</span>
			{/if}
		</label>

		<Select.Root bind:value type="single" {disabled} {onValueChange}>
			<Select.Trigger id={select_id} class={base_trigger_classes} aria-label={placeholder}>
				<span class="truncate">
					{selected_label || placeholder}
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
					class="data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0 data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-95 data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2 relative z-50 max-h-96 min-w-32 overflow-hidden rounded-md border border-gray-200 bg-white text-gray-900 shadow-md dark:border-gray-700 dark:bg-gray-800 dark:text-gray-100"
					sideOffset={4}
				>
					<Select.ScrollUpButton
						class="flex cursor-default items-center justify-center py-1 text-gray-500 dark:text-gray-400"
					>
						<svg
							class="h-4 w-4"
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
								class="relative flex w-full cursor-default items-center rounded-sm py-1.5 pr-2 pl-8 text-sm outline-none select-none hover:bg-gray-100 data-[disabled]:pointer-events-none data-[disabled]:opacity-50 data-[highlighted]:bg-gray-100 dark:hover:bg-gray-700 dark:data-[highlighted]:bg-gray-700"
								value={item.value}
								label={item.label}
								disabled={item.disabled}
							>
								{#snippet children({ selected })}
									{#if selected}
										<span class="absolute left-2 flex h-3.5 w-3.5 items-center justify-center">
											<svg
												class="h-4 w-4 text-blue-600 dark:text-blue-400"
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
						class="flex cursor-default items-center justify-center py-1 text-gray-500 dark:text-gray-400"
					>
						<svg
							class="h-4 w-4"
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

		{#if hint && !error}
			<p class="text-xs text-gray-500 dark:text-gray-400">{hint}</p>
		{/if}
		{#if error}
			<p class="text-xs text-red-500 dark:text-red-400">{error}</p>
		{/if}
	</div>
{:else}
	<Select.Root bind:value type="single" {disabled} {onValueChange}>
		<Select.Trigger id={select_id} class={base_trigger_classes} aria-label={placeholder}>
			<span class="truncate">
				{selected_label || placeholder}
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
				class="data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0 data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-95 data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2 relative z-50 max-h-96 min-w-32 overflow-hidden rounded-md border border-gray-200 bg-white text-gray-900 shadow-md dark:border-gray-700 dark:bg-gray-800 dark:text-gray-100"
				sideOffset={4}
			>
				<Select.ScrollUpButton
					class="flex cursor-default items-center justify-center py-1 text-gray-500 dark:text-gray-400"
				>
					<svg
						class="h-4 w-4"
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
							class="relative flex w-full cursor-default items-center rounded-sm py-1.5 pr-2 pl-8 text-sm outline-none select-none hover:bg-gray-100 data-[disabled]:pointer-events-none data-[disabled]:opacity-50 data-[highlighted]:bg-gray-100 dark:hover:bg-gray-700 dark:data-[highlighted]:bg-gray-700"
							value={item.value}
							label={item.label}
							disabled={item.disabled}
						>
							{#snippet children({ selected })}
								{#if selected}
									<span class="absolute left-2 flex h-3.5 w-3.5 items-center justify-center">
										<svg
											class="h-4 w-4 text-blue-600 dark:text-blue-400"
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
					class="flex cursor-default items-center justify-center py-1 text-gray-500 dark:text-gray-400"
				>
					<svg
						class="h-4 w-4"
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
{/if}
