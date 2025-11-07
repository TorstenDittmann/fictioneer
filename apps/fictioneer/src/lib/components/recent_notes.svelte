<script lang="ts">
	import { projects } from '$lib/state/projects.svelte';
	import { resolve } from '$app/paths';

	interface Props {
		project_id: string;
	}

	let { project_id }: Props = $props();

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
		<h2 class="text-xl font-semibold text-text">Recent Notes</h2>
	</div>

	{#if recent_notes.length === 0}
		<div class="rounded-lg border-2 border-dashed border-border p-8 text-center">
			<svg
				class="mx-auto h-8 w-8 text-text-muted"
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
			<h3 class="mt-2 text-sm font-medium text-text">No notes yet</h3>
			<p class="mt-1 text-sm text-text-secondary">
				Start organizing your thoughts by creating notes
			</p>
			<a
				href={resolve('/[projectId]/notes', { projectId: project_id })}
				class="mt-3 inline-flex items-center justify-center rounded-md bg-accent px-4 py-2 text-sm font-medium text-text-inverse transition-colors hover:bg-accent-hover focus:ring-2 focus:ring-accent focus:ring-offset-2 focus:outline-none disabled:opacity-50"
			>
				Create First Note
			</a>
		</div>
	{:else}
		<div class="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
			{#each recent_notes as note (note.id)}
				<a
					href={resolve('/[projectId]/notes/[noteId]', {
						projectId: project_id,
						noteId: note.id
					})}
					class="group block rounded-lg bg-background-secondary p-6 text-left no-underline shadow-sm ring-1 ring-border transition-all duration-200 hover:-translate-y-1 hover:shadow-md"
				>
					<div class="flex items-start justify-between">
						<div class="min-w-0 flex-1">
							<h3 class="truncate text-lg font-medium text-text group-hover:text-text-secondary">
								{note.title}
							</h3>
						</div>
						<svg
							class="h-5 w-5 shrink-0 text-text-muted transition-colors group-hover:text-text-secondary"
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
						<p class="mt-3 line-clamp-3 text-sm text-text-secondary">
							{get_note_preview(note.description)}
						</p>
					{:else}
						<p class="mt-3 text-sm text-text-muted italic">No description</p>
					{/if}

					<div class="mt-4 text-xs text-text-muted">
						Updated {format_date(new Date(note.updatedAt))}
					</div>
				</a>
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
