<script lang="ts">
	interface Props {
		value?: string;
		placeholder?: string;
		type?: 'text' | 'email' | 'password' | 'number' | 'tel' | 'url' | 'search';
		disabled?: boolean;
		readonly?: boolean;
		required?: boolean;
		label?: string;
		hint?: string;
		error?: string;
		id?: string;
		class?: string;
		autofocus?: boolean;
		onchange?: (value: string) => void;
		oninput?: (value: string) => void;
		onkeydown?: (event: KeyboardEvent) => void;
		onfocus?: (event: FocusEvent) => void;
		onblur?: (event: FocusEvent) => void;
	}

	let {
		value = $bindable(''),
		placeholder = '',
		type = 'text',
		disabled = false,
		readonly = false,
		required = false,
		label = '',
		hint = '',
		error = '',
		id = '',
		class: additional_class = '',
		autofocus = false,
		onchange,
		oninput,
		onkeydown,
		onfocus,
		onblur
	}: Props = $props();

	let input_element: HTMLInputElement = $state()!;
	let input_id = id || `input-${Math.random().toString(36).substring(2, 9)}`;

	const base_classes =
		'flex h-10 w-full rounded-md border px-3 py-2 text-sm ring-offset-white file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-gray-500 focus:outline-none focus:ring-2 focus:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50';

	const variant_classes = error
		? 'border-red-300 bg-white text-gray-900 focus:ring-red-500 dark:border-red-600 dark:bg-gray-700 dark:text-gray-100 dark:ring-offset-gray-800 dark:placeholder:text-gray-400 dark:focus:ring-red-600'
		: readonly
			? 'border-gray-200 bg-gray-50 text-gray-900 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-600 dark:text-gray-100 dark:ring-offset-gray-800 dark:placeholder:text-gray-400 dark:focus:ring-blue-600'
			: 'border-gray-200 bg-white text-gray-900 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-100 dark:ring-offset-gray-800 dark:placeholder:text-gray-400 dark:focus:ring-blue-600';

	const input_classes = `${base_classes} ${variant_classes} ${additional_class}`;

	function handle_input(event: Event) {
		const target = event.target as HTMLInputElement;
		value = target.value;
		if (oninput) {
			oninput(value);
		}
	}

	function handle_change(event: Event) {
		const target = event.target as HTMLInputElement;
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
		if (autofocus && input_element) {
			setTimeout(() => {
				input_element.focus();
				if (type === 'text' && value) {
					input_element.select();
				}
			}, 100);
		}
	});

	// Export focus and select methods for external control
	export function focus() {
		input_element?.focus();
	}

	export function select() {
		input_element?.select();
	}

	export function blur() {
		input_element?.blur();
	}
</script>

{#if label}
	<div class="grid gap-2">
		<label
			for={input_id}
			class="text-sm leading-none font-medium text-gray-700 peer-disabled:cursor-not-allowed peer-disabled:opacity-70 dark:text-gray-300"
		>
			{label}
			{#if required}
				<span class="text-red-500">*</span>
			{/if}
		</label>
		<input
			bind:this={input_element}
			{...{ id: input_id, type, placeholder, disabled, readonly, required }}
			{value}
			class={input_classes}
			oninput={handle_input}
			onchange={handle_change}
			onkeydown={handle_keydown}
			onfocus={handle_focus}
			onblur={handle_blur}
		/>
		{#if hint && !error}
			<p class="text-xs text-gray-500 dark:text-gray-400">{hint}</p>
		{/if}
		{#if error}
			<p class="text-xs text-red-500 dark:text-red-400">{error}</p>
		{/if}
	</div>
{:else}
	<input
		bind:this={input_element}
		{...{ id: input_id, type, placeholder, disabled, readonly, required }}
		{value}
		class={input_classes}
		oninput={handle_input}
		onchange={handle_change}
		onkeydown={handle_keydown}
		onfocus={handle_focus}
		onblur={handle_blur}
	/>
{/if}
