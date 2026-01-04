<script lang="ts">
	import { onMount } from 'svelte';
	import { page } from '$app/state';
	import { resolve } from '$app/paths';
	import { projects } from '$lib/state/projects.svelte.js';
	import { getCurrentWindow } from '@tauri-apps/api/window';
	import TitleBarUpdateButton from './title_bar_update_button.svelte';
	import SettingsModal from './settings_modal.svelte';
	import FeedbackModal from './feedback_modal.svelte';

	let settings_open = $state(false);
	let feedback_open = $state(false);

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
					href={resolve('/')}
					class="flex items-center gap-1 rounded-sm border border-border bg-transparent px-1.5 py-0.5 text-[10px] text-text-secondary transition-all duration-150 hover:border-accent hover:bg-surface"
					title="Back to Overview"
				>
					<svg
						width="12"
						height="12"
						viewBox="0 0 24 24"
						fill="none"
						stroke="currentColor"
						stroke-width="2"
						class="shrink-0"
					>
						<path d="M15 18l-6-6 6-6" />
					</svg>
					<span class="whitespace-nowrap">Overview</span>
				</a>
			{/if}
		{:else if show_back_button}
			<a
				href={resolve('/')}
				class="flex items-center gap-1 rounded-sm border border-border bg-transparent px-1.5 py-0.5 text-[10px] text-text-secondary transition-all duration-150 hover:border-accent hover:bg-surface"
				title="Back to Overview"
			>
				<svg
					width="12"
					height="12"
					viewBox="0 0 24 24"
					fill="none"
					stroke="currentColor"
					stroke-width="2"
					class="shrink-0"
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
	<div class="titlebar-right gap-1.5">
		<button
			aria-label="Send feedback"
			class="rounded-sm border border-border bg-transparent p-1 text-[10px] text-text-secondary transition-all duration-150 hover:border-accent hover:bg-surface"
			onclick={() => (feedback_open = true)}
			title="Send Feedback"
		>
			<svg
				width="14"
				height="14"
				viewBox="0 0 24 24"
				fill="none"
				stroke="currentColor"
				stroke-width="2"
			>
				<path
					d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v10z"
					stroke-linecap="round"
					stroke-linejoin="round"
				/>
			</svg>
		</button>
		<button
			aria-label="Open settings"
			class="rounded-sm border border-border bg-transparent p-1 text-[10px] text-text-secondary transition-all duration-150 hover:border-accent hover:bg-surface"
			onclick={() => (settings_open = true)}
			title="Settings"
		>
			<svg
				width="14"
				height="14"
				viewBox="0 0 24 24"
				fill="none"
				stroke="currentColor"
				stroke-width="2"
			>
				<path d="M12 15.5a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7Z" />
				<path
					d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 1 1-4 0v-.09a1.65 1.65 0 0 0-1-1.51 1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 1 1 0-4h.09a1.65 1.65 0 0 0 1.51-1 1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33h0A1.65 1.65 0 0 0 9 3.09V3a2 2 0 1 1 4 0v.09c0 .65.39 1.24 1 1.51h0c.59.27 1.28.15 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06c-.48.54-.6 1.23-.33 1.82h0c.27.61.86 1 1.51 1H21a2 2 0 1 1 0 4h-.09c-.65 0-1.24.39-1.51 1Z"
				/>
			</svg>
		</button>
	</div>

	<FeedbackModal bind:open={feedback_open} />
	<SettingsModal bind:open={settings_open} />
</div>

<style>
	.titlebar {
		height: 100%;
		border-bottom: 1px solid var(--color-border);
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
		color: var(--color-text);
		padding: 4px 0;
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
