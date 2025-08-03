<script lang="ts">
	import { goto } from '$app/navigation';
	import { projects } from '$lib/state/projects.svelte';
	import ProjectSidebar from '$lib/components/project_sidebar.svelte';

	import { onMount } from 'svelte';
	import type { PageData } from './$types';

	let { data }: { data: PageData } = $props();

	let is_sidebar_visible = $state(true);

	onMount(() => {
		// Initialize theme from localStorage
		const saved_theme = localStorage.getItem('theme');
		if (
			saved_theme === 'dark' ||
			(!saved_theme && window.matchMedia('(prefers-color-scheme: dark)').matches)
		) {
			document.documentElement.classList.add('dark');
		}
	});

	function toggle_sidebar() {
		is_sidebar_visible = !is_sidebar_visible;
	}

	function create_first_scene() {
		// Create chapter if none exists
		let chapter_id = data.project.chapters[0]?.id;
		if (!chapter_id) {
			chapter_id = projects.createChapter(data.project.id, 'Chapter 1');
		}

		// Create first scene
		const scene_id = projects.createScene(data.project.id, chapter_id, 'Scene 1');
		if (scene_id) {
			goto(`/${data.project.id}/${chapter_id}/${scene_id}`);
		}
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
			create_first_scene();
		}
	}
</script>

<svelte:window onkeydown={handle_keydown} />

<div class="app flex h-full flex-col bg-white text-gray-900 dark:bg-gray-900 dark:text-gray-100">
	<!-- Main content area -->
	<div class="flex flex-1 overflow-hidden">
		<!-- Sidebar -->
		<ProjectSidebar {data} is_visible={is_sidebar_visible} />

		<!-- Empty state area -->
		<main class="flex-1 overflow-hidden bg-white dark:bg-gray-900">
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
								d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.746 0 3.332.477 4.5 1.253v13C19.832 18.477 18.246 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"
							/>
						</svg>
					</div>
					<h3 class="mb-2 text-xl font-medium text-gray-900 dark:text-gray-100">
						{data.project.title}
					</h3>
					<p class="mb-6 text-gray-500 dark:text-gray-400">
						Start writing by creating your first scene
					</p>
					<button
						onclick={create_first_scene}
						class="rounded-lg bg-blue-600 px-6 py-3 text-white transition-colors duration-200 hover:bg-blue-700"
					>
						Create First Scene
					</button>
				</div>
			</div>
		</main>
	</div>
</div>
