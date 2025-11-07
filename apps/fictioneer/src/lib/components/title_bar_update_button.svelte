<script lang="ts">
	import { updater_service } from '$lib/services/updater.svelte.js';
	import { onMount, onDestroy } from 'svelte';

	const update_state = $derived(updater_service.state);

	onMount(() => {
		// Start automatic update checking
		updater_service.start_auto_check();
	});

	onDestroy(() => {
		// Clean up automatic checking
		updater_service.stop_auto_check();
	});

	async function handle_update_click() {
		if (update_state.update_available) {
			await updater_service.download_and_install_update();
		} else {
			await updater_service.check_for_updates();
		}
	}

	const is_disabled = $derived(
		update_state.is_checking || update_state.is_downloading || update_state.is_installing
	);
</script>

{#if update_state.update_available || update_state.is_checking || update_state.is_downloading || update_state.is_installing}
	<button
		onclick={handle_update_click}
		disabled={is_disabled}
		class="relative flex min-h-5 cursor-pointer items-center gap-1 overflow-hidden rounded-sm border border-border bg-transparent px-1.5 py-0.5 text-[10px] text-text-secondary transition-all duration-150
		       hover:border-accent hover:bg-surface disabled:cursor-not-allowed disabled:opacity-60
		       {update_state.update_available ? 'animate-pulse border-accent text-accent' : ''}
		       {update_state.update_available ? 'hover:bg-accent hover:text-text-inverse' : ''}"
		title={update_state.update_available
			? `Update to ${update_state.update_version}`
			: 'Checking for updates...'}
	>
		{#if update_state.is_downloading}
			<div class="absolute inset-0 overflow-hidden rounded-sm bg-surface">
				<div
					class="h-full bg-accent opacity-20 transition-all duration-300"
					style="width: {updater_service.get_download_percentage()}%"
				></div>
			</div>
			<span class="relative z-10 whitespace-nowrap">
				{updater_service.get_download_percentage()}%
			</span>
		{:else if update_state.is_checking || update_state.is_installing}
			<div class="h-2 w-2 animate-spin rounded-full border border-border border-t-accent"></div>
			<span class="whitespace-nowrap">
				{update_state.is_installing ? 'Installing' : 'Checking'}
			</span>
		{:else if update_state.update_available}
			<svg
				width="12"
				height="12"
				viewBox="0 0 24 24"
				fill="none"
				stroke="currentColor"
				stroke-width="2"
				class="shrink-0"
			>
				<path d="M12 2v20M5 12l7-7 7 7" />
			</svg>
			<span class="whitespace-nowrap">Update</span>
		{/if}
	</button>
{/if}
