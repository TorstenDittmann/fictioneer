<script lang="ts">
	import { onMount } from 'svelte';
	import { page } from '$app/state';
	import { projects } from '$lib/state/projects.svelte.js';
	import { getCurrentWindow } from '@tauri-apps/api/window';

	let windowTitle = $state('Omnia');
	let isFullscreen = $state(false);

	// Update title when page or projects change
	$effect(() => {
		const pathname = page.url.pathname;
		if (pathname === '/') {
			windowTitle = 'Omnia';
		} else {
			const activeProject = projects.activeProject;
			const activeScene = projects.activeScene;

			if (activeScene && activeProject) {
				windowTitle = `${activeScene.title} - ${activeProject.title} - Omnia`;
			} else if (activeProject) {
				windowTitle = `${activeProject.title} - Omnia`;
			} else {
				windowTitle = 'Omnia';
			}
		}
	});

	onMount(async () => {
		const appWindow = getCurrentWindow();
		isFullscreen = await appWindow.isFullscreen();

		// Listen for fullscreen changes
		await appWindow.listen('tauri://resize', async () => {
			isFullscreen = await appWindow.isFullscreen();
		});
	});

	function handleMinimize() {
		getCurrentWindow().minimize();
	}

	async function handleMaximize() {
		const appWindow = getCurrentWindow();
		const newFullscreenState = !(await appWindow.isFullscreen());
		await appWindow.setFullscreen(newFullscreenState);
	}

	function handleClose() {
		getCurrentWindow().close();
	}
</script>

<div class="titlebar">
	<!-- macOS traffic lights on left - hidden in fullscreen -->
	{#if !isFullscreen}
		<div class="controls">
			<button
				class="control-button close"
				onclick={handleClose}
				type="button"
				aria-label="Close window"
			></button>
			<button
				class="control-button minimize"
				onclick={handleMinimize}
				type="button"
				aria-label="Minimize window"
			></button>
			<button
				class="control-button maximize"
				onclick={handleMaximize}
				type="button"
				aria-label="Toggle fullscreen"
			></button>
		</div>
	{:else}
		<div class="spacer-left"></div>
	{/if}

	<!-- Center title with manual drag -->
	<div class="titlebar-title" data-tauri-drag-region>
		{windowTitle}
	</div>

	<!-- Right spacer -->
	<div class="spacer"></div>
</div>

<style>
	.titlebar {
		height: 30px;
		background: var(--paper-white);
		border-bottom: 1px solid var(--paper-border);
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding: 0 12px;
		position: fixed;
		top: 0;
		left: 0;
		right: 0;
		z-index: 1000;
		user-select: none;
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
		cursor: pointer;
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

	.titlebar-title {
		font-size: 13px;
		font-weight: 500;
		color: var(--paper-text);
		text-align: center;
		flex: 1;
		padding: 4px 0;
	}

	.spacer {
		width: 60px;
	}

	.spacer-left {
		width: 60px;
	}
</style>
