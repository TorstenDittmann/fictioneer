<script lang="ts">
	import { goto } from '$app/navigation';
	import { projects } from '$lib/state/projects.svelte.js';
	import Editor from '$lib/components/Editor.svelte';
	import ProjectSidebar from '$lib/components/ProjectSidebar.svelte';
	import Header from '$lib/components/Header.svelte';
	import { onMount } from 'svelte';

	let { params } = $props<{ params: { projectId: string; chapterId: string; sceneId: string } }>();

	let isSidebarVisible = $state(true);
	let editorComponent = $state<Editor>();
	let editorStats = $state({ words: 0, characters: 0 });

	// Update editor stats periodically
	let statsInterval: ReturnType<typeof setInterval>;

	// React to URL changes and sync the active scene
	$effect(() => {
		const { projectId, chapterId, sceneId } = params;

		// Find and set the active project
		const project = projects.projects.find((p) => p.id === projectId);
		if (project) {
			projects.setActiveProject(projectId);

			// Find and set the active chapter
			const chapter = project.chapters.find((c) => c.id === chapterId);
			if (chapter) {
				projects.setActiveChapter(chapterId);

				// Find and set the active scene
				const scene = chapter.scenes.find((s) => s.id === sceneId);
				if (scene) {
					projects.setActiveScene(sceneId);
				} else {
					// Scene not found, redirect to project
					goto(`/${projectId}`);
				}
			} else {
				// Chapter not found, redirect to project
				goto(`/${projectId}`);
			}
		} else {
			// Project not found, redirect to home
			goto('/');
		}
	});

	onMount(() => {
		// Initialize theme from localStorage
		const savedTheme = localStorage.getItem('theme');
		if (
			savedTheme === 'dark' ||
			(!savedTheme && window.matchMedia('(prefers-color-scheme: dark)').matches)
		) {
			document.documentElement.classList.add('dark');
		}

		// Update stats every 2 seconds
		statsInterval = setInterval(() => {
			if (editorComponent) {
				const stats = editorComponent.getStats();
				editorStats = { words: stats.words, characters: stats.characters };
			}
		}, 2000);

		return () => {
			if (statsInterval) {
				clearInterval(statsInterval);
			}
		};
	});

	function toggleSidebar() {
		isSidebarVisible = !isSidebarVisible;
	}

	function handleEditorUpdate() {
		// Update stats immediately on content change
		if (editorComponent) {
			const stats = editorComponent.getStats();
			editorStats = { words: stats.words, characters: stats.characters };
		}
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
			const activeProject = projects.activeProject;
			const activeChapter = projects.activeChapter;
			if (activeProject && activeChapter) {
				const newSceneId = projects.createScene(activeProject.id, activeChapter.id);
				goto(`/${activeProject.id}/${activeChapter.id}/${newSceneId}`);
			}
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

		<!-- Editor area -->
		<main class="flex-1 overflow-hidden bg-white dark:bg-gray-900">
			{#if projects.activeScene}
				{#key projects.activeScene.id}
					<Editor
						bind:this={editorComponent}
						content={projects.activeScene.content}
						placeholder="Start writing your scene..."
						onUpdate={handleEditorUpdate}
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
	{#if projects.isDistractionFree}
		<div class="fixed top-4 right-4 z-50">
			<button
				onclick={() => projects.setDistractionFree(false)}
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
				{editorStats.words}
				{editorStats.words === 1 ? 'word' : 'words'} • {editorStats.characters} characters
			</div>
		</div>
	{/if}
</div>
