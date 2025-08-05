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
			chapter_id = projects.createChapter('Chapter 1');
		}

		// Create first scene
		const scene_id = projects.createScene(chapter_id, 'Scene 1');
		if (scene_id) {
			goto(`/${data.project.id}/${chapter_id}/${scene_id}`);
		}
	}

	// Get recent scenes and project stats
	const recent_scenes = $derived(projects.recentScenes);
	const project_stats = $derived(projects.getProjectStats());
	const current_project = $derived(projects.project || data.project);

	function navigate_to_scene(chapter_id: string, scene_id: string) {
		goto(`/${data.project.id}/${chapter_id}/${scene_id}`);
	}

	function format_date(date: Date): string {
		const now = new Date();
		const diff = now.getTime() - date.getTime();
		const days = Math.floor(diff / (1000 * 60 * 60 * 24));
		const hours = Math.floor(diff / (1000 * 60 * 60));
		const minutes = Math.floor(diff / (1000 * 60));

		if (days > 0) {
			return `${days} day${days > 1 ? 's' : ''} ago`;
		} else if (hours > 0) {
			return `${hours} hour${hours > 1 ? 's' : ''} ago`;
		} else if (minutes > 0) {
			return `${minutes} minute${minutes > 1 ? 's' : ''} ago`;
		} else {
			return 'Just now';
		}
	}

	function get_scene_preview(content: string): string {
		const text = content.replace(/<[^>]*>/g, '').trim();
		return text.length > 150 ? text.slice(0, 150) + '...' : text;
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

<div class="app flex h-full flex-col text-gray-900 dark:text-gray-100">
	<!-- Main content area -->
	<div class="flex flex-1 overflow-hidden">
		<!-- Sidebar -->
		<ProjectSidebar {data} is_visible={is_sidebar_visible} />

		<!-- Overview content -->
		<main class="flex-1 overflow-hidden">
			<div class="h-full overflow-y-auto">
				<div class="mx-auto max-w-6xl p-6">
					<!-- Header -->
					<div class="mb-8">
						<div class="flex items-center justify-between">
							<div>
								<h1 class="text-3xl font-bold text-gray-900 dark:text-gray-100">
									{current_project.title}
								</h1>
								<p class="mt-2 text-gray-600 dark:text-gray-400">
									{current_project.description || 'Project overview and recent activity'}
								</p>
							</div>
							<button
								onclick={create_first_scene}
								class="rounded-lg bg-blue-600 px-4 py-2 text-white transition-colors duration-200 hover:bg-blue-700"
							>
								New Scene
							</button>
						</div>
					</div>

					<!-- Project Stats -->
					<div class="mb-8 grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
						<div
							class="rounded-lg bg-white p-6 shadow-sm ring-1 ring-gray-200 dark:bg-gray-800 dark:ring-gray-700"
						>
							<div class="flex items-center">
								<div class="flex-shrink-0">
									<svg
										class="h-8 w-8 text-blue-600"
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
								<div class="ml-4">
									<p class="text-sm font-medium text-gray-600 dark:text-gray-400">Total Scenes</p>
									<p class="text-2xl font-semibold text-gray-900 dark:text-gray-100">
										{project_stats.total_scenes}
									</p>
								</div>
							</div>
						</div>

						<div
							class="rounded-lg bg-white p-6 shadow-sm ring-1 ring-gray-200 dark:bg-gray-800 dark:ring-gray-700"
						>
							<div class="flex items-center">
								<div class="flex-shrink-0">
									<svg
										class="h-8 w-8 text-green-600"
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
								<div class="ml-4">
									<p class="text-sm font-medium text-gray-600 dark:text-gray-400">Total Chapters</p>
									<p class="text-2xl font-semibold text-gray-900 dark:text-gray-100">
										{project_stats.total_chapters}
									</p>
								</div>
							</div>
						</div>

						<div
							class="rounded-lg bg-white p-6 shadow-sm ring-1 ring-gray-200 dark:bg-gray-800 dark:ring-gray-700"
						>
							<div class="flex items-center">
								<div class="flex-shrink-0">
									<svg
										class="h-8 w-8 text-purple-600"
										fill="none"
										stroke="currentColor"
										viewBox="0 0 24 24"
									>
										<path
											stroke-linecap="round"
											stroke-linejoin="round"
											stroke-width="2"
											d="M7 4v16l4.586-4.586a2 2 0 012.828 0L19 20V4a2 2 0 00-2-2H9a2 2 0 00-2 2z"
										/>
									</svg>
								</div>
								<div class="ml-4">
									<p class="text-sm font-medium text-gray-600 dark:text-gray-400">Total Words</p>
									<p class="text-2xl font-semibold text-gray-900 dark:text-gray-100">
										{project_stats.total_words.toLocaleString()}
									</p>
								</div>
							</div>
						</div>

						<div
							class="rounded-lg bg-white p-6 shadow-sm ring-1 ring-gray-200 dark:bg-gray-800 dark:ring-gray-700"
						>
							<div class="flex items-center">
								<div class="flex-shrink-0">
									<svg
										class="h-8 w-8 text-orange-600"
										fill="none"
										stroke="currentColor"
										viewBox="0 0 24 24"
									>
										<path
											stroke-linecap="round"
											stroke-linejoin="round"
											stroke-width="2"
											d="M4 7v10c0 2.21 3.582 4 8 4s8-1.79 8-4V7M4 7c0 2.21 3.582 4 8 4s8-1.79 8-4M4 7c0-2.21 3.582-4 8-4s8 1.79 8 4"
										/>
									</svg>
								</div>
								<div class="ml-4">
									<p class="text-sm font-medium text-gray-600 dark:text-gray-400">Characters</p>
									<p class="text-2xl font-semibold text-gray-900 dark:text-gray-100">
										{project_stats.total_characters.toLocaleString()}
									</p>
								</div>
							</div>
						</div>
					</div>

					<!-- Recent Scenes -->
					<div class="mb-8">
						<h2 class="mb-6 text-xl font-semibold text-gray-900 dark:text-gray-100">
							Recently Updated Scenes
						</h2>

						{#if recent_scenes.length === 0}
							<div
								class="rounded-lg border-2 border-dashed border-gray-300 p-12 text-center dark:border-gray-600"
							>
								<svg
									class="mx-auto h-12 w-12 text-gray-400"
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
								<h3 class="mt-4 text-lg font-medium text-gray-900 dark:text-gray-100">
									No scenes yet
								</h3>
								<p class="mt-2 text-gray-600 dark:text-gray-400">
									Start writing by creating your first scene
								</p>
								<button
									onclick={create_first_scene}
									class="mt-4 rounded-lg bg-blue-600 px-6 py-3 text-white transition-colors duration-200 hover:bg-blue-700"
								>
									Create First Scene
								</button>
							</div>
						{:else}
							<div class="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
								{#each recent_scenes as scene (scene.id)}
									<button
										onclick={() => navigate_to_scene(scene.chapter_id, scene.id)}
										class="group rounded-lg bg-white p-6 text-left shadow-sm ring-1 ring-gray-200 transition-all duration-200 hover:-translate-y-1 hover:shadow-md dark:bg-gray-800 dark:ring-gray-700"
									>
										<div class="flex items-start justify-between">
											<div class="min-w-0 flex-1">
												<h3
													class="truncate text-lg font-medium text-gray-900 group-hover:text-blue-600 dark:text-gray-100 dark:group-hover:text-blue-400"
												>
													{scene.title}
												</h3>
												<p class="mt-1 text-sm text-gray-600 dark:text-gray-400">
													{scene.chapter_title}
												</p>
											</div>
											<svg
												class="h-5 w-5 flex-shrink-0 text-gray-400 transition-colors group-hover:text-blue-600 dark:group-hover:text-blue-400"
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

										{#if scene.content.trim()}
											<p class="mt-3 line-clamp-3 text-sm text-gray-600 dark:text-gray-400">
												{get_scene_preview(scene.content)}
											</p>
										{:else}
											<p class="mt-3 text-sm text-gray-400 italic">No content yet...</p>
										{/if}

										<div
											class="mt-4 flex items-center justify-between text-xs text-gray-500 dark:text-gray-400"
										>
											<span>
												{scene.wordCount} words
											</span>
											<span>
												Updated {format_date(new Date(scene.updatedAt))}
											</span>
										</div>
									</button>
								{/each}
							</div>
						{/if}
					</div>
				</div>
			</div>
		</main>
	</div>
</div>

<style>
	.line-clamp-3 {
		display: -webkit-box;
		line-clamp: 3;
		-webkit-line-clamp: 3;
		-webkit-box-orient: vertical;
		overflow: hidden;
	}
</style>
