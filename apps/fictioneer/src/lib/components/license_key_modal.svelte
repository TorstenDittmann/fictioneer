<script lang="ts">
	import { license_key_state } from '$lib/state/license_key.svelte.js';
	import Modal from '$lib/components/ui/modal.svelte';
	import { onMount } from 'svelte';

	interface Props {
		open?: boolean;
		onOpenChange?: (open: boolean) => void;
	}

	let { open = $bindable(false), onOpenChange }: Props = $props();

	let license_key_input = $state('');
	let is_saving = $state(false);

	onMount(async () => {
		await license_key_state.initialize();
		license_key_input = license_key_state.license_key || '';
	});

	function close_modal() {
		open = false;
		onOpenChange?.(false);
	}

	async function save_license_key() {
		if (is_saving) return;

		is_saving = true;
		try {
			await license_key_state.set_license_key(license_key_input.trim() || null);
			if (license_key_state.is_valid) {
				close_modal();
			}
		} finally {
			is_saving = false;
		}
	}

	function remove_license_key() {
		license_key_state.remove_license_key();
		license_key_input = '';
		close_modal();
	}

	function handle_keydown(event: KeyboardEvent) {
		if (event.key === 'Enter' && !event.shiftKey) {
			event.preventDefault();
			save_license_key();
		}
	}
</script>

<Modal bind:open {onOpenChange}>
	<div class="grid gap-4" style="background-color: var(--paper-white);">
		<div>
			<h2
				class="text-lg leading-none font-semibold tracking-tight"
				style="color: var(--paper-text);"
			>
				AI License Key
			</h2>
			<p class="mt-2 text-sm" style="color: var(--paper-text-light);">
				Enter your license key to access AI writing features. You can purchase a license from our
				website.
			</p>
		</div>

		<div class="grid gap-4">
			<div class="grid gap-2">
				<label
					for="license-key"
					class="text-sm leading-none font-medium"
					style="color: var(--paper-text);"
				>
					License Key
				</label>
				<input
					id="license-key"
					type="text"
					placeholder="Enter your license key..."
					bind:value={license_key_input}
					onkeydown={handle_keydown}
					class="flex h-10 w-full rounded-md border px-3 py-2 text-sm focus:ring-2 focus:ring-offset-2 focus:outline-none"
					style="background-color: var(--paper-white); border-color: var(--paper-border); color: var(--paper-text); focus:ring-color: var(--paper-accent);"
					disabled={is_saving || license_key_state.is_verifying}
				/>
			</div>

			{#if license_key_state.verification_result && !license_key_state.is_verifying}
				<div
					class="rounded-md p-3 text-sm"
					class:bg-green-50={license_key_state.is_valid}
					class:bg-red-50={!license_key_state.is_valid}
					style={license_key_state.is_valid
						? 'border: 1px solid #10b981; color: #065f46;'
						: 'border: 1px solid #ef4444; color: #991b1b;'}
				>
					{#if license_key_state.is_valid}
						✓ License key is valid
					{:else}
						✗ {license_key_state.verification_result.error || 'Invalid license key'}
					{/if}
				</div>
			{/if}

			{#if license_key_state.is_verifying}
				<div
					class="rounded-md p-3 text-sm"
					style="background-color: var(--paper-bg-light); border: 1px solid var(--paper-border); color: var(--paper-text-light);"
				>
					Verifying license key...
				</div>
			{/if}
		</div>

		<div class="flex justify-between gap-2">
			<div>
				{#if license_key_state.has_license_key}
					<button
						onclick={remove_license_key}
						class="inline-flex h-10 items-center justify-center rounded-md border px-4 py-2 text-sm font-medium transition-colors hover:opacity-80 focus:ring-2 focus:ring-offset-2 focus:outline-none"
						style="background-color: transparent; border-color: var(--paper-border); color: var(--paper-text-light);"
						disabled={is_saving || license_key_state.is_verifying}
					>
						Remove Key
					</button>
				{/if}
			</div>

			<div class="flex gap-2">
				<button
					onclick={close_modal}
					class="inline-flex h-10 items-center justify-center rounded-md border px-4 py-2 text-sm font-medium transition-colors hover:opacity-80 focus:ring-2 focus:ring-offset-2 focus:outline-none"
					style="background-color: transparent; border-color: var(--paper-border); color: var(--paper-text);"
					disabled={is_saving || license_key_state.is_verifying}
				>
					Cancel
				</button>
				<button
					onclick={save_license_key}
					class="inline-flex h-10 items-center justify-center rounded-md px-4 py-2 text-sm font-medium transition-colors hover:opacity-90 focus:ring-2 focus:ring-offset-2 focus:outline-none"
					style="background-color: var(--paper-accent); color: white;"
					disabled={is_saving || license_key_state.is_verifying || !license_key_input.trim()}
				>
					{#if is_saving || license_key_state.is_verifying}
						Saving...
					{:else}
						Save License Key
					{/if}
				</button>
			</div>
		</div>
	</div>
</Modal>
