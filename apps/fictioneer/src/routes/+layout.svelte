<script lang="ts">
	import '../app.css';
	import favicon from '$lib/assets/favicon.svg';
	import TitleBar from '$lib/components/title_bar.svelte';
	import UpsellModal from '$lib/components/upsell_modal.svelte';
	import { projects } from '$lib/state/projects.svelte';
	import { layout_state } from '$lib/state/layout.svelte';
	import { ai_writing_backend } from '$lib/state/ai_writing_backend.svelte';
	import { settings_state } from '$lib/state/settings.svelte';
	import { license_key_state } from '$lib/state/license_key.svelte';
	import { blur } from 'svelte/transition';
	import { onMount } from 'svelte';
	import { MediaQuery } from 'svelte/reactivity';
	import type { LayoutProps } from './$types';

	let { children }: LayoutProps = $props();

	let show_app = $state(false);
	let upsell_modal_open = $state(false);

	const prefers_dark = new MediaQuery('(prefers-color-scheme: dark)');

	// Compute the resolved theme based on settings and system preference
	const resolved_theme = $derived.by(() => {
		const theme = settings_state.settings.theme;
		if (theme === 'system') {
			return prefers_dark.current ? 'dark' : 'light';
		}
		return theme;
	});

	// Apply theme to document
	$effect(() => {
		if (typeof document !== 'undefined') {
			document.documentElement.setAttribute('data-theme', resolved_theme);
		}
	});

	onMount(async () => {
		settings_state.initialize();
		ai_writing_backend.initialize();
		await license_key_state.initialize();

		show_app = true;

		// Show upsell modal if no license key at all
		if (!license_key_state.has_license_key) {
			upsell_modal_open = true;
		}
	});

	// Global keyboard shortcuts
	function handle_keydown(event: KeyboardEvent) {
		if (event.metaKey || event.ctrlKey) {
			switch (event.key) {
				case 'w':
					if (projects.hasProject) {
						event.preventDefault();
						projects.closeProject();
					}
					break;
			}
		}
	}
</script>

<svelte:window onkeydown={handle_keydown} />

<svelte:head>
	<title>Fictioneer - Creative Writing Tool</title>
	<meta name="viewport" content="width=device-width, initial-scale=1" />
	<link rel="icon" href={favicon} />
	<script id="featurebase-sdk" src="https://do.featurebase.app/js/sdk.js"></script>
</svelte:head>

{#if show_app}
	<div class="app-wrapper" transition:blur={{ duration: 600, amount: 10 }}>
		<div class="app-grid" class:focus-mode={layout_state.is_distraction_free}>
			{#if !layout_state.is_distraction_free}
				<TitleBar />
			{/if}
			<div class="content-area">
				{@render children?.()}
			</div>
		</div>
	</div>

	<UpsellModal bind:open={upsell_modal_open} />
{/if}

<style>
	.app-wrapper {
		height: 100vh;
		width: 100vw;
		background: transparent;
		overflow: hidden;
		border-radius: 16px;
	}

	.app-grid {
		display: grid;
		grid-template-areas:
			'titlebar'
			'content';
		grid-template-rows: 30px 1fr;
		height: 100%;
		width: 100%;
		background: var(--color-background-transparent);
		overflow: hidden;
	}

	.app-grid.focus-mode {
		grid-template-areas: 'content';
		grid-template-rows: 1fr;
	}

	.content-area {
		grid-area: content;
		height: 100%;
		overflow: hidden;
	}
</style>
