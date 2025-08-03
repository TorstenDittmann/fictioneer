<script lang="ts">
	import { goto } from '$app/navigation';
	import { projects } from '$lib/state/projects.svelte';
	import { page } from '$app/state';
	import type { Project } from '$lib/services/projects.js';
	import { theme } from '$lib/state/theme.svelte';

	interface Props {
		data: {
			project: Project;
		};
		is_visible?: boolean;
	}

	let { data, is_visible = true }: Props = $props();

	// Get current IDs from page params
	const current_chapter_id = $derived(page.params.chapterId);
	const current_scene_id = $derived(page.params.sceneId);

	// Note: expanded chapters state is now managed in the projects store

	// Get current project data from state for real-time updates
	const current_project = $derived(() => {
		return projects.projects.find((p) => p.id === data.project.id) || data.project;
	});

	// Helper function to check if a chapter has the active scene
	function is_chapter_active(chapter_id: string): boolean {
		return current_chapter_id === chapter_id && current_scene_id !== null;
	}

	function toggle_chapter(chapter_id: string) {
		projects.toggleChapterExpansion(chapter_id);
	}

	function get_scene_url(chapter_id: string, scene_id: string): string {
		if (data.project) {
			return `/${data.project.id}/${chapter_id}/${scene_id}`;
		}
		return '#';
	}

	function create_chapter() {
		if (data.project) {
			const chapter_id = projects.createChapter(data.project.id);
			if (chapter_id) {
				projects.expandChapter(chapter_id);

				// Create first scene and navigate to it
				const scene_id = projects.createScene(data.project.id, chapter_id);
				if (scene_id) {
					goto(`/${data.project.id}/${chapter_id}/${scene_id}`);
				}
			}
		}
	}

	function create_scene(chapter_id: string) {
		if (data.project) {
			const scene_id = projects.createScene(data.project.id, chapter_id);
			if (scene_id) {
				goto(`/${data.project.id}/${chapter_id}/${scene_id}`);
			}
		}
	}
</script>

<aside
	class="sidebar flex h-full flex-col border-r border-gray-200 bg-white transition-all duration-300 ease-in-out dark:border-gray-700 dark:bg-gray-900"
	class:hidden={!is_visible}
	class:w-72={is_visible}
	class:w-0={!is_visible}
