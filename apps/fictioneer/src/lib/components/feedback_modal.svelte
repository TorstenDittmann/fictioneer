<script lang="ts">
	import Modal from './ui/modal.svelte';
	import Button from './ui/button.svelte';

	let { open = $bindable(false) }: { open: boolean } = $props();
</script>

<Modal bind:open>
	<div class="space-y-4">
		<div>
			<h2 class="text-lg font-semibold text-text">Send Feedback</h2>
			<p class="text-sm text-text-secondary">We'd love to hear from you</p>
		</div>

		<p class="text-text">
			To send feedback, report a bug, or request a feature, please email us at:
		</p>

		<a
			href="mailto:support@fictioneer.app"
			class="block rounded-lg border border-border bg-surface p-4 text-center font-medium text-accent transition-colors hover:border-accent hover:bg-surface-hover"
		>
			support@fictioneer.app
		</a>

		<div class="flex justify-end pt-2">
			<Button variant="ghost" onclick={() => (open = false)}>Close</Button>
		</div>
	</div>
</Modal>
