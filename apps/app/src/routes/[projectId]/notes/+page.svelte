<script lang="ts">
	import { page } from '$app/state';
	import { goto } from '$app/navigation';
	import { projects } from '$lib/state/projects.svelte';
	import type { Note } from '$lib/state/projects.svelte';
	import { Button, IconButton } from '$lib/components/ui';

	const project_id = page.params.projectId;
	const notes = $derived(projects.notes);

	function create_new_note() {
		try {
			const note_id = projects.createNote('Untitled Note', '');
			if (note_id) {
				goto(`/${project_id}/notes/${note_id}`);
			}
		} catch (error) {
			console.error('Failed to create note:', error);
		}
	}

	function delete_note(note_id: string, event: MouseEvent) {
		event.stopPropagation(); // Prevent navigation when clicking delete

		if (confirm('Are you sure you want to delete this note?')) {
			try {
				projects.deleteNote(note_id);
			} catch (error) {
				console.error('Failed to delete note:', error);
			}
		}
	}

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

	// Handle page-specific keyboard shortcuts
	function handle_keydown(event: KeyboardEvent) {
		// Skip if user is typing in an input field
		const target = event.target as HTMLElement;
		if (
			target.tagName === 'INPUT' ||
			target.tagName === 'TEXTAREA' ||
			target.contentEditable === 'true'
		) {
			return;
		}

		// Cmd/Ctrl + N to create new note
		if ((event.metaKey || event.ctrlKey) && event.key === 'n') {
			event.preventDefault();
			create_new_note();
		}
	}

	// Handle keyboard navigation for note cards
	function handle_note_keydown(event: KeyboardEvent, note: Note) {
		if (event.key === 'Enter' || event.key === ' ') {
			event.preventDefault();
			goto(`/${project_id}/notes/${note.id}`);
		}
	}
</script>

<svelte:window onkeydown={handle_keydown} />

<div class="h-full overflow-y-auto">
	<div class="mx-auto max-w-6xl p-6">
		<!-- Header -->
		<div class="mb-8">
			<div class="flex items-center justify-between">
				<div>
					<h1 class="text-3xl font-bold text-gray-900">Notes</h1>
					<p class="mt-2 text-gray-600">
						Keep track of ideas, character details, plot points, and more
					</p>
				</div>
				<div class="flex items-center gap-3">
					<Button variant="primary" onclick={create_new_note}>
						<svg class="mr-2 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
							<path
								stroke-linecap="round"
								stroke-linejoin="round"
								stroke-width="2"
								d="M12 4v16m8-8H4"
							/>
						</svg>
						New Note
					</Button>
				</div>
			</div>
		</div>

		<!-- Notes Grid -->
		{#if notes.length === 0}
			<div class="rounded-lg border-2 border-dashed border-gray-300 p-12 text-center">
				<svg
					class="mx-auto h-12 w-12 text-gray-400"
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
				<h3 class="mt-4 text-lg font-medium text-gray-900">No notes yet</h3>
				<p class="mt-2 text-gray-600">Start organizing your thoughts by creating your first note</p>
				<Button variant="secondary" onclick={create_new_note} class="mt-4">
					Create First Note
				</Button>
			</div>
		{:else}
			<div class="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
				{#each notes as note (note.id)}
					<div
						class="group cursor-pointer rounded-lg bg-white p-6 shadow-sm ring-1 ring-gray-200 transition-all duration-200 hover:-translate-y-1 hover:shadow-md"
						role="button"
						tabindex="0"
						onclick={() => goto(`/${project_id}/notes/${note.id}`)}
						onkeydown={(event) => handle_note_keydown(event, note)}
					>
						<div class="flex items-start justify-between">
							<div class="min-w-0 flex-1">
								<h3 class="truncate text-lg font-medium text-gray-900">
									{note.title}
								</h3>
							</div>
							<div
								class="ml-2 flex items-center gap-1 opacity-0 transition-opacity group-hover:opacity-100"
							>
								<IconButton
									onclick={(event: MouseEvent) => delete_note(note.id, event)}
									aria-label="Delete note"
									class="text-gray-400 hover:bg-red-100 hover:text-red-600"
								>
									<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
										<path
											stroke-linecap="round"
											stroke-linejoin="round"
											stroke-width="2"
											d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
										/>
									</svg>
								</IconButton>
							</div>
						</div>

						{#if note.description.trim()}
							<div class="mt-3 line-clamp-4 text-sm text-gray-600">
								{note.description.substring(0, 200)}
								{#if note.description.length > 200}...{/if}
							</div>
						{:else}
							<p class="mt-3 text-sm text-gray-400 italic">No description</p>
						{/if}

						<div class="mt-4 text-xs text-gray-500">
							Updated {format_date(new Date(note.updatedAt))}
						</div>
					</div>
				{/each}
			</div>
		{/if}
	</div>
</div>

<style>
	.line-clamp-4 {
		display: -webkit-box;
		line-clamp: 4;
		-webkit-line-clamp: 4;
		-webkit-box-orient: vertical;
		overflow: hidden;
	}
</style>
