<script lang="ts">
	interface Props {
		tags: string[];
		suggestions?: string[];
		placeholder?: string;
		onAdd?: (tag: string) => void;
		onRemove?: (tag: string) => void;
	}

	let { tags, suggestions = [], placeholder = 'Add tag...', onAdd, onRemove }: Props = $props();

	let input_value = $state('');
	let show_suggestions = $state(false);

	const filtered_suggestions = $derived(
		suggestions
			.filter(
				(s) =>
					s.toLowerCase().includes(input_value.toLowerCase()) && !tags.includes(s.toLowerCase())
			)
			.slice(0, 5)
	);

	function handle_keydown(event: KeyboardEvent) {
		if (event.key === 'Enter' && input_value.trim()) {
			event.preventDefault();
			add_tag(input_value.trim());
		} else if (event.key === 'Backspace' && !input_value && tags.length > 0) {
			remove_tag(tags[tags.length - 1]);
		} else if (event.key === 'Escape') {
			show_suggestions = false;
		}
	}

	function add_tag(tag: string) {
		const normalized = tag.toLowerCase().trim();
		if (normalized && !tags.includes(normalized)) {
			onAdd?.(normalized);
		}
		input_value = '';
		show_suggestions = false;
	}

	function remove_tag(tag: string) {
		onRemove?.(tag);
	}

	function handle_suggestion_click(suggestion: string) {
		add_tag(suggestion);
	}
</script>

<div class="relative">
	<div
		class="flex flex-wrap items-center gap-1.5 rounded-lg border border-border bg-background px-2 py-1.5 focus-within:ring-2 focus-within:ring-accent/20"
	>
		{#each tags as tag (tag)}
			<span
				class="inline-flex items-center gap-1 rounded-md bg-accent/10 px-2 py-0.5 text-sm text-accent"
			>
				{tag}
				<button
					type="button"
					onclick={() => remove_tag(tag)}
					class="ml-0.5 rounded-sm hover:bg-accent/20"
					aria-label="Remove tag {tag}"
				>
					<svg class="h-3 w-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
						<path
							stroke-linecap="round"
							stroke-linejoin="round"
							stroke-width="2"
							d="M6 18L18 6M6 6l12 12"
						/>
					</svg>
				</button>
			</span>
		{/each}
		<input
			type="text"
			bind:value={input_value}
			onkeydown={handle_keydown}
			onfocus={() => (show_suggestions = true)}
			onblur={() => setTimeout(() => (show_suggestions = false), 150)}
			{placeholder}
			class="min-w-[100px] flex-1 border-none bg-transparent p-1 text-sm text-text outline-none placeholder:text-text-muted"
		/>
	</div>

	{#if show_suggestions && filtered_suggestions.length > 0}
		<div
			class="absolute top-full left-0 z-10 mt-1 w-full rounded-lg border border-border bg-background py-1 shadow-lg"
		>
			{#each filtered_suggestions as suggestion (suggestion)}
				<button
					type="button"
					class="w-full px-3 py-1.5 text-left text-sm text-text hover:bg-background-tertiary"
					onmousedown={() => handle_suggestion_click(suggestion)}
				>
					{suggestion}
				</button>
			{/each}
		</div>
	{/if}
</div>
