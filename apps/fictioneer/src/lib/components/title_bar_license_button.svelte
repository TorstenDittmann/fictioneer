<script lang="ts">
	import { license_key_state } from '$lib/state/license_key.svelte';
	import LicenseKeyModal from './license_key_modal.svelte';

	let license_key_modal_open = $state(false);

	function open_license_modal() {
		license_key_modal_open = true;
	}

	let button_color = $derived.by((): 'red' | 'amber' | 'green' | 'gray' => {
		if (!license_key_state.is_initialized) return 'gray';
		if (!license_key_state.has_license_key) return 'red';
		if (license_key_state.is_verifying) return 'amber';
		if (!license_key_state.is_valid) return 'red';
		return 'green';
	});

	let tooltip_text = $derived.by(() => {
		if (!license_key_state.is_initialized) return 'AI features loading...';
		if (!license_key_state.has_license_key) return 'No AI license key configured';
		if (license_key_state.is_verifying) return 'Verifying AI license key...';
		if (!license_key_state.is_valid) {
			return license_key_state.verification_result?.error || 'Invalid AI license key';
		}
		return 'AI features enabled';
	});

	let button_styles = $derived.by(() => {
		const colors = {
			red: {
				bg: 'var(--color-surface)',
				border: 'var(--color-border)',
				text: '#dc2626',
				hover: 'var(--color-background-tertiary)'
			},
			amber: {
				bg: 'var(--color-surface)',
				border: 'var(--color-border)',
				text: '#d97706',
				hover: 'var(--color-background-tertiary)'
			},
			green: {
				bg: 'var(--color-surface)',
				border: 'var(--color-border)',
				text: '#16a34a',
				hover: 'var(--color-background-tertiary)'
			},
			gray: {
				bg: 'var(--color-surface)',
				border: 'var(--color-border)',
				text: 'var(--color-text-muted)',
				hover: 'var(--color-background-tertiary)'
			}
		};
		return colors[button_color];
	});
</script>

<button
	onclick={open_license_modal}
	class="flex items-center gap-1 rounded-sm border px-1.5 py-0.5 text-[10px] font-medium transition-all duration-150 hover:bg-background-tertiary"
	style="background-color: {button_styles.bg}; border-color: {button_styles.border}; color: {button_styles.text};"
	title={tooltip_text}
	type="button"
>
	<svg
		width="10"
		height="10"
		viewBox="0 0 24 24"
		fill="none"
		stroke="currentColor"
		stroke-width="2.5"
		class="shrink-0"
	>
		{#if button_color === 'green'}
			<path d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
		{:else if button_color === 'amber'}
			<path
				d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
			/>
		{:else}
			<path
				d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z"
			/>
		{/if}
	</svg>
	<span class="whitespace-nowrap">Pro</span>
</button>

<LicenseKeyModal bind:open={license_key_modal_open} />
