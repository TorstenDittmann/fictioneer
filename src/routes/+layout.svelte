<script lang="ts">
	import '../app.css';
	import favicon from '$lib/assets/favicon.svg';

	let { children } = $props();
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

{@render children?.()}
