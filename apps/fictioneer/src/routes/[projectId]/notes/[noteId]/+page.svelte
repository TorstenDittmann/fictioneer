<script lang="ts">
	import { goto } from '$app/navigation';
	import { projects } from '$lib/state/projects.svelte';
	import { Button, Input, IconButton } from '$lib/components/ui';
	import Editor from '$lib/components/editor.svelte';
	import type { PageProps } from './$types';
	import { resolve } from '$app/paths';

	let { params }: PageProps = $props();

	let note_title = $state('');
	let note_description = $state('');
	let is_loading = $state(true);
	let last_saved = $state<Date | null>(null);

	// Find the note
	const note = $derived(projects.notes.find((n) => n.id === params.noteId));

	// Initialize note data
	$effect(() => {
		if (note) {
			note_title = note.title;
			note_description = note.description;
			is_loading = false;
		} else if (!is_loading) {
			// Note not found, redirect to notes list
			goto(
				resolve('/[projectId]/notes', {
					projectId: params.projectId
				})
			);
		}
	});

	function auto_save() {
		if (!note || !note_title.trim()) return;

		try {
			projects.updateNote(note.id, {
				title: note_title.trim(),
				description: note_description
			});
			last_saved = new Date();
		} catch (error) {
			console.error('Failed to save note:', error);
		}
	}

	function handle_editor_update(content: string) {
		note_description = content;
		auto_save();
	}

	function handle_title_change() {
		auto_save();
	}

	function delete_note() {
		if (!note) return;

		if (confirm('Are you sure you want to delete this note?')) {
			try {
				projects.deleteNote(note.id);
				goto(
					resolve('/[projectId]/notes', {
						projectId: params.projectId
					})
				);
			} catch (error) {
				console.error('Failed to delete note:', error);
			}
		}
	}

	function format_last_saved(date: Date): string {
		const now = new Date();
		const diff = now.getTime() - date.getTime();
		const seconds = Math.floor(diff / 1000);
		const minutes = Math.floor(diff / (1000 * 60));

		if (minutes > 0) {
			return `${minutes} minute${minutes > 1 ? 's' : ''} ago`;
		} else if (seconds > 5) {
			return `${seconds} second${seconds > 1 ? 's' : ''} ago`;
		} else {
			return 'Just now';
		}
	}

	// Handle keyboard shortcuts
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

		// Cmd/Ctrl + S to manually save (though auto-save is already active)
		if ((event.metaKey || event.ctrlKey) && event.key === 's') {
			event.preventDefault();
			auto_save();
		}

		// Escape to go back to notes list
		if (event.key === 'Escape') {
			event.preventDefault();
			goto(
				resolve('/[projectId]/notes', {
					projectId: params.projectId
				})
			);
		}
	}
</script>

<svelte:window onkeydown={handle_keydown} />
<svelte:head>
	<title>{note_title || 'Note'} - {projects.project?.title || 'Project'}</title>
</svelte:head>

{#if is_loading}
	<div class="flex h-full items-center justify-center">
		<div class="text-center">
			<div
				class="h-8 w-8 animate-spin rounded-full border-4 border-accent/20 border-t-accent"
			></div>
			<p class="mt-2 text-text-secondary">Loading note...</p>
		</div>
	</div>
{:else if !note}
	<div class="flex h-full items-center justify-center">
		<div class="text-center">
			<h1 class="text-2xl font-bold text-text">Note not found</h1>
			<p class="mt-2 text-text-secondary">The note you're looking for doesn't exist.</p>
			<Button href="/{params.projectId}/notes" class="mt-4">Back to Notes</Button>
		</div>
	</div>
{:else}
	<div class="flex h-full flex-col">
		<!-- Header -->
		<div class="border-b border-border bg-surface px-6 py-4">
			<div class="flex items-center justify-between">
				<div class="flex items-center gap-4">
					<IconButton
						onclick={() =>
							goto(
								resolve('/[projectId]/notes', {
									projectId: params.projectId
								})
							)}
						aria-label="Back to notes"
						class="text-text-muted hover:bg-background-tertiary hover:text-text-secondary"
					>
						<svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
							<path
								stroke-linecap="round"
								stroke-linejoin="round"
								stroke-width="2"
								d="M15 19l-7-7 7-7"
							/>
						</svg>
					</IconButton>
					<div class="flex-1">
						<Input
							bind:value={note_title}
							placeholder="Note title..."
							class="border-none bg-transparent p-0 text-xl font-medium focus:ring-0"
							oninput={handle_title_change}
						/>
					</div>
				</div>
				<div class="flex items-center gap-3">
					{#if last_saved}
						<span class="text-sm text-text-muted">
							Saved {format_last_saved(last_saved)}
						</span>
					{/if}
					<IconButton
						onclick={delete_note}
						aria-label="Delete note"
						class="text-text-muted hover:bg-red-100 hover:text-red-600"
					>
						<svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
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
		</div>

		<!-- Editor -->
		<div class="h-full flex-1 overflow-hidden">
			<Editor
				content={note_description}
				placeholder="Start writing your note..."
				onUpdate={handle_editor_update}
			/>
		</div>
	</div>
{/if}
