<script lang="ts">
	import { Modal, Button } from '$lib/components/ui';

	interface Props {
		open: boolean;
		is_saving?: boolean;
		onSave?: () => void | Promise<void>;
		onDiscard?: () => void;
		onCancel?: () => void;
	}

	let { open = $bindable(), is_saving = false, onSave, onDiscard, onCancel }: Props = $props();

	async function handle_save() {
		if (onSave) {
			await onSave();
		}
		open = false;
	}

	function handle_discard() {
		if (onDiscard) {
			onDiscard();
		}
		open = false;
	}

	function handle_cancel() {
		if (onCancel) {
			onCancel();
		}
		open = false;
	}
</script>

<Modal
	bind:open
	title="Unsaved Changes"
	description="You have unsaved changes. What would you like to do?"
>
	{#snippet footer()}
		<div class="flex flex-col-reverse sm:flex-row sm:justify-end sm:space-x-2">
			<Button variant="secondary" onclick={handle_cancel} disabled={is_saving}>Cancel</Button>
			<Button variant="destructive" onclick={handle_discard} disabled={is_saving}>
				Don't Save
			</Button>
			<Button variant="primary" onclick={handle_save} disabled={is_saving} loading={is_saving}>
				{#if is_saving}
					Saving...
				{:else}
					Save
				{/if}
			</Button>
		</div>
	{/snippet}
</Modal>
