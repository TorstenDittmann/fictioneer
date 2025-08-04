<script lang="ts">
	import '../app.css';
	import '@fontsource/libre-baskerville/400.css';
	import '@fontsource/libre-baskerville/700.css';
	import '@fontsource/libre-baskerville/400-italic.css';
	import favicon from '$lib/assets/favicon.svg';
	import TitleBar from '$lib/components/title_bar.svelte';
	import { projects } from '$lib/state/projects.svelte';
	import { ClerkProvider } from 'svelte-clerk/client';
	import type { Snippet } from 'svelte';
	import { PUBLIC_CLERK_PUBLISHABLE_KEY } from '$env/static/public';
	import { dark } from '@clerk/themes';

	let { children }: { children: Snippet } = $props();

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
	<title>Omnia - Creative Writing Tool</title>
	<meta
		name="description"
		content="A minimalist creative writing tool for distraction-free writing"
	/>
	<meta name="viewport" content="width=device-width, initial-scale=1" />
	<link rel="icon" href={favicon} />
</svelte:head>

<ClerkProvider publishableKey={PUBLIC_CLERK_PUBLISHABLE_KEY} appearance={{ theme: dark }}>
	<div class="app-wrapper dark">
		<div class="app-grid">
			<TitleBar />
			<div class="content-area">
				{@render children?.()}
			</div>
		</div>
	</div>
</ClerkProvider>

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

	.content-area {
		grid-area: content;
		height: 100%;
		overflow: hidden;
	}
</style>
