<script lang="ts">
	import { browser } from '$app/environment';
	import { projects } from '$lib/state/projects.svelte.js';

	interface Props {
		onToggleSidebar?: () => void;
		isSidebarVisible?: boolean;
		editorStats?: { words: number; characters: number };
	}

	let {
		onToggleSidebar,
		isSidebarVisible = true,
		editorStats = { words: 0, characters: 0 }
	}: Props = $props();

	function formatWordCount(count: number): string {
		if (count === 0) return '0 words';
		if (count === 1) return '1 word';
		if (count < 1000) return `${count} words`;
		return `${(count / 1000).toFixed(1)}k words`;
	}

	function formatCharacterCount(count: number): string {
		if (count < 1000) return `${count} chars`;
		return `${(count / 1000).toFixed(1)}k chars`;
	}

	function updateSceneTitle(event: Event) {
		const target = event.target as HTMLInputElement;
		const activeScene = projects.activeScene;
		const activeChapter = projects.activeChapter;
		const activeProject = projects.activeProject;
		if (activeScene && activeChapter && activeProject && target.value.trim()) {
			projects.updateScene(activeProject.id, activeChapter.id, activeScene.id, {
				title: target.value.trim()
			});
		}
	}

	function handleTitleKeydown(event: KeyboardEvent) {
		if (event.key === 'Enter') {
			(event.target as HTMLInputElement).blur();
		}
	}

	function selectProject(projectId: string) {
		projects.setActiveProject(projectId);
	}

	function createNewProject() {
		projects.createProject();
	}
</script>

<header
	class="header flex min-h-[60px] items-center justify-between border-b border-gray-200 bg-white px-4 py-3 dark:border-gray-700 dark:bg-gray-800"
>
	<!-- Left section -->
	<div class="flex items-center gap-3">
		<!-- Sidebar toggle -->
		<button
			onclick={onToggleSidebar}
			class="rounded-lg p-2 transition-colors duration-200 hover:bg-gray-100 dark:hover:bg-gray-700"
			title={isSidebarVisible ? 'Hide sidebar' : 'Show sidebar'}
		>
			<svg
				class="h-5 w-5 text-gray-600 dark:text-gray-400"
				fill="none"
				stroke="currentColor"
				viewBox="0 0 24 24"
			>
				{#if isSidebarVisible}
					<path
						stroke-linecap="round"
						stroke-linejoin="round"
						stroke-width="2"
						d="M11 19l-7-7 7-7m8 14l-7-7 7-7"
					/>
				{:else}
					<path
						stroke-linecap="round"
						stroke-linejoin="round"
						stroke-width="2"
						d="M13 5l7 7-7 7M5 5l7 7-7 7"
					/>
				{/if}
			</svg>
		</button>

		<!-- Project selector -->
		{#if projects.projects.length > 0}
			<select
				value={projects.activeProjectId || ''}
				onchange={(e) => selectProject((e.target as HTMLSelectElement).value)}
				class="rounded border border-gray-300 bg-transparent px-2 py-1 text-sm text-gray-700 focus:ring-1 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:text-gray-300"
			>
				{#each projects.projects as project (project.id)}
					<option value={project.id}>{project.title}</option>
				{/each}
			</select>
			<button
				onclick={createNewProject}
				class="ml-2 text-xs text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"
				title="New project"
			>
				+ Project
			</button>
		{:else}
			<button
				onclick={createNewProject}
				class="text-sm text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"
			>
				Create Project
			</button>
		{/if}

		<!-- Scene title -->
		{#if projects.activeScene}
			<input
				type="text"
				value={projects.activeScene.title}
				oninput={updateSceneTitle}
				onkeydown={handleTitleKeydown}
				class="border-none bg-transparent text-sm font-medium text-gray-900 focus:outline-none dark:text-gray-100"
				placeholder="Scene title..."
			/>
		{:else}
			<div class="text-sm text-gray-500 dark:text-gray-400">No scene selected</div>
		{/if}
	</div>

	<!-- Center section - Statistics -->
	<div class="hidden items-center gap-4 text-xs text-gray-500 md:flex dark:text-gray-400">
		{#if projects.activeScene}
			<span>{formatWordCount(editorStats.words)} words</span>
			<span>{formatCharacterCount(editorStats.characters)} chars</span>
		{/if}
	</div>

	<!-- Right section -->
	<div class="flex items-center gap-3 text-xs text-gray-600 dark:text-gray-400">
		<!-- Focus mode toggle -->
		<button
			onclick={() => projects.toggleDistractionFree()}
			class="hover:text-gray-800 dark:hover:text-gray-200"
			class:text-blue-600={projects.isDistractionFree}
			class:dark:text-blue-400={projects.isDistractionFree}
			title="Toggle focus mode"
		>
			Focus
		</button>

		<!-- Theme toggle -->
		<button
			onclick={() => {
				const html = document.documentElement;
				html.classList.toggle('dark');
				localStorage.setItem('theme', html.classList.contains('dark') ? 'dark' : 'light');
			}}
			class="hover:text-gray-800 dark:hover:text-gray-200"
			title="Toggle theme"
		>
			{browser ? (document.documentElement.classList.contains('dark') ? 'Light' : 'Dark') : 'Theme'}
		</button>
	</div>
</header>

<!-- Mobile stats bar -->
<div class="border-b border-gray-200 px-4 py-1 md:hidden dark:border-gray-700">
	{#if projects.activeScene}
		<div class="flex items-center gap-4 text-xs text-gray-500 dark:text-gray-400">
			<span>{formatWordCount(editorStats.words)} words</span>
			<span>{formatCharacterCount(editorStats.characters)} chars</span>
		</div>
	{/if}
</div>
