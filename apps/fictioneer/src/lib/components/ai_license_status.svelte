<script lang="ts">
	import { license_key_state } from '$lib/state/license_key.svelte';

	interface Props {
		show_when_valid?: boolean;
	}

	let { show_when_valid = false }: Props = $props();

	const show_status = $derived(() => {
		if (!license_key_state.is_initialized) return false;
		if (show_when_valid) return license_key_state.has_license_key;
		return !license_key_state.has_license_key || !license_key_state.is_valid;
	});

	const status_text = $derived.by(() => {
		if (!license_key_state.has_license_key) {
			return 'No AI license key';
		}
		if (license_key_state.is_verifying) {
			return 'Verifying license...';
		}
		if (!license_key_state.is_valid) {
			return 'Invalid license key';
		}
		return 'AI enabled';
	});

	const status_color = $derived.by(() => {
		if (!license_key_state.has_license_key || !license_key_state.is_valid) {
			return '#ef4444'; // red
		}
		if (license_key_state.is_verifying) {
			return '#f59e0b'; // amber
		}
		return '#10b981'; // green
	});

	const icon_path = $derived.by(() => {
		if (!license_key_state.has_license_key || !license_key_state.is_valid) {
			return 'M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z';
		}
		if (license_key_state.is_verifying) {
			return 'M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15';
		}
		return 'M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z';
	});
</script>

{#if show_status()}
	<div
		class="flex items-center gap-1.5 rounded-md px-2 py-1 text-xs font-medium transition-colors"
		style="background-color: {status_color}20; color: {status_color}; border: 1px solid {status_color}40;"
		title={license_key_state.verification_result?.error || status_text}
	>
		<svg class="h-3 w-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
			<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d={icon_path} />
		</svg>
		<span>{status_text}</span>
	</div>
{/if}
