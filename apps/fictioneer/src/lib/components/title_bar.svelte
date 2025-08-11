<script lang="ts">
	import { onMount } from 'svelte';
	import { page } from '$app/state';
	import { projects } from '$lib/state/projects.svelte.js';
	import { getCurrentWindow } from '@tauri-apps/api/window';
	import TitleBarUpdateButton from './title_bar_update_button.svelte';

	let is_fullscreen = $state(false);
	const show_back_button = $derived(page.route.id?.startsWith('/[projectId]'));

	// Get the display title from file service
	const window_title = $derived(() => {
		const pathname = page.url.pathname;
		if (pathname === '/') {
			return 'Fictioneer';
		}
		if (projects.hasProject) {
			return projects.fileStatus.display_title;
		}
		return 'Fictioneer';
	});

	onMount(async () => {
		const app_window = getCurrentWindow();
		is_fullscreen = await app_window.isFullscreen();

		// Listen for fullscreen changes
		await app_window.listen('tauri://resize', async () => {
			is_fullscreen = await app_window.isFullscreen();
		});
	});

	function handle_minimize() {
		getCurrentWindow().minimize();
	}

	async function handle_maximize() {
		const app_window = getCurrentWindow();
		const new_fullscreen_state = !(await app_window.isFullscreen());
		await app_window.setFullscreen(new_fullscreen_state);
	}

	function handle_close() {
		getCurrentWindow().close();
	}
</script>

<div class="titlebar" style="grid-area: titlebar;">
	<!-- Left section -->
	<div class="titlebar-left">
		{#if !is_fullscreen}
			<div class="controls">
				<button
					class="control-button close"
					onclick={handle_close}
					type="button"
					aria-label="Close window"
				></button>
				<button
					class="control-button minimize"
					onclick={handle_minimize}
					type="button"
					aria-label="Minimize window"
				></button>
				<button
					class="control-button maximize"
					onclick={handle_maximize}
					type="button"
					aria-label="Toggle fullscreen"
				></button>
			</div>

			{#if show_back_button}
				<a
					href="/"
					class="flex items-center gap-1 rounded-sm border border-gray-600 bg-transparent px-1.5 py-0.5 text-[10px] text-gray-300 transition-all duration-150 hover:border-blue-500 hover:bg-gray-700"
					title="Back to Overview"
				>
					<svg
						width="12"
						height="12"
						viewBox="0 0 24 24"
						fill="none"
						stroke="currentColor"
						stroke-width="2"
						class="flex-shrink-0"
					>
						<path d="M15 18l-6-6 6-6" />
					</svg>
					<span class="whitespace-nowrap">Overview</span>
				</a>
			{/if}
		{:else if show_back_button}
			<a
				href="/"
				class="flex items-center gap-1 rounded-sm border border-gray-600 bg-transparent px-1.5 py-0.5 text-[10px] text-gray-300 transition-all duration-150 hover:border-blue-500 hover:bg-gray-700"
				title="Back to Overview"
			>
				<svg
					width="12"
					height="12"
					viewBox="0 0 24 24"
					fill="none"
					stroke="currentColor"
					stroke-width="2"
					class="flex-shrink-0"
				>
					<path d="M15 18l-6-6 6-6" />
				</svg>
				<span class="whitespace-nowrap">Overview</span>
			</a>
		{/if}
		<TitleBarUpdateButton />
	</div>

	<!-- Center section -->
	<div class="titlebar-center" data-tauri-drag-region>
		{window_title()}
	</div>

	<!-- Right section -->
	<div class="titlebar-right"></div>
</div>

<style>
	.titlebar {
		height: 100%;
		border-bottom: 1px solid var(--paper-border);
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding: 0 12px;
		user-select: none;
		cursor: default;
	}

	.titlebar-left {
		display: flex;
		align-items: center;
		gap: 8px;
		min-width: 150px;
	}

	.titlebar-center {
		flex: 1;
		display: flex;
		align-items: center;
		justify-content: center;
		font-size: 13px;
		font-weight: 500;
		color: var(--paper-text);
		padding: 4px 0;
		user-select: none;
		-webkit-user-select: none;
	}

	.titlebar-right {
		display: flex;
		align-items: center;
		justify-content: flex-end;
		min-width: 150px;
	}

	.controls {
		display: flex;
		gap: 8px;
		align-items: center;
	}

	.control-button {
		width: 12px;
		height: 12px;
		border-radius: 50%;
		border: none;
		transition: all 0.15s ease;
	}

	.close {
		background-color: #ff5f56;
	}

	.close:hover {
		background-color: #ff3b30;
	}

	.minimize {
		background-color: #ffbd2e;
	}

	.minimize:hover {
		background-color: #ff9500;
	}

	.maximize {
		background-color: #27ca3f;
	}

	.maximize:hover {
		background-color: #00ca4e;
	}
</style>
