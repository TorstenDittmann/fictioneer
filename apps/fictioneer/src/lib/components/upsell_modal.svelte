<script lang="ts">
	import { openUrl } from '@tauri-apps/plugin-opener';
	import Modal from './ui/modal.svelte';
	import Button from './ui/button.svelte';
	import SettingsModal from './settings_modal.svelte';

	interface Props {
		open?: boolean;
		onOpenChange?: (open: boolean) => void;
	}

	let { open = $bindable(false), onOpenChange }: Props = $props();

	let settings_modal_open = $state(false);

	const features = [
		'Everything in Free',
		'Advanced AI assistance',
		'Unlimited AI generations',
		'Priority support',
		'Early access to new features'
	];

	function close_modal() {
		open = false;
		onOpenChange?.(false);
	}

	function open_checkout() {
		openUrl('https://fictioneer.app/checkout');
	}

	function open_license_settings() {
		close_modal();
		settings_modal_open = true;
	}
</script>

<Modal bind:open {onOpenChange}>
	<div class="space-y-6">
		<!-- Header -->
		<div class="text-center">
			<div
				class="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-full bg-accent/10"
			>
				<svg class="h-6 w-6 text-accent" fill="none" stroke="currentColor" viewBox="0 0 24 24">
					<path
						stroke-linecap="round"
						stroke-linejoin="round"
						stroke-width="2"
						d="M13 10V3L4 14h7v7l9-11h-7z"
					/>
				</svg>
			</div>
			<h2 class="text-xl font-semibold text-text">Unlock AI Writing Tools</h2>
			<p class="mt-1 text-sm text-text-secondary">
				Supercharge your writing with advanced AI assistance
			</p>
		</div>

		<!-- Pricing -->
		<div class="rounded-lg border border-accent/20 bg-accent/5 p-4 text-center">
			<div class="flex items-baseline justify-center gap-1">
				<span class="text-3xl font-bold text-text">$10</span>
				<span class="text-text-secondary">/ month</span>
			</div>
			<p class="mt-1 text-sm font-medium text-accent">7-day free trial</p>
		</div>

		<!-- Features -->
		<ul class="space-y-3">
			{#each features as feature (feature)}
				<li class="flex items-center gap-3">
					<div
						class="flex h-5 w-5 flex-shrink-0 items-center justify-center rounded-full bg-accent/15 text-accent"
					>
						<svg
							class="h-3 w-3"
							fill="none"
							stroke="currentColor"
							stroke-width="3"
							viewBox="0 0 24 24"
						>
							<path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7" />
						</svg>
					</div>
					<span class="text-sm text-text">{feature}</span>
				</li>
			{/each}
		</ul>

		<!-- Actions -->
		<div class="space-y-3">
			<button
				onclick={open_checkout}
				class="flex w-full items-center justify-center gap-2 rounded-md bg-accent px-4 py-2.5 text-sm font-medium text-text-inverse transition-colors hover:bg-accent-hover"
			>
				Start Free Trial
				<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
					<path
						stroke-linecap="round"
						stroke-linejoin="round"
						stroke-width="2"
						d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"
					/>
				</svg>
			</button>
			<Button variant="ghost" class="w-full" onclick={close_modal}>
				Continue with Free Version
			</Button>
		</div>

		<!-- Footer note -->
		<p class="text-text-tertiary text-center text-xs">
			<button onclick={open_license_settings} class="underline hover:text-text-secondary">
				I already have a license key
			</button>
		</p>
	</div>
</Modal>

<SettingsModal bind:open={settings_modal_open} initial_tab="license" />
