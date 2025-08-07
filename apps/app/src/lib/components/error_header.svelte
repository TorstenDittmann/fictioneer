<script lang="ts">
	let { show_back_to_overview = true }: { show_back_to_overview?: boolean } = $props();
</script>

<header class="border-b border-gray-700 px-6 py-4">
	<div class="mx-auto flex max-w-4xl items-center justify-between">
		<h1 class="text-2xl font-bold">Omnia</h1>
		<div class="flex items-center gap-4">
			{#if show_back_to_overview}
				<a href="/" class="text-sm text-gray-400 no-underline hover:text-gray-300">
					← Back to Overview
				</a>
			{/if}
		</div>
	</div>
</header>
