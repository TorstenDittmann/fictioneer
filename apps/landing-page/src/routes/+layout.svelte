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

	onMount(() => {
		if (data.theme) {
			theme.set(data.theme);
		} else {
			theme.set(prefersDark.current ? 'dark' : 'light');
		}
	});

	const json_ld = $derived(
		JSON.stringify({
			'@context': 'https://schema.org',
			'@graph': [
				{
					'@type': 'Organization',
					name: 'Fictioneer',
					url: 'https://fictioneer.app',
					logo: 'https://fictioneer.app/logo.svg',
					description: 'Distraction-free writing software for novelists with AI-powered assistance',
					foundingDate: '2024',
					sameAs: []
				},
				{
					'@type': 'WebSite',
					name: 'Fictioneer',
					url: 'https://fictioneer.app',
					description: 'Distraction-free writing software for novelists with AI-powered assistance'
				}
			]
		})
	);
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

	<!-- Structured Data -->
	<!-- eslint-disable-next-line -->
	{@html `${'<'}script type="application/ld+json">${json_ld}</script>`}
</svelte:head>

<div class="relative">
	<!-- Fixed Background -->
	<div class="fixed inset-0 -z-10">
		<div class="absolute inset-0" style:background="var(--gradient-mesh)"></div>
		<div
			class="aurora-blob-subtle fixed top-[10%] left-[10%] h-[500px] w-[500px] rounded-full bg-paper-accent/15"
		></div>
		<div
			class="aurora-blob-subtle fixed top-[40%] right-[5%] h-[400px] w-[400px] rounded-full bg-paper-iris/10"
		></div>
		<div
			class="aurora-blob-subtle fixed bottom-[10%] left-[30%] h-[600px] w-[600px] rounded-full bg-paper-accent-pink/8"
		></div>
	</div>

	<NavigationMenu />
	<main class="pt-20">
		{@render children?.()}
	</main>
	<Footer />
	<FeedbackButton />
</div>
