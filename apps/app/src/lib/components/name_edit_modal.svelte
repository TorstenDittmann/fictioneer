<script lang="ts">
	import { Modal, Input, Button } from '$lib/components/ui';

	interface Props {
		open: boolean;
		title: string;
		name: string;
		on_close: () => void;
	}

	let { open = $bindable(), title, name = $bindable(), on_close }: Props = $props();

	let input_component: Input;

	// Focus the input when modal opens
	$effect(() => {
		if (open) {
			// Focus the input after a brief delay to ensure it's rendered
			setTimeout(() => {
				input_component?.focus();
				input_component?.select();
			}, 100);
		}
	});

	function handle_close() {
		on_close();
	}

	function handle_keydown(event: KeyboardEvent) {
		if (event.key === 'Enter') {
			event.preventDefault();
			handle_close();
		}
	}
</script>

<Modal bind:open {title} onOpenChange={handle_close}>
	{#snippet content()}
		<div class="grid gap-4 py-4">
			<Input
				bind:this={input_component}
				bind:value={name}
				onkeydown={handle_keydown}
				id="name"
				label="Name"
				placeholder="Enter name..."
			/>
		</div>
	{/snippet}

	{#snippet footer()}
		<div class="flex flex-col-reverse sm:flex-row sm:justify-end sm:space-x-2">
			<Button variant="secondary" onclick={handle_close}>Done</Button>
		</div>
	{/snippet}
</Modal>
