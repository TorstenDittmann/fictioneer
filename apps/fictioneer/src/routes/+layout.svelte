<script lang="ts">
	import '../app.css';
	import '@fontsource/libre-baskerville/400.css';
	import '@fontsource/libre-baskerville/700.css';
	import '@fontsource/libre-baskerville/400-italic.css';
	import favicon from '$lib/assets/favicon.svg';
	import TitleBar from '$lib/components/title_bar.svelte';
	import { projects } from '$lib/state/projects.svelte';
	import { layout_state } from '$lib/state/layout.svelte';
	import { license_key_state } from '$lib/state/license_key.svelte';
	import { ai_writing_backend } from '$lib/state/ai_writing_backend.svelte';
	import type { Snippet } from 'svelte';
	import { blur } from 'svelte/transition';
	import { onMount } from 'svelte';

	let { children }: { children: Snippet } = $props();

	let show_app = $state(false);

	onMount(async () => {
		await license_key_state.initialize();
		await ai_writing_backend.initialize();
		show_app = true;
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
	<meta
		name="description"
		content="A minimalist creative writing tool for distraction-free writing"
	/>
	<meta name="viewport" content="width=device-width, initial-scale=1" />
	<link rel="icon" href={favicon} />
</svelte:head>

{#if show_app}
	<div class="app-wrapper dark" transition:blur={{ duration: 600, amount: 10 }}>
		<div class="app-grid" class:focus-mode={layout_state.is_distraction_free}>
			{#if !layout_state.is_distraction_free}
				<TitleBar />
			{/if}
			<div class="content-area">
				{@render children?.()}
			</div>
		</div>
	</div>
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
		background: var(--paper-white-transparent);
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
