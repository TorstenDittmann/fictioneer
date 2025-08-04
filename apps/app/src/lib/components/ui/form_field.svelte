<script lang="ts">
	import Input from './input.svelte';
	import Textarea from './textarea.svelte';

	interface Props {
		type?: 'input' | 'textarea';
		input_type?: 'text' | 'email' | 'password' | 'number' | 'tel' | 'url' | 'search';
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
		type = 'input',
		input_type = 'text',
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

	let field_component: Input | Textarea = $state()!;

	// Export methods for external control
	export function focus() {
		field_component?.focus();
	}

	export function select() {
		field_component?.select();
	}

	export function blur() {
		field_component?.blur();
	}
</script>

{#if type === 'textarea'}
	<Textarea
		bind:this={field_component}
		bind:value
		{placeholder}
		{disabled}
		{readonly}
		{required}
		{label}
		{hint}
		{error}
		{id}
		class={additional_class}
		{rows}
		{cols}
		{autofocus}
		{resize}
		{onchange}
		{oninput}
		{onkeydown}
		{onfocus}
		{onblur}
	/>
{:else}
	<Input
		bind:this={field_component}
		bind:value
		type={input_type}
		{placeholder}
		{disabled}
		{readonly}
		{required}
		{label}
		{hint}
		{error}
		{id}
		class={additional_class}
		{autofocus}
		{onchange}
		{oninput}
		{onkeydown}
		{onfocus}
		{onblur}
	/>
{/if}
