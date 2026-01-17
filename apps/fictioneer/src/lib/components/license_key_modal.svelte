<script lang="ts">
	import { openUrl } from '@tauri-apps/plugin-opener';
	import { license_key_state } from '$lib/state/license_key.svelte.js';
	import { license_key_service } from '$lib/services/license_key.js';
	import Modal from '$lib/components/ui/modal.svelte';
	import { onMount } from 'svelte';

	interface Props {
		open?: boolean;
		onOpenChange?: (open: boolean) => void;
	}

	let { open = $bindable(false), onOpenChange }: Props = $props();

	let license_key_input = $state('');
	let is_verifying = $state(false);
	let verification_error = $state<string | null>(null);

	onMount(async () => {
		await license_key_state.initialize();
		license_key_input = license_key_state.license_key || '';
	});

	function open_account() {
		openUrl('https://fictioneer.app/account');
	}

	function close_modal() {
		open = false;
		onOpenChange?.(false);
	}

	async function save_license_key() {
		if (is_verifying) return;

		const key = license_key_input.trim();
		if (!key) return;

		is_verifying = true;
		verification_error = null;

		try {
			// Verify first without saving
			const result = await license_key_service.verify_license_key(key);

			if (result.is_valid) {
				// Only save if valid
				await license_key_state.set_license_key(key);
				close_modal();
			} else {
				verification_error = result.error || 'Invalid license key';
			}
		} catch {
			verification_error = 'Verification failed';
		} finally {
			is_verifying = false;
		}
	}

	function remove_license_key() {
		license_key_state.remove_license_key();
		license_key_input = '';
		verification_error = null;
		close_modal();
	}

	function handle_keydown(event: KeyboardEvent) {
		if (event.key === 'Enter' && !event.shiftKey) {
			event.preventDefault();
			save_license_key();
		}
	}

	function handle_input() {
		// Clear error when user types
		verification_error = null;
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
					oninput={handle_input}
					class="flex h-10 w-full rounded-md border px-3 py-2 text-sm focus:ring-2 focus:ring-offset-2 focus:outline-none"
					style="background-color: var(--paper-white); border-color: var(--paper-border); color: var(--paper-text); focus:ring-color: var(--paper-accent);"
					disabled={is_verifying}
				/>
			</div>

			{#if verification_error}
				<div
					class="rounded-md bg-red-50 p-3 text-sm"
					style="border: 1px solid #ef4444; color: #991b1b;"
				>
					✗ {verification_error}
				</div>
			{/if}

			{#if license_key_state.is_valid && !verification_error}
				<div
					class="rounded-md bg-green-50 p-3 text-sm"
					style="border: 1px solid #10b981; color: #065f46;"
				>
					✓ License key is valid
				</div>
			{/if}

			{#if is_verifying}
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
						disabled={is_verifying}
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
					disabled={is_verifying}
				>
					Cancel
				</button>
				<button
					onclick={save_license_key}
					class="inline-flex h-10 items-center justify-center rounded-md px-4 py-2 text-sm font-medium transition-colors hover:opacity-90 focus:ring-2 focus:ring-offset-2 focus:outline-none"
					style="background-color: var(--paper-accent); color: white;"
					disabled={is_verifying || !license_key_input.trim()}
				>
					{#if is_verifying}
						Verifying...
					{:else}
						Save License Key
					{/if}
				</button>
			</div>
		</div>

		<p class="text-center text-sm" style="color: var(--paper-text-muted);">
			<button
				onclick={open_account}
				class="underline transition-colors hover:opacity-80"
				style="color: var(--paper-accent);"
			>
				Manage your account
			</button>
		</p>
	</div>
</Modal>
