<script lang="ts">
	import { projects } from '$lib/state/projects.svelte';
	import type { Project } from '$lib/state/projects.svelte';
	import { Input, Textarea, Label, Card } from '$lib/components/ui';
	import type { PageData } from './$types';

	let { data }: { data: PageData } = $props();
	const get_project = (): Project => data.project;
	const get_os_type = () => data.os_type;
	const existing_epub_metadata = get_project().epub_metadata;

	let project_title = $state(get_project().title);
	let project_description = $state(get_project().description || '');
	let epub_author = $state(existing_epub_metadata?.author || '');
	let epub_publisher = $state(existing_epub_metadata?.publisher || '');
	let epub_language = $state(existing_epub_metadata?.language || 'en');
	let epub_rights = $state(existing_epub_metadata?.rights || '');
	let epub_subjects_input = $state(existing_epub_metadata?.subjects.join(', ') || '');
	const is_darwin =
		get_os_type()?.toLowerCase() === 'darwin' || get_os_type()?.toLowerCase() === 'macos';

	// Get project stats as derived value
	const stats = $derived(projects.getProjectStats());

	function parse_subjects(subjects_input: string): string[] {
		return subjects_input
			.split(',')
			.map((subject) => subject.trim())
			.filter((subject) => subject.length > 0);
	}

	function save_settings() {
		const updates = {
			title: project_title.trim() || 'Untitled Project',
			description: project_description.trim(),
			epub_metadata: {
				author: epub_author.trim(),
				publisher: epub_publisher.trim(),
				language: epub_language.trim() || 'en',
				rights: epub_rights.trim(),
				subjects: parse_subjects(epub_subjects_input)
			}
		};

		projects.updateProject(updates);
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
			<Card class="ring-1 ring-border">
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
			</Card>

			<Card class="ring-1 ring-border">
				<h2 class="mb-4 text-xl font-semibold text-text">eBook Metadata</h2>
				<p class="mb-4 text-sm text-text-secondary">
					Saved metadata is used as the default when exporting EPUB files.
				</p>

				<div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
					<div class="grid gap-2">
						<Label for="epub-author">Author</Label>
						<Input
							id="epub-author"
							type="text"
							bind:value={epub_author}
							oninput={save_settings}
							placeholder="Author name"
						/>
					</div>

					<div class="grid gap-2">
						<Label for="epub-publisher">Publisher</Label>
						<Input
							id="epub-publisher"
							type="text"
							bind:value={epub_publisher}
							oninput={save_settings}
							placeholder="Publisher"
						/>
					</div>

					<div class="grid gap-2">
						<Label for="epub-language">Language</Label>
						<Input
							id="epub-language"
							type="text"
							bind:value={epub_language}
							oninput={save_settings}
							placeholder="en"
						/>
					</div>

					<div class="grid gap-2">
						<Label for="epub-rights">Rights</Label>
						<Input
							id="epub-rights"
							type="text"
							bind:value={epub_rights}
							oninput={save_settings}
							placeholder="Copyright statement"
						/>
					</div>

					<div class="grid gap-2 sm:col-span-2">
						<Label for="epub-subjects">Subjects</Label>
						<Input
							id="epub-subjects"
							type="text"
							bind:value={epub_subjects_input}
							oninput={save_settings}
							placeholder="Fantasy, Adventure, Drama"
						/>
						<p class="text-xs text-text-secondary">Separate tags with commas.</p>
					</div>
				</div>
			</Card>

			<Card class="ring-1 ring-border">
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
				{#if is_darwin}
					<div class="flex justify-between">
						<span>AI suggestions (hold)</span>
						<kbd class="rounded bg-surface px-1 py-0.5 font-mono text-xs">⌥</kbd>
					</div>
				{:else}
					<div class="flex justify-between">
						<span>AI suggestions (hold)</span>
						<kbd class="rounded bg-surface px-1 py-0.5 font-mono text-xs">Ctrl</kbd>
					</div>
					<div class="flex justify-between">
						<span>Accept suggestion</span>
						<kbd class="rounded bg-surface px-1 py-0.5 font-mono text-xs">Ctrl+Enter</kbd>
					</div>
				{/if}
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
