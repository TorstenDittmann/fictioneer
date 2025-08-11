<script lang="ts">
	import { projects } from '$lib/state/projects.svelte';

	const recent_notes = $derived(projects.recentNotes);

	function format_date(date: Date): string {
		const now = new Date();
		const diff = now.getTime() - date.getTime();
		const days = Math.floor(diff / (1000 * 60 * 60 * 24));
		const hours = Math.floor(diff / (1000 * 60 * 60));
		const minutes = Math.floor(diff / (1000 * 60));

		if (days > 0) {
			return `${days} day${days > 1 ? 's' : ''} ago`;
		} else if (hours > 0) {
			return `${hours} hour${hours > 1 ? 's' : ''} ago`;
		} else if (minutes > 0) {
			return `${minutes} minute${minutes > 1 ? 's' : ''} ago`;
		} else {
			return 'Just now';
		}
	}

	function get_note_preview(description: string): string {
		if (!description.trim()) return 'No description';
		const text = description.replace(/<[^>]*>/g, '').trim();
		return text.length > 150 ? text.slice(0, 150) + '...' : text;
	}
</script>

<div class="mb-8">
	<div class="mb-6">
		<h2 class="text-xl font-semibold text-gray-900">Recent Notes</h2>
	</div>

	{#if recent_notes.length === 0}
		<div class="rounded-lg border-2 border-dashed border-gray-300 p-8 text-center">
			<svg
				class="mx-auto h-8 w-8 text-gray-400"
				fill="none"
				stroke="currentColor"
				viewBox="0 0 24 24"
			>
				<path
					stroke-linecap="round"
					stroke-linejoin="round"
					stroke-width="2"
					d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
				/>
			</svg>
			<h3 class="mt-2 text-sm font-medium text-gray-900">No notes yet</h3>
			<p class="mt-1 text-sm text-gray-600">Start organizing your thoughts by creating notes</p>
			<a
				href="notes"
				class="bg-paper-accent hover:bg-paper-accent-light focus:ring-paper-accent mt-3 inline-flex items-center justify-center rounded-md px-4 py-2 text-sm font-medium text-white transition-colors focus:ring-2 focus:ring-offset-2 focus:outline-none disabled:opacity-50"
			>
				Create First Note
			</a>
		</div>
	{:else}
		<div class="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
			{#each recent_notes as note (note.id)}
				<button
					onclick={() => (window.location.href = `notes/${note.id}`)}
					class="group rounded-lg bg-white p-6 text-left shadow-sm ring-1 ring-gray-300 transition-all duration-200 hover:-translate-y-1 hover:shadow-md"
				>
					<div class="flex items-start justify-between">
						<div class="min-w-0 flex-1">
							<h3 class="truncate text-lg font-medium text-gray-900 group-hover:text-gray-600">
								{note.title}
							</h3>
						</div>
						<svg
							class="h-5 w-5 flex-shrink-0 text-gray-400 transition-colors group-hover:text-gray-600"
							fill="none"
							stroke="currentColor"
							viewBox="0 0 24 24"
						>
							<path
								stroke-linecap="round"
								stroke-linejoin="round"
								stroke-width="2"
								d="M9 5l7 7-7 7"
							/>
						</svg>
					</div>

					{#if note.description.trim()}
						<p class="mt-3 line-clamp-3 text-sm text-gray-600">
							{get_note_preview(note.description)}
						</p>
					{:else}
						<p class="mt-3 text-sm text-gray-400 italic">No description</p>
					{/if}

					<div class="mt-4 text-xs text-gray-500">
						Updated {format_date(new Date(note.updatedAt))}
					</div>
				</button>
			{/each}
		</div>
	{/if}
</div>

<style>
	.line-clamp-3 {
		display: -webkit-box;
		line-clamp: 3;
		-webkit-line-clamp: 3;
		-webkit-box-orient: vertical;
		overflow: hidden;
	}
</style>