>
	<!-- Header -->
	<div class="border-b border-gray-200 bg-gray-50 p-4 dark:border-gray-700 dark:bg-gray-800">
		<!-- Project Info -->
		<div class="space-y-3">
			<div class="flex items-start justify-between">
				<div class="min-w-0 flex-1">
					<h2 class="truncate text-lg font-semibold text-gray-900 dark:text-gray-100">
						{current_project().title}
					</h2>
				</div>
				<a
					href="/{data.project.id}/settings"
					class="ml-2 inline-flex items-center rounded-md px-2 py-1 text-xs text-gray-600 no-underline transition-colors hover:bg-gray-100 hover:text-gray-800 dark:text-gray-400 dark:hover:bg-gray-700 dark:hover:text-gray-200"
					title="Project settings"
					aria-label="Project settings"
				>
					<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
						<path
							stroke-linecap="round"
							stroke-linejoin="round"
							stroke-width="2"
							d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"
						/>
						<path
							stroke-linecap="round"
							stroke-linejoin="round"
							stroke-width="2"
							d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
						/>
					</svg>
				</a>
			</div>
		</div>
	</div>

	<!-- Chapters and Scenes -->
	<div class="flex-1 overflow-y-auto py-2">
		{#each current_project().chapters as chapter (chapter.id)}
			<div class="mb-1">
				<!-- Chapter header -->
				<button
					class="flex w-full items-center gap-3 border-l-4 px-4 py-3 text-left text-sm font-medium transition-colors duration-200 outline-none focus:shadow-none focus:ring-0 focus:outline-none focus-visible:outline-none active:shadow-none active:ring-0 active:outline-none"
					class:bg-gray-100={is_chapter_active(chapter.id)}
					class:dark:bg-gray-700={is_chapter_active(chapter.id)}
					class:border-gray-400={is_chapter_active(chapter.id)}
					class:dark:border-gray-500={is_chapter_active(chapter.id)}
					class:border-transparent={!is_chapter_active(chapter.id)}
					class:hover:bg-gray-100={!is_chapter_active(chapter.id)}
					class:dark:hover:bg-gray-700={!is_chapter_active(chapter.id)}
					onclick={() => toggle_chapter(chapter.id)}
				>
					<div class="flex h-5 w-5 items-center justify-center">
						<svg
							class="h-3 w-3 text-gray-500 transition-all duration-300 ease-out dark:text-gray-400"
							class:rotate-90={projects.isChapterExpanded(chapter.id)}
							class:text-gray-700={projects.isChapterExpanded(chapter.id) ||
								is_chapter_active(chapter.id)}
							class:dark:text-gray-300={projects.isChapterExpanded(chapter.id) ||
								is_chapter_active(chapter.id)}
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
					<div class="flex min-w-0 flex-1 items-center justify-between">
						<span
							class="truncate text-gray-900 dark:text-gray-100"
							class:font-semibold={is_chapter_active(chapter.id)}
						>
							{chapter.title}
						</span>
						<div class="flex items-center gap-2">
							{#if is_chapter_active(chapter.id)}
								<div class="h-2 w-2 rounded-full bg-gray-600 dark:bg-gray-400"></div>
							{/if}
							<span
								class="rounded-full bg-gray-200 px-2 py-0.5 text-xs font-medium text-gray-700 dark:bg-gray-700 dark:text-gray-300"
							>
								{chapter.scenes.length}
							</span>
						</div>
					</div>
				</button>

				<!-- Scenes (only show if chapter is expanded) -->
				{#if projects.isChapterExpanded(chapter.id)}
					<div class="ml-6 space-y-1 border-l-2 border-gray-200 dark:border-gray-700">
						{#each chapter.scenes as scene (scene.id)}
							<a
								href={get_scene_url(chapter.id, scene.id)}
								class="flex w-full items-center gap-3 border-l-2 border-transparent py-2.5 pr-3 pl-6 text-left text-sm no-underline transition-colors duration-200 outline-none hover:bg-gray-100 focus:shadow-none focus:ring-0 focus:outline-none focus-visible:outline-none active:ring-0 active:outline-none dark:hover:bg-gray-700"
								class:bg-gray-100={current_scene_id === scene.id}
								class:dark:bg-gray-700={current_scene_id === scene.id}
								class:border-gray-400={current_scene_id === scene.id}
								class:dark:border-gray-500={current_scene_id === scene.id}
							>
								<svg
									class="h-3 w-3 flex-shrink-0 text-gray-400"
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
								<span class="truncate font-medium text-gray-900 dark:text-gray-100">
									{scene.title}
								</span>
							</a>
						{/each}

						<!-- Add scene -->
						<button
							class="flex w-full items-center gap-3 border-l-2 border-transparent py-2.5 pr-3 pl-6 text-left text-sm font-medium text-gray-600 transition-colors duration-200 outline-none hover:bg-gray-100 hover:text-gray-800 focus:shadow-none focus:ring-0 focus:outline-none focus-visible:outline-none active:ring-0 active:outline-none dark:text-gray-400 dark:hover:bg-gray-700 dark:hover:text-gray-200"
							onclick={(e) => {
								e.stopPropagation();
								create_scene(chapter.id);
							}}
						>
							<svg
								class="h-3 w-3 flex-shrink-0 text-gray-400"
								fill="none"
								stroke="currentColor"
								viewBox="0 0 24 24"
							>
								<path
									stroke-linecap="round"
									stroke-linejoin="round"
									stroke-width="2"
									d="M12 6v6m0 0v6m0-6h6m-6 0H6"
								/>
							</svg>
							<span class="truncate font-medium text-gray-900 dark:text-gray-100"> Add scene </span>
						</button>
					</div>
				{/if}
			</div>
		{/each}

		<!-- Add chapter -->
		<div class="mx-4 mt-4">
			<button
				class="flex w-full items-center justify-center rounded-lg border-2 border-dashed border-gray-300 px-4 py-3 text-sm font-medium text-gray-600 transition-colors duration-200 hover:border-gray-400 hover:bg-gray-50 hover:text-gray-800 focus:border-gray-500 focus:ring-2 focus:ring-gray-500 focus:ring-offset-2 focus:outline-none dark:border-gray-600 dark:text-gray-400 dark:hover:border-gray-500 dark:hover:bg-gray-800 dark:hover:text-gray-200"
				onclick={create_chapter}
			>
				<svg class="mr-2 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
					<path
						stroke-linecap="round"
						stroke-linejoin="round"
						stroke-width="2"
						d="M12 6v6m0 0v6m0-6h6m-6 0H6"
					/>
				</svg>
				Add chapter
			</button>
		</div>
	</div>

	<!-- Footer -->
	<div class="border-t border-gray-200 bg-gray-50 p-4 dark:border-gray-700 dark:bg-gray-800">
		<div class="space-y-3">
			<!-- Theme toggle -->
			<div class="flex items-center justify-between">
				<span class="text-xs font-medium text-gray-700 dark:text-gray-300">Theme:</span>
				<button
					onclick={() => theme.toggle_theme()}
					class="inline-flex items-center rounded-md px-2 py-1 text-xs text-gray-600 transition-colors hover:bg-gray-100 hover:text-gray-800 dark:text-gray-400 dark:hover:bg-gray-700 dark:hover:text-gray-200"
					title="Current: {theme.current_theme_label}, Click for: {theme.next_theme_label}"
				>
					<svg class="mr-1 h-3 w-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
						<path
							stroke-linecap="round"
							stroke-linejoin="round"
							stroke-width="2"
							d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z"
						/>
					</svg>
					{theme.next_theme_label}
				</button>
			</div>

			<div class="text-xs font-medium text-gray-700 dark:text-gray-300">Keyboard shortcuts:</div>
			<div class="space-y-1 text-xs text-gray-600 dark:text-gray-400">
				<div class="flex justify-between">
					<span>Toggle sidebar</span>
					<kbd class="rounded bg-gray-200 px-1 py-0.5 font-mono text-xs dark:bg-gray-700"
						>Ctrl+B</kbd
					>
				</div>
				<div class="flex justify-between">
					<span>New scene</span>
					<kbd class="rounded bg-gray-200 px-1 py-0.5 font-mono text-xs dark:bg-gray-700"
						>Ctrl+N</kbd
					>
				</div>
			</div>
		</div>
	</div>
</aside>
