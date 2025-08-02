<script lang="ts">
	import { goto } from '$app/navigation';
	import { projects } from '$lib/state/projects.svelte.js';
	import ProjectSidebar from '$lib/components/ProjectSidebar.svelte';
	import Header from '$lib/components/Header.svelte';
	import { onMount } from 'svelte';

	let { params } = $props<{ params: { projectId: string } }>();

	let isSidebarVisible = $state(true);
	let editorStats = $state({ words: 0, characters: 0 });

	onMount(() => {
		// Set the active project based on URL params
		const { projectId } = params;

		// Find and set the active project
		const project = projects.projects.find((p) => p.id === projectId);
		if (project) {
			projects.setActiveProject(projectId);

			// If project has chapters and scenes, redirect to first scene
			if (project.chapters.length > 0) {
				const firstChapter = project.chapters[0];
				if (firstChapter.scenes.length > 0) {
					const firstScene = firstChapter.scenes[0];
					goto(`/${projectId}/${firstChapter.id}/${firstScene.id}`);
					return;
				}
			}
		} else {
			// Project not found, redirect to home
			goto('/');
		}

		// Initialize theme from localStorage
		const savedTheme = localStorage.getItem('theme');
		if (
			savedTheme === 'dark' ||
			(!savedTheme && window.matchMedia('(prefers-color-scheme: dark)').matches)
		) {
			document.documentElement.classList.add('dark');
		}
	});

	function toggleSidebar() {
		isSidebarVisible = !isSidebarVisible;
	}

	function createFirstScene() {
		const activeProject = projects.activeProject;
		if (!activeProject) return;

		// Create chapter if none exists
		let chapterId = activeProject.chapters[0]?.id;
		if (!chapterId) {
			chapterId = projects.createChapter(activeProject.id, 'Chapter 1');
		}

		// Create first scene
		const sceneId = projects.createScene(activeProject.id, chapterId, 'Scene 1');
		goto(`/${activeProject.id}/${chapterId}/${sceneId}`);
	}

	// Handle keyboard shortcuts
	function handleKeydown(event: KeyboardEvent) {
		// Cmd/Ctrl + B to toggle sidebar
		if ((event.metaKey || event.ctrlKey) && event.key === 'b') {
			event.preventDefault();
			toggleSidebar();
		}

		// Cmd/Ctrl + N to create new scene
		if ((event.metaKey || event.ctrlKey) && event.key === 'n') {
			event.preventDefault();
			createFirstScene();
		}

		// Cmd/Ctrl + Shift + F to toggle focus mode
		if ((event.metaKey || event.ctrlKey) && event.shiftKey && event.key === 'F') {
			event.preventDefault();
			projects.toggleDistractionFree();
		}

		// ESC to exit focus mode
		if (event.key === 'Escape' && projects.isDistractionFree) {
			projects.setDistractionFree(false);
		}
	}
</script>

<svelte:window onkeydown={handleKeydown} />

<div class="app flex h-screen flex-col bg-white text-gray-900 dark:bg-gray-900 dark:text-gray-100">
	<!-- Header -->
	{#if !projects.isDistractionFree}
		<Header {isSidebarVisible} {editorStats} onToggleSidebar={toggleSidebar} />
	{/if}

	<!-- Main content area -->
	<div class="flex flex-1 overflow-hidden">
		<!-- Sidebar -->
		{#if !projects.isDistractionFree}
			<ProjectSidebar isVisible={isSidebarVisible} />
		{/if}

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
					{#if projects.activeProject}
						<h3 class="mb-2 text-xl font-medium text-gray-900 dark:text-gray-100">
							{projects.activeProject.title}
						</h3>
						<p class="mb-6 text-gray-500 dark:text-gray-400">
							Start writing by creating your first scene
						</p>
						<button
							onclick={createFirstScene}
							class="rounded-lg bg-blue-600 px-6 py-3 text-white transition-colors duration-200 hover:bg-blue-700"
						>
							Create First Scene
						</button>
					{:else}
						<h3 class="mb-2 text-xl font-medium text-gray-900 dark:text-gray-100">
							Project not found
						</h3>
						<p class="mb-6 text-gray-500 dark:text-gray-400">
							The project you're looking for doesn't exist
						</p>
						<button
							onclick={() => goto('/')}
							class="rounded-lg bg-gray-600 px-6 py-3 text-white transition-colors duration-200 hover:bg-gray-700"
						>
							Go Home
						</button>
					{/if}
				</div>
			</div>
		</main>
	</div>
</div>
