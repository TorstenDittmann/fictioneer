<script lang="ts">
	import { goto } from '$app/navigation';
	import { resolve } from '$app/paths';
	import { projects } from '$lib/state/projects.svelte';
	import { page } from '$app/state';
	import type { Project } from '$lib/services/projects.svelte.js';
	import { Modal, Input, Button, Label, ContextMenu, AlertDialog } from '$lib/components/ui';

	interface Props {
		data: {
			project: Project;
		};
		is_visible?: boolean;
		os_type?: string | null;
	}

	let { data, is_visible = true, os_type = null }: Props = $props();
	const is_darwin = os_type?.toLowerCase() === 'darwin' || os_type?.toLowerCase() === 'macos';

	// Modal state
	let chapter_modal_open = $state(false);
	let scene_modal_open = $state(false);
	let editing_chapter_id = $state<string | null>(null);
	let editing_scene_id = $state<string | null>(null);
	let editing_chapter_name = $state('');
	let editing_scene_name = $state('');

	// Alert dialog state
	let delete_alert_open = $state(false);
	let pending_delete_action = $state<{
		type: 'chapter' | 'scene';
		chapter_id: string;
		scene_id?: string;
		title: string;
	} | null>(null);

	// Context menu items
	const chapter_menu_items = [
		{ value: 'rename', label: 'Rename', icon: 'edit' },
		{ value: 'add_scene', label: 'Add Scene', icon: 'add' },
		{ separator: true } as const,
		{ value: 'delete', label: 'Delete', icon: 'delete', destructive: true }
	];

	const scene_menu_items = [
		{ value: 'rename', label: 'Rename', icon: 'edit' },
		{ separator: true } as const,
		{ value: 'delete', label: 'Delete', icon: 'delete', destructive: true }
	];

	// Watch for name changes and auto-save
	$effect(() => {
		if (editing_chapter_id && data.project && editing_chapter_name.trim()) {
			const current_chapter = current_project().chapters.find((c) => c.id === editing_chapter_id);
			if (current_chapter && current_chapter.title !== editing_chapter_name.trim()) {
				projects.updateChapter(editing_chapter_id, {
					title: editing_chapter_name.trim()
				});
			}
		}
	});

	$effect(() => {
		if (editing_scene_id && editing_chapter_id && data.project && editing_scene_name.trim()) {
			const current_chapter = current_project().chapters.find((c) => c.id === editing_chapter_id);
			const current_scene = current_chapter?.scenes.find((s) => s.id === editing_scene_id);
			if (current_scene && current_scene.title !== editing_scene_name.trim()) {
				projects.updateScene(editing_chapter_id, editing_scene_id, {
					title: editing_scene_name.trim()
				});
			}
		}
	});

	// Get current IDs from page params
	const current_chapter_id = $derived(page.params.chapterId);
	const current_scene_id = $derived(page.params.sceneId);
	const is_overview_active = $derived(
		!current_chapter_id && !current_scene_id && page.url.pathname === `/${data.project.id}`
	);
	const is_notes_active = $derived(page.url.pathname === `/${data.project.id}/notes`);

	// Note: expanded chapters state is now managed in the projects store

	// Get current project data from state for real-time updates
	const current_project = $derived(() => {
		return projects.project || data.project;
	});

	// Helper function to check if a chapter has the active scene
	function is_chapter_active(chapter_id: string): boolean {
		return current_chapter_id === chapter_id && current_scene_id !== null;
	}

	function toggle_chapter(chapter_id: string) {
		projects.toggleChapterExpansion(chapter_id);
	}

	function create_chapter() {
		if (data.project) {
			const chapter_id = projects.createChapter();
			if (chapter_id) {
				projects.expandChapter(chapter_id);

				// Create first scene and navigate to it
				const scene_id = projects.createScene(chapter_id);
				if (scene_id) {
					goto(
						resolve('/[projectId]/[chapterId]/[sceneId]', {
							projectId: data.project.id,
							chapterId: chapter_id,
							sceneId: scene_id
						})
					);
				}
			}
		}
	}

	function create_scene(chapter_id: string) {
		if (data.project) {
			const scene_id = projects.createScene(chapter_id);
			if (scene_id) {
				goto(
					resolve('/[projectId]/[chapterId]/[sceneId]', {
						projectId: data.project.id,
						chapterId: chapter_id,
						sceneId: scene_id
					})
				);
			}
		}
	}

	function handle_chapter_context_menu(action: string, chapter_id: string, chapter_title: string) {
		if (action === 'rename') {
			editing_chapter_id = chapter_id;
			editing_chapter_name = chapter_title;
			chapter_modal_open = true;
		} else if (action === 'delete') {
			pending_delete_action = { type: 'chapter', chapter_id, title: chapter_title };
			delete_alert_open = true;
		} else if (action === 'add_scene') {
			create_scene(chapter_id);
		}
	}

	function handle_scene_context_menu(
		action: string,
		chapter_id: string,
		scene_id: string,
		scene_title: string
	) {
		if (action === 'rename') {
			editing_chapter_id = chapter_id;
			editing_scene_id = scene_id;
			editing_scene_name = scene_title;
			scene_modal_open = true;
		} else if (action === 'delete') {
			pending_delete_action = { type: 'scene', chapter_id, scene_id, title: scene_title };
			delete_alert_open = true;
		}
	}

	function close_chapter_modal() {
		chapter_modal_open = false;
		editing_chapter_id = null;
		editing_chapter_name = '';
	}

	function close_scene_modal() {
		scene_modal_open = false;
		editing_scene_id = null;
		editing_scene_name = '';
	}

	function handle_delete_confirm() {
		if (!pending_delete_action) return;

		if (pending_delete_action.type === 'chapter') {
			projects.deleteChapter(pending_delete_action.chapter_id);
		} else if (pending_delete_action.type === 'scene' && pending_delete_action.scene_id) {
			projects.deleteScene(pending_delete_action.chapter_id, pending_delete_action.scene_id);
		}

		pending_delete_action = null;
	}

	function handle_delete_cancel() {
		pending_delete_action = null;
	}
