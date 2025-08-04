<script lang="ts">
	import { goto } from '$app/navigation';
	import { projects } from '$lib/state/projects.svelte';
	import NewProjectModal from '$lib/components/new_project_modal.svelte';

	let show_new_project_modal = $state(false);

	// Import file service for recent projects management
	import { file_service } from '$lib/services/file.svelte.js';

	async function handle_new_project() {
		show_new_project_modal = true;
	}

	async function handle_open_project() {
		const success = await projects.openProject();
		if (success) {
			const project = projects.project;
			if (project) {
				const urls = projects.getProjectUrls();
				if (urls) {
					await goto(urls.scene_url);
				}
			}
		}
	}

	async function handle_create_project(title: string, description: string, filePath: string) {
		const success = await projects.createNewProject(title, description, filePath);
		if (success) {
			const project = projects.project;
			if (project) {
				const urls = projects.getProjectUrls();
				if (urls) {
					await goto(urls.scene_url);
				}
			}
		}
	}

	async function handle_open_recent(filePath: string) {
		const success = await projects.openRecentProject(filePath);
		if (success) {
			const project = projects.project;
			if (project) {
				const urls = projects.getProjectUrls();
				if (urls) {
					await goto(urls.scene_url);
				}
			}
		}
	}

	function format_date(dateString: string): string {
		return new Intl.DateTimeFormat('en-US', {
			month: 'short',
			day: 'numeric',
			year: 'numeric',
			hour: 'numeric',
			minute: '2-digit'
		}).format(new Date(dateString));
	}

	function get_filename_from_path(path: string): string {
		return path.split('/').pop()?.replace('.omnia', '') || path;
	}

	const recent_projects = $derived(projects.recentProjects);

	// Keyboard shortcuts
	function handle_keydown(event: KeyboardEvent) {
		if (event.metaKey || event.ctrlKey) {
			switch (event.key) {
				case 'n':
					event.preventDefault();
					handle_new_project();
					break;
				case 'o':
					event.preventDefault();
					handle_open_project();
					break;
			}
		}
	}
</script>

<svelte:window onkeydown={handle_keydown} />

<div class="flex h-full flex-col text-gray-100">
	<!-- Header -->
	<header class="border-b border-gray-700 px-6 py-4">
		<div class="mx-auto flex max-w-4xl items-center justify-between">
			<h1 class="text-2xl font-bold">Omnia</h1>
		</div>
	</header>

	<!-- Main content -->
	<main class="flex-1 overflow-y-auto">
		<div class="mx-auto max-w-4xl px-6 py-12">
			<!-- Welcome state -->
			<div class="text-center">
				<div
					class="mx-auto mb-8 flex h-20 w-20 items-center justify-center rounded-full bg-gray-800"
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
				<p class="mx-auto mb-8 max-w-2xl text-xl text-gray-400">
					A minimalist writing tool designed for distraction-free creative writing.
				</p>

				<div
					class="flex flex-col items-center space-y-4 sm:flex-row sm:justify-center sm:space-y-0 sm:space-x-4"
				>
					<button
						onclick={handle_new_project}
						class="rounded-lg bg-blue-600 px-8 py-4 text-lg font-medium text-white transition-colors duration-200 hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none"
					>
						Create New Project
					</button>
					<button
						onclick={handle_open_project}
						class="rounded-lg border border-gray-600 px-8 py-4 text-lg font-medium text-gray-300 transition-colors duration-200 hover:bg-gray-800 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none"
					>
						Open Existing Project
					</button>
				</div>
			</div>

			<!-- Recent Projects -->
			{#if recent_projects.length > 0}
				<div class="mt-12 border-t border-gray-700 pt-8">
					<div class="mb-6 flex items-center justify-between">
						<h3 class="text-xl font-semibold">Recent Projects</h3>
						<button
							onclick={() =>
								projects.recentProjects.length > 0 &&
								confirm('Clear all recent projects?') &&
								file_service.clear_recent_projects()}
							class="text-sm text-gray-400 hover:text-gray-200"
						>
							Clear All
						</button>
					</div>
					<div class="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
						{#each recent_projects as recent_project (recent_project.path)}
							<div
								class="group relative rounded-lg border border-gray-700 bg-gray-800 transition-all duration-200 hover:-translate-y-1 hover:scale-[1.02] hover:border-gray-600 hover:bg-gray-700 hover:shadow-lg"
							>
								<button
									onclick={() => handle_open_recent(recent_project.path)}
									class="block w-full p-4 text-left focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none"
								>
									<h4
										class="mb-2 truncate text-lg font-medium text-gray-100 group-hover:text-white"
									>
										{recent_project.title}
									</h4>
									<div class="text-sm text-gray-400">
										<div class="mb-1 truncate" title={recent_project.path}>
											{get_filename_from_path(recent_project.path)}
										</div>
										<div class="flex items-center justify-between">
											<span>Last opened {format_date(recent_project.lastOpened)}</span>
										</div>
									</div>
								</button>

								<!-- Remove button -->
								<button
									onclick={(e) => {
										e.stopPropagation();
										file_service.remove_from_recent_projects(recent_project.path);
									}}
									class="absolute top-2 right-2 rounded p-1 text-gray-400 opacity-0 transition-opacity group-hover:opacity-100 hover:bg-gray-800 hover:text-red-400"
									title="Remove from recent projects"
									aria-label="Remove from recent projects"
								>
									<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
										<path
											stroke-linecap="round"
											stroke-linejoin="round"
											stroke-width="2"
											d="M6 18L18 6M6 6l12 12"
										/>
									</svg>
								</button>
							</div>
						{/each}
					</div>
				</div>
			{/if}

			<!-- Getting Started -->
			<div class="mt-12 text-left">
				<h3 class="mb-4 text-xl font-semibold">Getting Started</h3>
				<div class="grid gap-6 md:grid-cols-2">
					<div class="rounded-lg border border-gray-700 p-6">
						<h4 class="mb-2 font-medium">Creating a New Project</h4>
						<p class="text-sm text-gray-400">
							Click "Create New Project" to start a new writing project. You'll be prompted to set a
							title, description, and choose where to save your <code>.omnia</code> file.
						</p>
					</div>
					<div class="rounded-lg border border-gray-700 p-6">
						<h4 class="mb-2 font-medium">Opening an Existing Project</h4>
						<p class="text-sm text-gray-400">
							Click "Open Existing Project" to browse for and open a previously saved <code
								>.omnia</code
							> file. All your chapters, scenes, and content will be restored.
						</p>
					</div>
					<div class="rounded-lg border border-gray-700 p-6">
						<h4 class="mb-2 font-medium">Automatic Saving</h4>
						<p class="text-sm text-gray-400">
							Your work is automatically saved to your <code>.omnia</code> file as you write. No need
							to manually save.
						</p>
					</div>
					<div class="rounded-lg border border-gray-700 p-6">
						<h4 class="mb-2 font-medium">Keyboard Shortcuts</h4>
						<div class="text-sm text-gray-400">
							<div>⌘N - New Project</div>
							<div>⌘O - Open Project</div>
							<div>⌘W - Close Project</div>
						</div>
					</div>
				</div>
			</div>
		</div>
	</main>
</div>

<!-- New Project Modal -->
<NewProjectModal
	bind:open={show_new_project_modal}
	onCreate={handle_create_project}
	onCancel={() => (show_new_project_modal = false)}
/>

<style>
	code {
		background-color: rgba(255, 255, 255, 0.1);
		padding: 0.125rem 0.25rem;
		border-radius: 0.25rem;
		font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
		font-size: 0.875em;
	}
</style>
