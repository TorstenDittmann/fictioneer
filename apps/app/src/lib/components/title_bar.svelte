<script lang="ts">
	import { onMount } from 'svelte';
	import { page } from '$app/state';
	import { projects } from '$lib/state/projects.svelte.js';
	import { getCurrentWindow } from '@tauri-apps/api/window';
	import {
		SignedIn,
		SignedOut,
		SignInButton,
		useClerkContext,
		UserButton
	} from 'svelte-clerk/client';
	import { ai_writing_backend_service } from '$lib/services/ai_writing_backend';

	const ctx = useClerkContext();

	let window_title = $state('Omnia');
	let is_fullscreen = $state(false);
	let show_back_button = $state(false);

	// Update title when page or projects change
	$effect(() => {
		const pathname = page.url.pathname;
		if (pathname === '/') {
			window_title = 'Omnia';
			show_back_button = false;
		} else {
			show_back_button = true;
			const active_project = projects.activeProject;
			const active_scene = projects.activeScene;

			if (active_scene && active_project) {
				window_title = `${active_scene.title} - ${active_project.title} - Omnia`;
			} else if (active_project) {
				window_title = `${active_project.title} - Omnia`;
			} else {
				window_title = 'Omnia';
			}
		}
	});

	$effect(() => {
		ctx.session?.getToken().then((token) => {
			ai_writing_backend_service.set_token(token);
		});
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
	<!-- macOS traffic lights on left - hidden in fullscreen -->
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

		<!-- Back to overview button when not in fullscreen -->
		{#if show_back_button}
			<a href="/" class="back-button" title="Back to Overview">
				<svg
					width="16"
					height="16"
					viewBox="0 0 24 24"
					fill="none"
					stroke="currentColor"
					stroke-width="2"
				>
					<path d="M15 18l-6-6 6-6" />
				</svg>
				Overview
			</a>
		{/if}
	{:else}
		<!-- Back to overview button in fullscreen mode, positioned where traffic lights would be -->
		{#if show_back_button}
			<a href="/" class="back-button fullscreen" title="Back to Overview">
				<svg
					width="16"
					height="16"
					viewBox="0 0 24 24"
					fill="none"
					stroke="currentColor"
					stroke-width="2"
				>
					<path d="M15 18l-6-6 6-6" />
				</svg>
				Overview
			</a>
		{:else}
			<div class="spacer-left"></div>
		{/if}
	{/if}

	<!-- Center title with manual drag -->
	<div class="titlebar-title" data-tauri-drag-region>
		{window_title}
	</div>

	<!-- Right spacer -->
	<div class="spacer"></div>

	<SignedOut>
		<SignInButton mode="modal" />
	</SignedOut>
	<SignedIn>
		<UserButton
			appearance={{
				elements: {
					avatarBox: {
						height: '1rem',
						width: '1rem'
					}
				}
			}}
		/>
	</SignedIn>
</div>

<style>
	.titlebar {
		height: 100%;
		background: var(--paper-white);
		border-bottom: 1px solid var(--paper-border);
		display: flex;
		align-items: center;
		padding: 0 12px;
		user-select: none;
		position: relative;
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
		position: absolute;
		left: 50%;
		transform: translateX(-50%);
		padding: 4px 0;
		width: 100%;
		user-select: none;
		-webkit-user-select: none;
	}

	.spacer {
		flex: 1;
	}

	.spacer-left {
		width: 60px;
	}

	.back-button {
		display: flex;
		align-items: center;
		gap: 4px;
		padding: 4px 8px;
		margin-left: 8px;
		font-size: 12px;
		color: var(--paper-text);
		text-decoration: none;
		border-radius: 4px;
		transition: background-color 0.15s ease;
	}

	.back-button.fullscreen {
		margin-left: 0;
	}

	.back-button:hover {
		background-color: rgba(0, 0, 0, 0.1);
	}

	.back-button svg {
		width: 14px;
		height: 14px;
	}
</style>