</script>

<aside
	class="sidebar flex h-full flex-col border-r border-border transition-all duration-300 ease-in-out"
	class:hidden={!is_visible}
	class:w-72={is_visible}
	class:w-0={!is_visible}
>
	<!-- Header -->
	<div class="border-b border-border bg-background-tertiary-transparent p-2">
		<!-- Project Info -->
		<div class="space-y-2">
			<div class="flex items-start justify-between">
				<div class="min-w-0 flex-1">
					<h2 class="truncate text-lg font-semibold text-text">
						{current_project().title}
					</h2>
				</div>
				<a
					href={resolve('/[projectId]/settings', { projectId: data.project.id })}
					class="ml-2 inline-flex items-center rounded-md px-2 py-1 text-xs text-text-secondary no-underline transition-colors hover:bg-surface hover:text-text"
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

	<!-- Overview Button -->
	<div class="border-b border-border p-2">
		<div class="space-y-0.5">
			<a
				href={resolve('/[projectId]', { projectId: data.project.id })}
				class="flex w-full items-center gap-2 rounded-lg px-2 py-1.5 text-sm font-medium transition-colors duration-200"
				class:bg-surface={is_overview_active}
				class:text-text={is_overview_active}
				class:text-text-secondary={!is_overview_active}
				class:hover:bg-background-tertiary={!is_overview_active}
			>
				<svg class="h-4 w-4 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
					<path
						stroke-linecap="round"
						stroke-linejoin="round"
						stroke-width="2"
						d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
					/>
				</svg>
				<span>Overview</span>
			</a>
			<a
				href={resolve('/[projectId]/notes', { projectId: data.project.id })}
				class="flex w-full items-center gap-2 rounded-lg px-2 py-1.5 text-sm font-medium transition-colors duration-200"
				class:bg-surface={is_notes_active}
				class:text-text={is_notes_active}
				class:text-text-secondary={!is_notes_active}
				class:hover:bg-background-tertiary={!is_notes_active}
			>
				<svg class="h-4 w-4 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
					<path
						stroke-linecap="round"
						stroke-linejoin="round"
						stroke-width="2"
						d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
					/>
				</svg>
				<span>Notes</span>
			</a>
		</div>
	</div>

	<!-- Chapters and Scenes -->
	<div class="flex-1 overflow-y-auto py-1">
		{#each current_project().chapters as chapter (chapter.id)}
			<div class="group mb-0.5">
				<!-- Chapter header -->
				<ContextMenu
					items={chapter_menu_items}
					onSelect={(action) => handle_chapter_context_menu(action, chapter.id, chapter.title)}
				>
					<div class="w-full select-none">
						<button
							class="flex w-full items-center gap-2 border-l-4 px-3 py-2 text-left text-sm font-medium transition-colors duration-200 outline-none select-none focus:shadow-none focus:ring-0 focus:outline-none focus-visible:outline-none active:shadow-none active:ring-0 active:outline-none"
							class:bg-background-tertiary={is_chapter_active(chapter.id)}
							class:border-accent={is_chapter_active(chapter.id)}
							class:text-text={is_chapter_active(chapter.id)}
							class:border-transparent={!is_chapter_active(chapter.id)}
							class:text-text-secondary={!is_chapter_active(chapter.id)}
							class:hover:bg-background-tertiary={!is_chapter_active(chapter.id)}
							onclick={() => toggle_chapter(chapter.id)}
							aria-label="Toggle chapter {chapter.title}"
						>
							<div class="flex h-4 w-4 items-center justify-center">
								<svg
									class="h-3 w-3 text-text-muted transition-all duration-300 ease-out"
									class:rotate-90={projects.isChapterExpanded(chapter.id)}
									class:text-text-secondary={projects.isChapterExpanded(chapter.id) ||
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
									class="truncate text-text"
									class:font-semibold={is_chapter_active(chapter.id)}
								>
									{chapter.title}
								</span>
								<div class="flex items-center gap-2">
									{#if is_chapter_active(chapter.id)}
										<div class="h-2 w-2 rounded-full bg-accent"></div>
									{/if}
									<span
										class="rounded-full bg-surface px-2 py-0.5 text-xs font-medium text-text-secondary"
									>
										{chapter.scenes.length}
									</span>
								</div>
							</div>
						</button>
					</div>
				</ContextMenu>

				<!-- Scenes (only show if chapter is expanded) -->
				{#if projects.isChapterExpanded(chapter.id)}
					<div class="ml-4 space-y-0.5 border-l-2 border-border">
						{#each chapter.scenes as scene (scene.id)}
							<div class="group relative">
								<ContextMenu
									items={scene_menu_items}
									onSelect={(action) =>
										handle_scene_context_menu(action, chapter.id, scene.id, scene.title)}
								>
									<div class="w-full select-none">
										<a
											href={resolve('/[projectId]/[chapterId]/[sceneId]', {
												projectId: data.project.id,
												chapterId: chapter.id,
												sceneId: scene.id
											})}
											class="flex w-full items-center gap-2 border-l-2 border-transparent py-1.5 pr-2 pl-4 text-left text-sm no-underline transition-colors duration-200 outline-none select-none hover:bg-background-tertiary focus:shadow-none focus:ring-0 focus:outline-none focus-visible:outline-none active:ring-0 active:outline-none"
											class:bg-background-tertiary={current_scene_id === scene.id}
											class:border-accent={current_scene_id === scene.id}
										>
											<svg
												class="h-3 w-3 shrink-0 text-text-muted"
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
											<span class="truncate font-medium text-text">
												{scene.title}
											</span>
										</a>
									</div>
								</ContextMenu>
							</div>
						{/each}

						<!-- Add scene -->
						<button
							class="flex w-full items-center gap-2 border-l-2 border-transparent py-1.5 pr-2 pl-4 text-left text-sm font-medium text-text-muted transition-colors duration-200 outline-none hover:bg-background-tertiary hover:text-text focus:shadow-none focus:ring-0 focus:outline-none focus-visible:outline-none active:ring-0 active:outline-none"
							onclick={(e) => {
								e.stopPropagation();
								create_scene(chapter.id);
							}}
						>
							<svg
								class="h-3 w-3 shrink-0 text-text-muted"
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
							<span class="truncate font-medium">Add Scene</span>
						</button>
					</div>
				{/if}
			</div>
		{/each}

		<!-- Add chapter -->
		<div class="mx-2 mt-2">
			<button
				onclick={create_chapter}
				class="group flex w-full items-center gap-2 rounded-lg px-3 py-2 text-left text-sm font-medium text-text-muted transition-colors duration-200 hover:bg-background-tertiary hover:text-text-secondary"
			>
				<svg
					class="mr-2 h-4 w-4 text-text-muted"
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
				Add chapter
			</button>
		</div>
	</div>

	<!-- Footer -->
	<!-- Keyboard Shortcuts -->
	<div class="border-t border-border bg-background-tertiary-transparent p-2">
		<div class="space-y-2">
			<div class="text-xs font-medium text-text-secondary">Keyboard Shortcuts</div>
			<div class="space-y-0.5 text-xs text-text-secondary">
				<div class="flex justify-between">
					<span>New Scene</span>
					<kbd class="rounded bg-surface px-1 py-0.5 font-mono text-xs">⌘N</kbd>
				</div>
				{#if is_darwin}
					<div class="flex justify-between">
						<span>AI Suggestions (hold)</span>
						<kbd class="rounded bg-surface px-1 py-0.5 font-mono text-xs">⌥</kbd>
					</div>
				{:else}
					<div class="flex justify-between">
						<span>AI Suggestions (hold)</span>
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
</aside>

<!-- Chapter Settings Modal -->
<Modal bind:open={chapter_modal_open} onOpenChange={close_chapter_modal}>
	<h2 class="mb-3 text-lg font-semibold text-text">Edit Chapter Name</h2>

	<div class="mb-4 grid gap-2">
		<Label for="chapter-name">Name</Label>
		<Input
			bind:value={editing_chapter_name}
			onkeydown={(e) => e.key === 'Enter' && close_chapter_modal()}
			id="chapter-name"
			placeholder="Enter name..."
		/>
	</div>

	<div class="flex justify-end">
		<Button variant="secondary" onclick={close_chapter_modal}>Done</Button>
	</div>
</Modal>

<!-- Scene Settings Modal -->
<Modal bind:open={scene_modal_open} onOpenChange={close_scene_modal}>
	<h2 class="mb-3 text-lg font-semibold text-text">Edit Scene Name</h2>

	<div class="mb-4 grid gap-2">
		<Label for="scene-name">Name</Label>
		<Input
			bind:value={editing_scene_name}
			onkeydown={(e) => e.key === 'Enter' && close_scene_modal()}
			id="scene-name"
			placeholder="Enter name..."
		/>
	</div>

	<div class="flex justify-end">
		<Button variant="secondary" onclick={close_scene_modal}>Done</Button>
	</div>
</Modal>

<!-- Delete Confirmation Alert Dialog -->
<AlertDialog
	bind:open={delete_alert_open}
	title={`Delete ${pending_delete_action?.type === 'chapter' ? 'Chapter' : 'Scene'}`}
	description={`Are you sure you want to delete ${pending_delete_action?.type === 'chapter' ? 'the chapter' : 'the scene'} "${pending_delete_action?.title}"? This action cannot be undone.`}
	confirmText="Delete"
	cancelText="Cancel"
	destructive={true}
	onConfirm={handle_delete_confirm}
	onCancel={handle_delete_cancel}
/>
