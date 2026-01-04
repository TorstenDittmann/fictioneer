<script lang="ts">
	import '../app.css';
	import NavigationMenu from '$lib/components/navigation_menu.svelte';
	import Footer from '$lib/components/footer.svelte';
	import FeedbackButton from '$lib/components/feedback_button.svelte';
	import { asset } from '$app/paths';
	import { MediaQuery } from 'svelte/reactivity';
	import { theme } from '$lib/stores/theme.svelte';
	import { onMount } from 'svelte';

	let { children, data } = $props();
	const logo = asset('/logo.svg');

	const prefersDark = new MediaQuery('prefers-color-scheme: dark', false);

	// Initialize theme once on mount
	onMount(() => {
		if (data.theme) {
			theme.set(data.theme);
		} else {
			theme.set(prefersDark.current ? 'dark' : 'light');
		}
	});
</script>

<svelte:head>
	<!-- Favicon -->
	<link rel="icon" type="image/svg+xml" href={logo} />

	<!-- Apple Touch Icons -->
	<link rel="apple-touch-icon" sizes="180x180" href={logo} />
	<link rel="apple-touch-icon" sizes="152x152" href={logo} />
	<link rel="apple-touch-icon" sizes="120x120" href={logo} />
	<link rel="apple-touch-icon" sizes="76x76" href={logo} />

	<!-- Mask icon for Safari -->
	<link rel="mask-icon" href={logo} color="#6366f1" />

	<!-- Microsoft Tiles -->
	<meta name="msapplication-TileColor" content="#6366f1" />
	<meta name="msapplication-TileImage" content={logo} />
</svelte:head>

<NavigationMenu />
<main class="pt-20">
	{@render children?.()}
</main>
<Footer />
<FeedbackButton />
