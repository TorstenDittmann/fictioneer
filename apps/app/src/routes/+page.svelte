<script lang="ts">
	import { goto } from '$app/navigation';
	import { projects } from '$lib/state/projects.svelte';
	import type { Project } from '$lib/services/projects.js';
	import { onMount } from 'svelte';
	import { theme } from '$lib/state/theme.svelte';

	let { data }: { data: { projects: Project[] } } = $props();

	onMount(() => {
		// Keep users on overview page to manually select projects
	});

	function create_new_project() {
		const project_id = projects.createProject('My Novel');
		const urls = projects.getProjectUrls(project_id);
		if (!urls) {
			throw new Error('Failed to create project URLs');
		}
		goto(urls.scene_url);
	}

	function get_project_url(project_id: string): string {
		const urls = projects.getProjectUrls(project_id);
		if (!urls) {
			throw new Error(`Failed to generate URLs for project ${project_id}`);
		}
		return urls.scene_url;
	}

	function format_date(date: Date): string {
		return new Intl.DateTimeFormat('en-US', {
			month: 'short',
			day: 'numeric',
			year: 'numeric'
		}).format(date);
	}

	function format_word_count(count: number): string {
		if (count === 0) return '0 words';
		if (count === 1) return '1 word';
		if (count < 1000) return `${count} words`;
		return `${(count / 1000).toFixed(1)}k words`;
	}
</script>

<div class="flex h-full flex-col bg-white text-gray-900 dark:bg-gray-900 dark:text-gray-100">
	<!-- Header -->
	<header class="border-b border-gray-200 px-6 py-4 dark:border-gray-700">
		<div class="mx-auto flex max-w-4xl items-center justify-between">
			<h1 class="text-2xl font-bold">Omnia</h1>
			<button
				onclick={() => theme.toggle_theme()}
				class="text-sm text-gray-600 hover:text-gray-800 dark:text-gray-400 dark:hover:text-gray-200"
				title="Current: {theme.current_theme_label}, Click for: {theme.next_theme_label}"
			>
				{theme.current_theme_label}
			</button>
		</div>
	</header>

	<!-- Main content -->
	<main class="flex-1 overflow-y-auto">
		<div class="mx-auto max-w-4xl px-6 py-12">
			{#if data.projects.length === 0}
				<!-- Welcome state -->
				<div class="text-center">
					<div
						class="mx-auto mb-8 flex h-20 w-20 items-center justify-center rounded-full bg-gray-100 dark:bg-gray-800"
					>
						<svg
							class="h-10 w-10 text-gray-400"
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
					<h2 class="mb-4 text-3xl font-bold">Welcome to Omnia</h2>
					<p class="mx-auto mb-8 max-w-2xl text-xl text-gray-600 dark:text-gray-400">
						A minimalist writing tool designed for distraction-free creative writing. Start by
						creating your first project.
					</p>
					<button
						onclick={create_new_project}
						class="rounded-lg bg-blue-600 px-8 py-4 text-lg font-medium text-white transition-colors duration-200 hover:bg-blue-700"
					>
						Create Your First Project
					</button>
				</div>
			{:else}
				<!-- Project list -->
				<div class="mb-8">
					<div class="mb-6 flex items-center justify-between">
						<h2 class="text-2xl font-bold">Your Projects</h2>
						<button
							onclick={create_new_project}
							class="rounded-lg bg-blue-600 px-4 py-2 text-white transition-colors duration-200 hover:bg-blue-700"
						>
							New Project
						</button>
					</div>

					<div class="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
						{#each data.projects as project (project.id)}
							{@const stats = projects.getProjectStats(project.id)}
							<a
								href={get_project_url(project.id)}
								class="block w-full rounded-lg border border-gray-200 p-6 text-left text-inherit no-underline transition-shadow duration-200 hover:shadow-lg focus:shadow-lg focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none dark:border-gray-700 dark:focus:ring-blue-400"
							>
								<h3 class="mb-2 truncate text-xl font-semibold">{project.title}</h3>

								{#if project.description}
									<p class="mb-4 line-clamp-2 text-gray-600 dark:text-gray-400">
										{project.description}
									</p>
								{/if}

								<div
									class="mb-3 flex items-center justify-between text-sm text-gray-500 dark:text-gray-400"
								>
									<span>{stats.totalChapters} chapters</span>
									<span>{stats.totalScenes} scenes</span>
									<span>{format_word_count(stats.totalWords)}</span>
								</div>

								<div class="text-xs text-gray-400 dark:text-gray-500">
									Updated {format_date(project.updatedAt)}
								</div>
							</a>
						{/each}
					</div>
				</div>

				<!-- Recent activity -->
				<div class="border-t border-gray-200 pt-8 dark:border-gray-700">
					<h3 class="mb-4 text-lg font-semibold">Recent Activity</h3>
					<div class="space-y-3">
						{#each data.projects
							.sort((a: Project, b: Project) => new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime())
							.slice(0, 5) as project (project.id)}
							<a
								href={get_project_url(project.id)}
								class="flex w-full items-center justify-between rounded-lg p-3 text-left text-inherit no-underline transition-colors duration-200 hover:bg-gray-50 focus:bg-gray-50 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none dark:hover:bg-gray-800 dark:focus:bg-gray-800 dark:focus:ring-blue-400"
							>
								<div>
									<span class="font-medium">{project.title}</span>
									<span class="ml-2 text-sm text-gray-500 dark:text-gray-400">
										{format_date(project.updatedAt)}
									</span>
								</div>
								<div class="text-sm text-gray-500 dark:text-gray-400">
									{format_word_count(projects.getProjectStats(project.id).totalWords)}
								</div>
							</a>
						{/each}
					</div>
				</div>
			{/if}
		</div>
	</main>
</div>

<style>
	.line-clamp-2 {
		display: -webkit-box;
		-webkit-line-clamp: 2;
		line-clamp: 2;
		-webkit-box-orient: vertical;
		overflow: hidden;
	}
</style>
