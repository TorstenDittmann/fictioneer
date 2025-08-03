<script lang="ts">
	import { Dialog } from 'bits-ui';

	interface Props {
		open: boolean;
		title: string;
		name: string;
		on_close: () => void;
	}

	let { open = $bindable(), title, name = $bindable(), on_close }: Props = $props();

	let input_element: HTMLInputElement;

	// Focus the input when modal opens
	$effect(() => {
		if (open) {
			// Focus the input after a brief delay to ensure it's rendered
			setTimeout(() => {
				input_element?.focus();
				input_element?.select();
			}, 100);
		}
	});

	function handle_close() {
		on_close();
	}

	function handle_keydown(event: KeyboardEvent) {
		if (event.key === 'Escape') {
			event.preventDefault();
			handle_close();
		}
	}
</script>

<Dialog.Root bind:open>
	<Dialog.Portal>
		<Dialog.Overlay
			class="fixed inset-0 z-50 bg-black/80 data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0"
		/>
		<Dialog.Content
			class="fixed left-[50%] top-[50%] z-50 grid w-full max-w-lg translate-x-[-50%] translate-y-[-50%] gap-4 border bg-white p-6 shadow-lg duration-200 data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0 data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-95 data-[state=closed]:slide-out-to-left-1/2 data-[state=closed]:slide-out-to-top-[48%] data-[state=open]:slide-in-from-left-1/2 data-[state=open]:slide-in-from-top-[48%] sm:rounded-lg dark:border-gray-700 dark:bg-gray-800"
		>
			<div class="flex flex-col space-y-1.5 text-center sm:text-left">
				<Dialog.Title class="text-lg font-semibold leading-none tracking-tight text-gray-900 dark:text-gray-100">
					{title}
				</Dialog.Title>
			</div>

			<div class="grid gap-4 py-4">
				<div class="grid grid-cols-4 items-center gap-4">
					<label for="name" class="text-right text-sm font-medium text-gray-700 dark:text-gray-300">
						Name
					</label>
					<input
						bind:this={input_element}
						bind:value={name}
						onkeydown={handle_keydown}
						id="name"
						type="text"
						class="col-span-3 flex h-10 w-full rounded-md border border-gray-300 bg-white px-3 py-2 text-sm ring-offset-white file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-gray-500 focus:outline-none focus:ring-2 focus:ring-gray-400 focus:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-100 dark:ring-offset-gray-800 dark:placeholder:text-gray-400 dark:focus:ring-gray-600"
						placeholder="Enter name..."
					/>
				</div>
			</div>

			<div class="flex flex-col-reverse sm:flex-row sm:justify-end sm:space-x-2">
				<button
					type="button"
					class="inline-flex h-10 items-center justify-center rounded-md border border-gray-300 bg-transparent px-4 py-2 text-sm font-medium text-gray-700 ring-offset-white transition-colors hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-gray-400 focus:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 dark:border-gray-600 dark:text-gray-300 dark:ring-offset-gray-800 dark:hover:bg-gray-700 dark:focus:ring-gray-600"
					onclick={handle_close}
				>
					Done
				</button>
			</div>
		</Dialog.Content>
	</Dialog.Portal>
</Dialog.Root>