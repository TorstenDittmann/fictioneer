<script lang="ts">
	import { Dialog } from 'bits-ui';

	interface Props {
		open: boolean;
		title?: string;
		description?: string;
		size?: 'sm' | 'md' | 'lg' | 'xl';
		class?: string;
		onOpenChange?: (open: boolean) => void;
		onEscapeKeydown?: (event: KeyboardEvent) => void;
		onOutsideClick?: (event: MouseEvent) => void;
		closeOnEscape?: boolean;
		closeOnOutsideClick?: boolean;
		header?: import('svelte').Snippet;
		content?: import('svelte').Snippet;
		footer?: import('svelte').Snippet;
		children?: import('svelte').Snippet;
	}

	let {
		open = $bindable(),
		title = '',
		description = '',
		size = 'md',
		class: additional_class = '',
		onOpenChange,
		onEscapeKeydown,
		onOutsideClick,
		closeOnEscape = true,
		closeOnOutsideClick = true,
		header,
		content,
		footer,
		children
	}: Props = $props();

	const size_classes = {
		sm: 'max-w-sm',
		md: 'max-w-lg',
		lg: 'max-w-2xl',
		xl: 'max-w-4xl'
	};

	const modal_classes = `fixed left-[50%] top-[50%] z-50 grid w-full ${size_classes[size]} translate-x-[-50%] translate-y-[-50%] gap-6 border bg-white p-6 shadow-lg duration-200 data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0 data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-95 data-[state=closed]:slide-out-to-left-1/2 data-[state=closed]:slide-out-to-top-[48%] data-[state=open]:slide-in-from-left-1/2 data-[state=open]:slide-in-from-top-[48%] sm:rounded-lg dark:border-gray-700 dark:bg-gray-800 ${additional_class}`;

	function handle_escape_keydown(event: KeyboardEvent) {
		if (onEscapeKeydown) {
			onEscapeKeydown(event);
		}
		if (!closeOnEscape) {
			event.preventDefault();
		}
	}

	function handle_outside_click(event: MouseEvent) {
		if (onOutsideClick) {
			onOutsideClick(event);
		}
		if (!closeOnOutsideClick) {
			event.preventDefault();
		}
	}

	function handle_open_change(new_open: boolean) {
		open = new_open;
		if (onOpenChange) {
			onOpenChange(new_open);
		}
	}
</script>

<Dialog.Root {open} onOpenChange={handle_open_change}>
	<Dialog.Portal>
		<Dialog.Overlay
			class="data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0 fixed inset-0 z-50 bg-black/80"
		/>
		<Dialog.Content
			class={modal_classes}
			onEscapeKeydown={handle_escape_keydown}
			onInteractOutside={handle_outside_click}
		>
			{#if header}
				{@render header()}
			{:else if title || description}
				<div class="flex flex-col space-y-1.5 text-center sm:text-left">
					{#if title}
						<Dialog.Title
							class="text-lg leading-none font-semibold tracking-tight text-gray-900 dark:text-gray-100"
						>
							{title}
						</Dialog.Title>
					{/if}
					{#if description}
						<Dialog.Description class="text-sm text-gray-500 dark:text-gray-400">
							{description}
						</Dialog.Description>
					{/if}
				</div>
			{/if}

			{#if content}
				{@render content()}
			{:else if children}
				{@render children()}
			{/if}

			{#if footer}
				{@render footer()}
			{/if}
		</Dialog.Content>
	</Dialog.Portal>
</Dialog.Root>
