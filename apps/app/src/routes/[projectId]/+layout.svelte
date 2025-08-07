<script lang="ts">
	import { goto } from '$app/navigation';
	import { projects } from '$lib/state/projects.svelte';
	import { layout_state } from '$lib/state/layout.svelte';
	import ProjectSidebar from '$lib/components/project_sidebar.svelte';
	import CommandMenu from '$lib/components/command_menu.svelte';
	import type { Snippet } from 'svelte';
	import type { LayoutData } from './$types';

	let { children, data }: { children: Snippet; data: LayoutData } = $props();

	function create_first_scene() {
		// Create chapter if none exists
		let chapter_id = data.project.chapters[0]?.id;
		if (!chapter_id) {
			chapter_id = projects.createChapter('Chapter 1');
		}

		// Create first scene
		const scene_id = projects.createScene(chapter_id, 'Scene 1');
		if (scene_id) {
			goto(`/${data.project.id}/${chapter_id}/${scene_id}`);
		}
	}

	// Centralized keyboard shortcut handling
	function handle_global_keydown(event: KeyboardEvent) {
		// Cmd/Ctrl + N to create new scene (context-dependent)
		if ((event.metaKey || event.ctrlKey) && event.key === 'n') {
			event.preventDefault();
			create_first_scene();
		}

		// Cmd/Ctrl + K to open command menu
		if ((event.metaKey || event.ctrlKey) && event.key === 'k') {
			event.preventDefault();
			layout_state.open_command_menu();
		}

		// Cmd/Ctrl+F to toggle distraction-free mode (focus mode)
		if ((event.metaKey || event.ctrlKey) && event.key === 'f') {
			event.preventDefault();
			layout_state.toggle_distraction_free();
		}

		// Escape to exit distraction-free mode
		if (event.key === 'Escape' && layout_state.is_distraction_free) {
			event.preventDefault();
			layout_state.is_distraction_free = false;
		}
	}
</script>

<svelte:window onkeydown={handle_global_keydown} />

<div class="app flex h-full flex-col text-gray-900">
	<!-- Main content area -->
	<div class="flex flex-1 overflow-hidden">
		<!-- Sidebar - hidden in distraction free mode -->
		{#if !layout_state.is_distraction_free}
			<ProjectSidebar {data} is_visible={true} />
		{/if}

		<!-- Main content -->
		<main class="flex-1 overflow-hidden">
			{@render children()}
		</main>
	</div>

	<!-- Global Command Menu -->
	<CommandMenu bind:open={layout_state.command_menu_open} />
</div>

<!-- Focus Mode Indicator -->
{#if layout_state.is_distraction_free}
	<div
		class="fixed top-4 right-4 z-50 rounded-lg bg-black/80 px-3 py-2 text-sm text-white backdrop-blur"
	>
		Focus Mode • Press <kbd class="rounded bg-white/20 px-1">Esc</kbd> to exit
	</div>
{/if}
