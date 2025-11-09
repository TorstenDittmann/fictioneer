<script lang="ts">
	import '../app.css';
	import logo from '$lib/assets/logo.svg';
	import NavigationMenu from '$lib/components/navigation_menu.svelte';

	let { children } = $props();
</script>

<svelte:head>
	<!-- Favicon -->
	<link rel="icon" type="image/svg+xml" href="/favicon.svg" />

	<!-- Apple Touch Icons -->
	<link rel="apple-touch-icon" sizes="180x180" href={logo} />
	<link rel="apple-touch-icon" sizes="152x152" href={logo} />
	<link rel="apple-touch-icon" sizes="120x120" href={logo} />
	<link rel="apple-touch-icon" sizes="76x76" href={logo} />

	<!-- Mask icon for Safari -->
	<link rel="mask-icon" href={logo} color="#c4a47c" />

	<!-- Microsoft Tiles -->
	<meta name="msapplication-TileColor" content="#2a2621" />
	<meta name="msapplication-TileImage" content={logo} />
</svelte:head>

<NavigationMenu />
{@render children?.()}
