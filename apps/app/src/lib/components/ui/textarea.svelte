<script lang="ts">
	interface Props {
		value?: string;
		placeholder?: string;
		disabled?: boolean;
		readonly?: boolean;
		required?: boolean;
		label?: string;
		hint?: string;
		error?: string;
		id?: string;
		class?: string;
		rows?: number;
		cols?: number;
		autofocus?: boolean;
		resize?: boolean;
		onchange?: (value: string) => void;
		oninput?: (value: string) => void;
		onkeydown?: (event: KeyboardEvent) => void;
		onfocus?: (event: FocusEvent) => void;
		onblur?: (event: FocusEvent) => void;
	}

	let {
		value = $bindable(''),
		placeholder = '',
		disabled = false,
		readonly = false,
		required = false,
		label = '',
		hint = '',
		error = '',
		id = '',
		class: additional_class = '',
		rows = 3,
		cols,
		autofocus = false,
		resize = true,
		onchange,
		oninput,
		onkeydown,
		onfocus,
		onblur
	}: Props = $props();

	let textarea_element: HTMLTextAreaElement = $state()!;
	let textarea_id = id || `textarea-${Math.random().toString(36).substring(2, 9)}`;

	const base_classes =
		'flex min-h-[80px] w-full rounded-md border px-3 py-2 text-sm ring-offset-white placeholder:text-gray-500 focus:outline-none focus:ring-2 focus:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50';

	const variant_classes = error
		? 'border-red-300 bg-white text-gray-900 focus:ring-red-500 dark:border-red-600 dark:bg-gray-700 dark:text-gray-100 dark:ring-offset-gray-800 dark:placeholder:text-gray-400 dark:focus:ring-red-600'
		: readonly
			? 'border-gray-200 bg-gray-50 text-gray-900 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-600 dark:text-gray-100 dark:ring-offset-gray-800 dark:placeholder:text-gray-400 dark:focus:ring-blue-600'
			: 'border-gray-200 bg-white text-gray-900 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-100 dark:ring-offset-gray-800 dark:placeholder:text-gray-400 dark:focus:ring-blue-600';

	const resize_classes = resize ? 'resize-y' : 'resize-none';

	const textarea_classes = `${base_classes} ${variant_classes} ${resize_classes} ${additional_class}`;

	function handle_input(event: Event) {
		const target = event.target as HTMLTextAreaElement;
		value = target.value;
		if (oninput) {
			oninput(value);
		}
	}

	function handle_change(event: Event) {
		const target = event.target as HTMLTextAreaElement;
		value = target.value;
		if (onchange) {
			onchange(value);
		}
	}

	function handle_keydown(event: KeyboardEvent) {
		if (onkeydown) {
			onkeydown(event);
		}
	}

	function handle_focus(event: FocusEvent) {
		if (onfocus) {
			onfocus(event);
		}
	}

	function handle_blur(event: FocusEvent) {
		if (onblur) {
			onblur(event);
		}
	}

	// Auto-focus functionality
	$effect(() => {
		if (autofocus && textarea_element) {
			setTimeout(() => {
				textarea_element.focus();
				if (value) {
					textarea_element.select();
				}
			}, 100);
		}
	});

	// Export focus and select methods for external control
	export function focus() {
		textarea_element?.focus();
	}

	export function select() {
		textarea_element?.select();
	}

	export function blur() {
		textarea_element?.blur();
	}
</script>

{#if label}
	<div class="grid gap-2">
		<label
			for={textarea_id}
			class="text-sm leading-none font-medium text-gray-700 peer-disabled:cursor-not-allowed peer-disabled:opacity-70 dark:text-gray-300"
		>
			{label}
			{#if required}
				<span class="text-red-500">*</span>
			{/if}
		</label>
		<textarea
			bind:this={textarea_element}
			{...{ id: textarea_id, placeholder, disabled, readonly, required, rows, cols }}
			{value}
			class={textarea_classes}
			oninput={handle_input}
			onchange={handle_change}
			onkeydown={handle_keydown}
			onfocus={handle_focus}
			onblur={handle_blur}
		></textarea>
		{#if hint && !error}
			<p class="text-xs text-gray-500 dark:text-gray-400">{hint}</p>
		{/if}
		{#if error}
			<p class="text-xs text-red-500 dark:text-red-400">{error}</p>
		{/if}
	</div>
{:else}
	<textarea
		bind:this={textarea_element}
		{...{ id: textarea_id, placeholder, disabled, readonly, required, rows, cols }}
		{value}
		class={textarea_classes}
		oninput={handle_input}
		onchange={handle_change}
		onkeydown={handle_keydown}
		onfocus={handle_focus}
		onblur={handle_blur}
	></textarea>
{/if}
