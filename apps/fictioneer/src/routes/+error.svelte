<script lang="ts">
	import { page } from '$app/state';
	import { resolve } from '$app/paths';
	import ErrorHeader from '$lib/components/error_header.svelte';

	function get_error_message(error: unknown): string {
		if (error && typeof error === 'object' && 'message' in error) {
			return String(error.message);
		}
		return 'An unexpected error occurred';
	}

	function get_status_text(status: number): string {
		switch (status) {
			case 404:
				return 'Page Not Found';
			case 500:
				return 'Internal Server Error';
			case 403:
				return 'Forbidden';
			case 401:
				return 'Unauthorized';
			default:
				return 'Error';
		}
	}
</script>

<div class="bg-transparent-paper flex min-h-screen flex-col text-text">
	<!-- Header -->
	<ErrorHeader />

	<!-- Error content -->
	<main class="flex flex-1 items-center justify-center">
		<div class="mx-auto max-w-md text-center">
			<div
				class="mx-auto mb-8 flex h-20 w-20 items-center justify-center rounded-full bg-red-100 dark:bg-red-900"
			>
				<svg
					class="h-10 w-10 text-red-600 dark:text-red-400"
					fill="none"
					stroke="currentColor"
					viewBox="0 0 24 24"
				>
					<path
						stroke-linecap="round"
						stroke-linejoin="round"
						stroke-width="2"
						d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z"
					/>
				</svg>
			</div>

			<h1 class="mb-4 text-4xl font-bold text-text">
				{page.status}
			</h1>

			<h2 class="mb-4 text-xl font-semibold text-text-secondary">
				{get_status_text(page.status)}
			</h2>

			<p class="mb-8 text-text-secondary">
				{get_error_message(page.error)}
			</p>

			<div class="space-y-4">
				<a
					href={resolve('/')}
					class="bg-paper-accent hover:bg-paper-accent-light focus:ring-paper-accent block w-full rounded-lg px-6 py-3 text-center text-white no-underline transition-colors duration-200 focus:ring-2 focus:ring-offset-2 focus:outline-none"
				>
					Go to Overview
				</a>

				<button
					onclick={() => window.history.back()}
					class="w-full rounded-lg border border-border px-6 py-3 text-text-secondary transition-colors duration-200 hover:bg-background-tertiary focus:ring-2 focus:ring-accent focus:ring-offset-2 focus:outline-none"
				>
					Go Back
				</button>
			</div>

			{#if page.status === 404}
				<p class="mt-6 text-sm text-text-muted">
					The page you're looking for might have been moved, deleted, or doesn't exist.
				</p>
			{:else if page.status >= 500}
				<p class="mt-6 text-sm text-text-muted">
					Something went wrong on our end. Please try again later.
				</p>
			{/if}
		</div>
	</main>
</div>
