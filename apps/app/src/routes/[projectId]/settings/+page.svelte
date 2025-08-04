<script lang="ts">
	import { goto } from '$app/navigation';
	import { projects } from '$lib/state/projects.svelte';
	import ProjectSidebar from '$lib/components/project_sidebar.svelte';
	import { Input, Textarea, Button, Label, Card } from '$lib/components/ui';
	import type { PageData } from './$types';

	let { data }: { data: PageData } = $props();

	let is_sidebar_visible = $state(true);
	let project_title = $state(data.project.title);
	let project_description = $state(data.project.description || '');

	// Get project stats as derived value
	const stats = $derived(projects.getProjectStats());

	function toggle_sidebar() {
		is_sidebar_visible = !is_sidebar_visible;
	}

	function save_settings() {
		projects.updateProject({
			title: project_title.trim() || 'Untitled Project',
			description: project_description.trim()
		});
	}

	function delete_project() {
		if (
			confirm(
				`Are you sure you want to delete "${data.project.title}"? This action cannot be undone.`
			)
		) {
			// In file-based system, just close the project
			projects.closeProject();
			goto('/');
		}
	}

	// Handle keyboard shortcuts
	function handle_keydown(event: KeyboardEvent) {
		// Cmd/Ctrl + B to toggle sidebar
		if ((event.metaKey || event.ctrlKey) && event.key === 'b') {
			event.preventDefault();
			toggle_sidebar();
		}

		// Cmd/Ctrl + S to save
		if ((event.metaKey || event.ctrlKey) && event.key === 's') {
			event.preventDefault();
			save_settings();
		}
	}
</script>

<svelte:window onkeydown={handle_keydown} />

<div class="app bg-transparent-paper flex h-full flex-col text-gray-900 dark:text-gray-100">
	<!-- Main content area -->
	<div class="flex flex-1 overflow-hidden">
		<!-- Sidebar -->
		<ProjectSidebar {data} is_visible={is_sidebar_visible} />

		<!-- Settings content -->
		<main class="bg-transparent-paper flex-1 overflow-y-auto">
			<div class="mx-auto max-w-4xl p-8">
				<!-- Header -->
				<div class="mb-8">
					<h1 class="text-3xl font-bold text-gray-900 dark:text-gray-100">Project Settings</h1>
					<p class="mt-2 text-gray-600 dark:text-gray-400">
						Manage your project details and preferences.
					</p>
				</div>

				<!-- Settings Form -->
				<div class="space-y-8">
					<!-- Basic Information -->
					<Card>
						<h2 class="mb-4 text-xl font-semibold text-gray-900 dark:text-gray-100">
							Basic Information
						</h2>

						<div class="space-y-4">
							<div class="grid gap-2">
								<Label for="title">Project Title</Label>
								<Input
									id="title"
									type="text"
									bind:value={project_title}
									oninput={save_settings}
									placeholder="Enter project title..."
								/>
							</div>

							<div class="grid gap-2">
								<Label for="description">Description</Label>
								<Textarea
									id="description"
									bind:value={project_description}
									oninput={save_settings}
									rows={4}
									placeholder="Enter project description..."
								/>
							</div>
						</div>
					</Card>

					<!-- Project Statistics -->
					<Card>
						<h2 class="mb-4 text-xl font-semibold text-gray-900 dark:text-gray-100">
							Project Statistics
						</h2>

						<div class="grid grid-cols-1 gap-4 sm:grid-cols-3">
							<div class="rounded-md bg-gray-50 p-4 dark:bg-gray-700">
								<div class="text-2xl font-bold text-gray-900 dark:text-gray-100">
									{stats.total_chapters}
								</div>
								<div class="text-sm text-gray-600 dark:text-gray-400">Chapters</div>
							</div>
							<div class="rounded-md bg-gray-50 p-4 dark:bg-gray-700">
								<div class="text-2xl font-bold text-gray-900 dark:text-gray-100">
									{stats.total_scenes}
								</div>
								<div class="text-sm text-gray-600 dark:text-gray-400">Scenes</div>
							</div>
							<div class="rounded-md bg-gray-50 p-4 dark:bg-gray-700">
								<div class="text-2xl font-bold text-gray-900 dark:text-gray-100">
									{stats.total_words.toLocaleString()}
								</div>
								<div class="text-sm text-gray-600 dark:text-gray-400">Words</div>
							</div>
						</div>
					</Card>

					<!-- Project Actions -->
					<Card class="border-red-200 dark:border-red-800">
						<h2 class="mb-4 text-xl font-semibold text-red-900 dark:text-red-100">Danger Zone</h2>

						<div class="space-y-4">
							<div>
								<h3 class="text-sm font-medium text-red-900 dark:text-red-100">Delete Project</h3>
								<p class="mt-1 text-sm text-red-700 dark:text-red-300">
									Once you delete a project, there is no going back. Please be certain.
								</p>
								<Button variant="destructive" onclick={delete_project} class="mt-3">
									Delete Project
								</Button>
							</div>
						</div>
					</Card>
				</div>

				<!-- Keyboard Shortcuts -->
				<div class="mt-8 rounded-lg bg-gray-50 p-4 dark:bg-gray-800">
					<h3 class="text-sm font-medium text-gray-900 dark:text-gray-100">Keyboard Shortcuts</h3>
					<div class="mt-2 space-y-1 text-sm text-gray-600 dark:text-gray-400">
						<div class="flex justify-between">
							<span>Toggle sidebar</span>
							<kbd class="rounded bg-gray-200 px-1 py-0.5 font-mono text-xs dark:bg-gray-700"
								>Ctrl+B</kbd
							>
						</div>
						<div class="flex justify-between">
							<span>Save changes</span>
							<kbd class="rounded bg-gray-200 px-1 py-0.5 font-mono text-xs dark:bg-gray-700"
								>Ctrl+S</kbd
							>
						</div>
						<div class="flex justify-between">
							<span>AI auto complete</span>
							<kbd class="rounded bg-gray-200 px-1 py-0.5 font-mono text-xs dark:bg-gray-700">⌥</kbd
							>
						</div>
					</div>
				</div>
			</div>
		</main>
	</div>
</div>
