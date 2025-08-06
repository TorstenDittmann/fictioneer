<script lang="ts">
	import { goto } from '$app/navigation';
	import { projects } from '$lib/state/projects.svelte';
	import Editor from '$lib/components/editor.svelte';
	import ProjectSidebar from '$lib/components/project_sidebar.svelte';
	import CommandMenu from '$lib/components/command_menu.svelte';

	import { onMount } from 'svelte';
	import type { PageData } from './$types';

	let { data }: { data: PageData } = $props();

	let is_sidebar_visible = $state(true);
	let is_distraction_free = $state(false);
	let editor_component = $state<Editor>();
	let editor_stats = $state({ words: 0, characters: 0 });
	let command_menu_open = $state(false);

	// Update editor stats periodically
	let stats_interval: ReturnType<typeof setInterval>;

	onMount(() => {
		// Initialize theme from localStorage
		const saved_theme = localStorage.getItem('theme');
		if (
			saved_theme === 'dark' ||
			(!saved_theme && window.matchMedia('(prefers-color-scheme: dark)').matches)
		) {
			document.documentElement.classList.add('dark');
		}

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

	function toggle_sidebar() {
		is_sidebar_visible = !is_sidebar_visible;
	}

	function handle_editor_update() {
		// Update stats immediately on content change
		if (editor_component) {
			const stats = editor_component.get_stats();
			editor_stats = { words: stats.words, characters: stats.characters };
		}
	}

	function toggle_distraction_free() {
		is_distraction_free = !is_distraction_free;
	}

	function set_distraction_free(value: boolean) {
		is_distraction_free = value;
	}

	// Handle keyboard shortcuts
	function handle_keydown(event: KeyboardEvent) {
		// Cmd/Ctrl + B to toggle sidebar
		if ((event.metaKey || event.ctrlKey) && event.key === 'b') {
			event.preventDefault();
			toggle_sidebar();
		}

		// Cmd/Ctrl + N to create new scene
		if ((event.metaKey || event.ctrlKey) && event.key === 'n') {
			event.preventDefault();
			const new_scene_id = projects.createScene(data.project.id, data.chapter.id);
			if (new_scene_id) {
				goto(`/${data.project.id}/${data.chapter.id}/${new_scene_id}`);
			}
		}

		// Cmd/Ctrl + Shift + F to toggle focus mode
		if ((event.metaKey || event.ctrlKey) && event.shiftKey && event.key === 'F') {
			event.preventDefault();
			toggle_distraction_free();
		}

		// Cmd/Ctrl + K to open command menu
		if ((event.metaKey || event.ctrlKey) && event.key === 'k') {
			event.preventDefault();
			command_menu_open = true;
		}

		// ESC to exit focus mode
		if (event.key === 'Escape' && is_distraction_free) {
			set_distraction_free(false);
		}
	}
</script>

<svelte:window onkeydown={handle_keydown} />

<div class="app flex h-full flex-col text-gray-900 dark:text-gray-100">
	<!-- Main content area -->
	<div class="flex flex-1 overflow-hidden">
		<!-- Sidebar -->
		{#if !is_distraction_free}
			<ProjectSidebar {data} is_visible={is_sidebar_visible} />
		{/if}

		<!-- Editor area -->
		<main class="flex-1 overflow-hidden">
			{#if data.scene}
				{#key data.scene.id}
					<Editor
						bind:this={editor_component}
						content={data.scene.content}
						placeholder="Start writing your scene..."
						onUpdate={handle_editor_update}
						project={data.project}
						chapter={data.chapter}
						scene={data.scene}
					/>
				{/key}
			{:else}
				<!-- Loading or error state -->
				<div class="flex h-full items-center justify-center">
					<div class="text-center">
						<div
							class="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-gray-200 dark:bg-gray-800"
						>
							<svg
								class="h-8 w-8 text-gray-400"
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
						<h3 class="mb-2 text-lg font-medium text-gray-900 dark:text-gray-100">
							Scene not found
						</h3>
						<p class="mb-4 text-gray-500 dark:text-gray-400">
							The scene you're looking for doesn't exist or has been deleted.
						</p>
					</div>
				</div>
			{/if}
		</main>
	</div>

	<!-- Focus mode overlay -->
	{#if is_distraction_free}
		<div class="fixed top-[34px] right-4 z-50">
			<button
				onclick={() => set_distraction_free(false)}
				class="bg-opacity-20 hover:bg-opacity-30 rounded-full bg-black p-3 text-white backdrop-blur-sm transition-colors duration-200"
				title="Exit focus mode (ESC)"
				aria-label="Exit focus mode"
			>
				<svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
					<path
						stroke-linecap="round"
						stroke-linejoin="round"
						stroke-width="2"
						d="M6 18L18 6M6 6l12 12"
					/>
				</svg>
			</button>
		</div>

		<!-- Focus mode stats -->
		<div class="fixed bottom-4 left-1/2 z-50 -translate-x-1/2 transform">
			<div
				class="bg-opacity-20 rounded-full bg-black px-4 py-2 text-sm text-white backdrop-blur-sm"
			>
				{editor_stats.words}
				{editor_stats.words === 1 ? 'word' : 'words'} • {editor_stats.characters} characters
			</div>
		</div>
	{/if}
</div>

<CommandMenu bind:open={command_menu_open} />
