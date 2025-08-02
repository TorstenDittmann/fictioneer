<script lang="ts">
	import { projects } from '$lib/state/projects.svelte.js';
	import { goto } from '$app/navigation';

	let { isVisible = true }: { isVisible?: boolean } = $props();

	// State for expanded chapters - use array instead of Set for better reactivity
	let expandedChapters = $state<string[]>([]);

	// Auto-expand active chapter and first chapter
	$effect(() => {
		if (projects.activeChapterId && !expandedChapters.includes(projects.activeChapterId)) {
			expandedChapters = [...expandedChapters, projects.activeChapterId];
		}

		// Auto-expand first chapter if we have a project with chapters but no expanded chapters
		if (
			projects.activeProject &&
			projects.activeProject.chapters.length > 0 &&
			expandedChapters.length === 0
		) {
			const firstChapter = projects.activeProject.chapters[0];
			expandedChapters = [firstChapter.id];
			if (!projects.activeChapterId) {
				projects.setActiveChapter(firstChapter.id);
			}
		}
	});

	function toggleChapter(chapterId: string) {
		if (expandedChapters.includes(chapterId)) {
			expandedChapters = expandedChapters.filter((id) => id !== chapterId);
		} else {
			expandedChapters = [...expandedChapters, chapterId];
		}
	}

	function selectScene(sceneId: string) {
		const activeProject = projects.activeProject;
		const activeChapter = projects.activeChapter;
		if (activeProject && activeChapter) {
			goto(`/${activeProject.id}/${activeChapter.id}/${sceneId}`);
		}
	}

	function createChapter() {
		const activeProject = projects.activeProject;
		if (activeProject) {
			const chapterId = projects.createChapter(activeProject.id);
			expandedChapters = [...expandedChapters, chapterId];

			// Create first scene and navigate to it
			const sceneId = projects.createScene(activeProject.id, chapterId);
			goto(`/${activeProject.id}/${chapterId}/${sceneId}`);
		}
	}

	function createScene() {
		const activeProject = projects.activeProject;
		const activeChapter = projects.activeChapter;
		if (activeProject && activeChapter) {
			const sceneId = projects.createScene(activeProject.id, activeChapter.id);
			goto(`/${activeProject.id}/${activeChapter.id}/${sceneId}`);
		}
	}

	function formatWordCount(count: number): string {
		if (count === 0) return '0';
		if (count < 1000) return `${count}`;
		return `${(count / 1000).toFixed(1)}k`;
	}
</script>

<aside
	class="sidebar flex h-full flex-col border-r border-gray-200 bg-white transition-all duration-300 ease-in-out dark:border-gray-700 dark:bg-gray-900"
	class:hidden={!isVisible}
	class:w-64={isVisible}
	class:w-0={!isVisible}
>
	<!-- Header -->
	<div class="border-b border-gray-200 p-3 dark:border-gray-700">
		{#if projects.activeProject}
			<div class="flex items-center justify-between">
				<h2 class="truncate text-sm font-medium text-gray-900 dark:text-gray-100">
					{projects.activeProject.title}
				</h2>
				<button
					onclick={createChapter}
					class="text-xs text-gray-600 hover:text-gray-800 dark:text-gray-300 dark:hover:text-gray-100"
					title="New chapter"
				>
					+ Chapter
				</button>
			</div>
			{#if true}
				{@const projectStats = projects.getProjectStats(projects.activeProject.id)}
				<div class="mt-1 text-xs text-gray-600 dark:text-gray-300">
					{formatWordCount(projectStats.totalWords)} words
				</div>
			{/if}
		{:else}
			<div class="text-sm text-gray-700 dark:text-gray-200">No project selected</div>
		{/if}
	</div>

	<!-- Chapters and Scenes -->
	{#if projects.activeProject}
		<div class="flex-1 overflow-y-auto">
			{#each projects.activeProject.chapters as chapter (chapter.id)}
				<!-- Chapter header -->
				<div
					class="flex cursor-pointer items-center px-3 py-2 text-sm transition-colors duration-200 hover:bg-gray-100 dark:hover:bg-gray-700"
					onclick={() => toggleChapter(chapter.id)}
					role="button"
					tabindex="0"
					onkeydown={(e) => e.key === 'Enter' && toggleChapter(chapter.id)}
				>
					<span class="mr-2 text-xs text-gray-600 dark:text-gray-300">
						{expandedChapters.includes(chapter.id) ? '−' : '+'}
					</span>
					<span class="flex-1 truncate font-medium text-gray-900 dark:text-gray-100">
						{chapter.title}
					</span>
					<span class="ml-2 text-xs text-gray-600 dark:text-gray-400">
						{chapter.scenes.length}
					</span>
				</div>

				<!-- Scenes (only show if chapter is expanded) -->
				{#if expandedChapters.includes(chapter.id)}
					{#each chapter.scenes as scene (scene.id)}
						<div
							class="cursor-pointer px-6 py-2 text-sm transition-colors duration-200 hover:bg-gray-100 dark:hover:bg-gray-700"
							class:bg-gray-100={projects.activeSceneId === scene.id}
							class:dark:bg-gray-600={projects.activeSceneId === scene.id}
							onclick={(e) => {
								e.stopPropagation();
								selectScene(scene.id);
							}}
							role="button"
							tabindex="0"
							onkeydown={(e) => e.key === 'Enter' && selectScene(scene.id)}
						>
							<div class="flex items-center justify-between">
								<span class="truncate text-gray-900 dark:text-gray-100">
									{scene.title}
								</span>
								<span class="ml-2 text-xs text-gray-600 dark:text-gray-400">
									{formatWordCount(scene.wordCount)}
								</span>
							</div>
						</div>
					{/each}

					<!-- Add scene -->
					<div
						class="cursor-pointer px-6 py-2 text-sm transition-colors duration-200 hover:bg-gray-100 dark:hover:bg-gray-700"
						onclick={(e) => {
							e.stopPropagation();
							createScene();
						}}
						role="button"
						tabindex="0"
						onkeydown={(e) => e.key === 'Enter' && createScene()}
					>
						<span class="text-gray-600 italic dark:text-gray-300"> + add scene </span>
					</div>
				{/if}
			{/each}

			<!-- Add chapter -->
			<div
				class="cursor-pointer px-3 py-2 text-sm transition-colors duration-200 hover:bg-gray-100 dark:hover:bg-gray-700"
				onclick={createChapter}
				role="button"
				tabindex="0"
				onkeydown={(e) => e.key === 'Enter' && createChapter()}
			>
				<span class="text-gray-600 italic dark:text-gray-300"> + add chapter </span>
			</div>
		</div>
	{/if}

	<!-- Footer -->
	<div class="border-t border-gray-200 p-3 dark:border-gray-700">
		<button
			onclick={() => projects.toggleDistractionFree()}
			class="w-full py-2 text-xs text-gray-600 hover:text-gray-800 dark:text-gray-400 dark:hover:text-gray-200"
		>
			Focus Mode
		</button>
	</div>
</aside>
