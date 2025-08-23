<script lang="ts">
	import { projects } from '$lib/state/projects.svelte';
	import { Input, Textarea, Label, Card } from '$lib/components/ui';
	import type { PageData } from './$types';

	let { data }: { data: PageData } = $props();

	let project_title = $state(data.project.title);
	let project_description = $state(data.project.description || '');

	// Get project stats as derived value
	const stats = $derived(projects.getProjectStats());

	function save_settings() {
		projects.updateProject({
			title: project_title.trim() || 'Untitled Project',
			description: project_description.trim()
		});
	}

	// Handle page-specific keyboard shortcuts
	function handle_keydown(event: KeyboardEvent) {
		// Skip if user is typing in an input field
		const target = event.target as HTMLElement;
		if (
			target.tagName === 'INPUT' ||
			target.tagName === 'TEXTAREA' ||
			target.contentEditable === 'true'
		) {
			return;
		}

		// Cmd/Ctrl + S to save
		if ((event.metaKey || event.ctrlKey) && event.key === 's') {
			event.preventDefault();
			save_settings();
		}
	}
</script>

<svelte:window onkeydown={handle_keydown} />

<div class="h-full overflow-y-auto">
	<div class="mx-auto max-w-4xl p-8">
		<!-- Header -->
		<div class="mb-8">
			<h1 class="text-3xl font-bold text-text">Project Settings</h1>
			<p class="mt-2 text-text-secondary">Manage your project details and preferences.</p>
		</div>

		<!-- Settings Form -->
		<div class="space-y-8">
			<!-- Basic Information -->
			<Card class="ring-1 ring-border">
				{#snippet children()}
					<h2 class="mb-4 text-xl font-semibold text-text">Basic Information</h2>

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
				{/snippet}
			</Card>

			<!-- Project Statistics -->
			<Card class="ring-1 ring-border">
				{#snippet children()}
					<h2 class="mb-4 text-xl font-semibold text-text">Project Statistics</h2>

					<div class="grid grid-cols-1 gap-4 sm:grid-cols-3">
						<div class="rounded-md bg-background-tertiary p-4">
							<div class="text-2xl font-bold text-text">
								{stats.total_chapters}
							</div>
							<div class="text-sm text-text-secondary">Chapters</div>
						</div>
						<div class="rounded-md bg-background-tertiary p-4">
							<div class="text-2xl font-bold text-text">
								{stats.total_scenes}
							</div>
							<div class="text-sm text-text-secondary">Scenes</div>
						</div>
						<div class="rounded-md bg-background-tertiary p-4">
							<div class="text-2xl font-bold text-text">
								{stats.total_words.toLocaleString()}
							</div>
							<div class="text-sm text-text-secondary">Words</div>
						</div>
					</div>
				{/snippet}
			</Card>
		</div>

		<!-- Keyboard Shortcuts -->
		<div class="mt-8 rounded-lg bg-background-tertiary p-4">
			<h3 class="text-sm font-medium text-text">Keyboard Shortcuts</h3>
			<div class="mt-2 space-y-1 text-sm text-text-secondary">
				<div class="flex justify-between">
					<span>Save changes</span>
					<kbd class="rounded bg-surface px-1 py-0.5 font-mono text-xs">⌘S</kbd>
				</div>
				<div class="flex justify-between">
					<span>Focus Mode</span>
					<kbd class="rounded bg-surface px-1 py-0.5 font-mono text-xs">⌘F</kbd>
				</div>
				<div class="flex justify-between">
					<span>Search</span>
					<kbd class="rounded bg-surface px-1 py-0.5 font-mono text-xs">⌘K</kbd>
				</div>
			</div>
		</div>
	</div>
</div>
