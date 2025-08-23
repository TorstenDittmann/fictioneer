<script lang="ts">
	let { show_back_to_overview = true }: { show_back_to_overview?: boolean } = $props();
</script>

<header class="border-b border-border px-6 py-4">
	<div class="mx-auto flex max-w-4xl items-center justify-between">
		<h1 class="text-2xl font-bold">Fictioneer</h1>
		<div class="flex items-center gap-4">
			{#if show_back_to_overview}
				<a href="/" class="text-sm text-text-muted no-underline hover:text-text-secondary">
					← Back to Overview
				</a>
			{/if}
		</div>
	</div>
</header>
