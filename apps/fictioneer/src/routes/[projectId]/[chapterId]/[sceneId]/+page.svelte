<script lang="ts">
	import { goto } from '$app/navigation';
	import { resolve } from '$app/paths';
	import { beforeNavigate } from '$app/navigation';
	import { projects } from '$lib/state/projects.svelte';
	import { layout_state } from '$lib/state/layout.svelte';
	import Editor from '$lib/components/editor.svelte';

	import { onMount } from 'svelte';
	import type { PageData } from './$types';

	let { data }: { data: PageData } = $props();

	let editor_component = $state<Editor>();
	let editor_stats = $state({ words: 0, characters: 0 });
	let has_unsaved_changes = $state(false);

	// Update editor stats periodically
	let stats_interval: ReturnType<typeof setInterval>;

	// Auto-save before navigation
	beforeNavigate(() => {
		if (has_unsaved_changes && editor_component) {
			// Trigger a final save
			const content = editor_component.get_content();
			projects.updateScene(data.chapter.id, data.scene.id, {
				content: content
			});
			has_unsaved_changes = false;
		}
	});

	onMount(() => {
		// Update stats every 2 seconds
		stats_interval = setInterval(() => {
			if (editor_component) {
				const stats = editor_component.get_stats();
				editor_stats = { words: stats.words, characters: stats.characters };
			}
		}, 2000);

		return () => {
			if (stats_interval) {
				clearInterval(stats_interval);
			}
		};
	});

	function handle_editor_update(content: string) {
		// Mark as having unsaved changes
		has_unsaved_changes = true;

		// Update the scene content
		projects.updateScene(data.chapter.id, data.scene.id, {
			content: content
		});

		// Update stats immediately on content change
		if (editor_component) {
			const stats = editor_component.get_stats();
			editor_stats = { words: stats.words, characters: stats.characters };
		}

		// Clear the unsaved flag after a successful update
		has_unsaved_changes = false;
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

		// Cmd/Ctrl + N to create new scene
		if ((event.metaKey || event.ctrlKey) && event.key === 'n') {
			event.preventDefault();
			// Save current content before creating new scene
			if (has_unsaved_changes && editor_component) {
				const content = editor_component.get_content();
				projects.updateScene(data.chapter.id, data.scene.id, {
					content: content
				});
				has_unsaved_changes = false;
			}
			const new_scene_id = projects.createScene(data.chapter.id);
			if (new_scene_id) {
				goto(
					resolve('/[projectId]/[chapterId]/[sceneId]', {
						projectId: data.project.id,
						chapterId: data.chapter.id,
						sceneId: new_scene_id
					})
				);
			}
		}
	}
</script>

<svelte:window onkeydown={handle_keydown} />

<!-- Editor area -->
<main class="h-full flex-1 overflow-hidden">
	{#if data.scene}
		{#key data.scene.id}
			<Editor
				bind:this={editor_component}
				content={data.scene.content}
				placeholder="Start writing your scene..."
				onUpdate={handle_editor_update}
				aiContext={{
					title: data.project.title,
					scene_description: data.scene.title
				}}
			/>
		{/key}
	{:else}
		<!-- Loading or error state -->
		<div class="flex h-full items-center justify-center">
			<div class="text-center">
				<div
					class="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-surface"
				>
					<svg
						class="h-8 w-8 text-text-muted"
						fill="none"
						stroke="currentColor"
						viewBox="0 0 24 24"
					>
						<path
							stroke-linecap="round"
							stroke-linejoin="round"
							stroke-width="2"
							d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
						/>
					</svg>
				</div>
				<h3 class="mb-2 text-lg font-medium text-text">Scene not found</h3>
				<p class="mb-4 text-text-secondary">
					The scene you're looking for doesn't exist or has been deleted.
				</p>
			</div>
		</div>
	{/if}
</main>

<!-- Focus mode stats overlay -->
{#if layout_state.is_distraction_free}
	<div class="fixed bottom-4 left-1/2 z-50 -translate-x-1/2 transform">
		<div class="bg-opacity-20 rounded-full bg-black px-4 py-2 text-sm text-white backdrop-blur-sm">
			{editor_stats.words}
			{editor_stats.words === 1 ? 'word' : 'words'} • {editor_stats.characters} characters
		</div>
	</div>
{/if}
