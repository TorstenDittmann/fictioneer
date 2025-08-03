<script lang="ts">
	import '../app.css';
	import '@fontsource/libre-baskerville/400.css';
	import '@fontsource/libre-baskerville/700.css';
	import '@fontsource/libre-baskerville/400-italic.css';
	import favicon from '$lib/assets/favicon.svg';
	import TitleBar from '$lib/components/TitleBar.svelte';
	import { theme } from '$lib/state/theme.svelte';
	import { ClerkProvider } from 'svelte-clerk/client';
	import type { Snippet } from 'svelte';
	import { PUBLIC_CLERK_PUBLISHABLE_KEY } from '$env/static/public';
	import { dark } from '@clerk/themes';

	let { children }: { children: Snippet } = $props();

	// Set up theme reactivity
	theme.setup_reactivity();
</script>

<svelte:head>
	<title>Omnia - Creative Writing Tool</title>
	<meta
		name="description"
		content="A minimalist creative writing tool for distraction-free writing"
	/>
	<meta name="viewport" content="width=device-width, initial-scale=1" />
	<link rel="icon" href={favicon} />
</svelte:head>

<ClerkProvider
	publishableKey={PUBLIC_CLERK_PUBLISHABLE_KEY}
	appearance={{ theme: theme.current_theme === 'light' ? undefined : dark }}
>
	<div class="app-grid">
		<TitleBar />
		<div class="content-area">
			{@render children?.()}
		</div>
	</div>
</ClerkProvider>

<style>
	.app-grid {
		display: grid;
		grid-template-areas:
			'titlebar'
			'content';
		grid-template-rows: 30px 1fr;
		height: 100vh;
		width: 100vw;
	}

	.content-area {
		grid-area: content;
		height: 100%;
		overflow: hidden;
	}
</style>
