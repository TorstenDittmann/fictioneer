<script lang="ts">
	import { resolve } from '$app/paths';
</script>

<!-- Floating Feedback Button -->
<a
	href={resolve('/contact')}
	class="fixed right-6 bottom-6 z-40 flex h-12 w-12 items-center justify-center rounded-full bg-paper-accent text-white shadow-lg transition-all hover:scale-105 hover:bg-paper-accent/90 focus:ring-2 focus:ring-paper-accent focus:ring-offset-2 focus:outline-none"
	aria-label="Contact us"
>
	<svg
		width="20"
		height="20"
		viewBox="0 0 24 24"
		fill="none"
		stroke="currentColor"
		stroke-width="2"
	>
		<path
			d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v10z"
			stroke-linecap="round"
			stroke-linejoin="round"
		/>
	</svg>
</a>
