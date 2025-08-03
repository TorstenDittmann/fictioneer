<script lang="ts">
	import { theme } from '$lib/state/theme.svelte';

	let { show_back_to_overview = true }: { show_back_to_overview?: boolean } = $props();
</script>

<header class="border-b border-gray-200 px-6 py-4 dark:border-gray-700">
	<div class="mx-auto flex max-w-4xl items-center justify-between">
		<h1 class="text-2xl font-bold">Omnia</h1>
		<div class="flex items-center gap-4">
			{#if show_back_to_overview}
				<a
					href="/"
					class="text-sm text-blue-600 no-underline hover:text-blue-800 dark:text-blue-400 dark:hover:text-blue-200"
				>
					← Back to Overview
				</a>
			{/if}
			<button
				onclick={() => theme.toggle_theme()}
				class="text-sm text-gray-600 hover:text-gray-800 dark:text-gray-400 dark:hover:text-gray-200"
				title="Current: {theme.current_theme_label}, Click for: {theme.next_theme_label}"
			>
				{theme.current_theme_label}
			</button>
		</div>
	</div>
</header>
