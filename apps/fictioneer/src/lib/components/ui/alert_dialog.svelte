<script lang="ts">
	import { AlertDialog } from 'bits-ui';

	interface Props {
		open?: boolean;
		title?: string;
		description?: string;
		confirmText?: string;
		cancelText?: string;
		destructive?: boolean;
		onConfirm?: () => void;
		onCancel?: () => void;
		onOpenChange?: (open: boolean) => void;
	}

	let {
		open = $bindable(false),
		title = 'Are you sure?',
		description = 'This action cannot be undone.',
		confirmText = 'Continue',
		cancelText = 'Cancel',
		destructive = false,
		onConfirm,
		onCancel,
		onOpenChange
	}: Props = $props();

	function handle_confirm() {
		onConfirm?.();
		open = false;
	}

	function handle_cancel() {
		onCancel?.();
		open = false;
	}

	function handle_open_change(new_open: boolean) {
		open = new_open;
		onOpenChange?.(new_open);
	}
</script>

<AlertDialog.Root bind:open onOpenChange={handle_open_change}>
	<AlertDialog.Portal>
		<AlertDialog.Overlay
			class="data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0 fixed inset-0 z-50 bg-black/50"
		/>
		<AlertDialog.Content
			class="data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0 data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-95 data-[state=closed]:slide-out-to-left-1/2 data-[state=closed]:slide-out-to-top-[48%] data-[state=open]:slide-in-from-left-1/2 data-[state=open]:slide-in-from-top-[48%] fixed top-1/2 left-1/2 z-50 grid w-full max-w-lg -translate-x-1/2 -translate-y-1/2 gap-4 rounded-lg border border-gray-200 bg-white p-6 shadow-lg duration-200 dark:border-gray-800 dark:bg-gray-950"
		>
			<div class="flex flex-col space-y-2 text-center sm:text-left">
				<AlertDialog.Title class="text-lg font-semibold text-gray-900 dark:text-gray-100">
					{title}
				</AlertDialog.Title>
				<AlertDialog.Description class="text-sm text-gray-600 dark:text-gray-400">
					{description}
				</AlertDialog.Description>
			</div>
			<div class="flex flex-col-reverse sm:flex-row sm:justify-end sm:space-x-2">
				<AlertDialog.Cancel
					class="mt-2 inline-flex h-9 items-center justify-center rounded-md border border-gray-200 bg-transparent px-4 py-2 text-sm font-medium text-gray-900 transition-colors hover:bg-gray-100 focus:bg-gray-100 focus:ring-2 focus:ring-gray-400 focus:ring-offset-2 focus:outline-none disabled:cursor-not-allowed disabled:opacity-50 sm:mt-0 dark:border-gray-800 dark:text-gray-100 dark:hover:bg-gray-800 dark:focus:bg-gray-800 dark:focus:ring-gray-600"
					onclick={handle_cancel}
				>
					{cancelText}
				</AlertDialog.Cancel>
				<AlertDialog.Action
					class={`inline-flex h-9 items-center justify-center rounded-md px-4 py-2 text-sm font-medium transition-colors focus:ring-2 focus:ring-offset-2 focus:outline-none disabled:cursor-not-allowed disabled:opacity-50 ${
						destructive
							? 'bg-red-600 text-white hover:bg-red-700 focus:ring-red-500 dark:bg-red-600 dark:hover:bg-red-700'
							: 'bg-gray-900 text-white hover:bg-gray-800 focus:ring-gray-400 dark:bg-gray-100 dark:text-gray-900 dark:hover:bg-gray-200'
					}`}
					onclick={handle_confirm}
				>
					{confirmText}
				</AlertDialog.Action>
			</div>
		</AlertDialog.Content>
	</AlertDialog.Portal>
</AlertDialog.Root>
