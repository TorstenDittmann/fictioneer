<script lang="ts">
	import { goto } from '$app/navigation';
	import { projects } from '$lib/state/projects.svelte';
	import RecentNotes from '$lib/components/recent_notes.svelte';
	import ExportModal from '$lib/components/export_modal.svelte';
	import { Button } from '$lib/components/ui';
	import type { PageData } from './$types';

	let { data }: { data: PageData } = $props();

	let show_rtf_export_modal = $state(false);
	let show_txt_export_modal = $state(false);

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

		// Cmd/Ctrl + N to create new scene
		if ((event.metaKey || event.ctrlKey) && event.key === 'n') {
			event.preventDefault();
			create_first_scene();
		}
	}

	function handle_export_rtf() {
		show_rtf_export_modal = true;
	}

	function handle_export_txt() {
		show_txt_export_modal = true;
	}
</script>

<svelte:window onkeydown={handle_keydown} />

<div class="h-full overflow-y-auto">
	<div class="mx-auto max-w-6xl p-6">
		<!-- Header -->
		<div class="mb-8">
			<div>
				<h1 class="text-3xl font-bold text-text">
					{current_project.title}
				</h1>
				<p class="mt-2 text-text-secondary">
					{current_project.description || 'Project overview and recent activity'}
				</p>
			</div>
		</div>

		<!-- Project Stats -->
		<div class="mb-8 grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
			<div class="rounded-lg bg-background-secondary p-6 shadow-sm ring-1 ring-border">
				<div class="flex items-center">
					<div class="flex-shrink-0">
						<svg
							class="h-8 w-8 text-text-secondary"
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
						<p class="text-sm font-medium text-text-secondary">Scenes</p>
						<p class="text-2xl font-semibold text-text">
							{project_stats.total_scenes}
						</p>
					</div>
				</div>
			</div>

			<div class="rounded-lg bg-background-secondary p-6 shadow-sm ring-1 ring-border">
				<div class="flex items-center">
					<div class="flex-shrink-0">
						<svg
							class="h-8 w-8 text-text-secondary"
							fill="none"
							stroke="currentColor"
							viewBox="0 0 24 24"
						>
							<path
								stroke-linecap="round"
								stroke-linejoin="round"
								stroke-width="2"
								d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.246 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"
							/>
						</svg>
					</div>
					<div class="ml-4">
						<p class="text-sm font-medium text-text-secondary">Chapters</p>
						<p class="text-2xl font-semibold text-text">
							{project_stats.total_chapters}
						</p>
					</div>
				</div>
			</div>

			<div class="rounded-lg bg-background-secondary p-6 shadow-sm ring-1 ring-border">
				<div class="flex items-center">
					<div class="flex-shrink-0">
						<svg
							class="h-8 w-8 text-text-secondary"
							fill="none"
							stroke="currentColor"
							viewBox="0 0 24 24"
						>
							<path
								stroke-linecap="round"
								stroke-linejoin="round"
								stroke-width="2"
								d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
							/>
						</svg>
					</div>
					<div class="ml-4">
						<p class="text-sm font-medium text-text-secondary">Total Words</p>
						<p class="text-2xl font-semibold text-text">
							{project_stats.total_words.toLocaleString()}
						</p>
					</div>
				</div>
			</div>

			<div class="rounded-lg bg-background-secondary p-6 shadow-sm ring-1 ring-border">
				<div class="flex items-center">
					<div class="flex-shrink-0">
						<svg
							class="h-8 w-8 text-text-secondary"
							fill="none"
							stroke="currentColor"
							viewBox="0 0 24 24"
						>
							<path
								stroke-linecap="round"
								stroke-linejoin="round"
								stroke-width="2"
								d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
							/>
						</svg>
					</div>
					<div class="ml-4">
						<p class="text-sm font-medium text-text-secondary">Last Modified</p>
						<p class="text-lg font-semibold text-text">
							{project_stats.total_characters.toLocaleString()}
						</p>
					</div>
				</div>
			</div>
		</div>

		<!-- Recent Scenes -->
		<div class="mb-8">
			<h2 class="mb-6 text-xl font-semibold text-text">Recently Updated Scenes</h2>

			{#if recent_scenes.length === 0}
				<div class="rounded-lg border-2 border-dashed border-border p-12 text-center">
					<svg
						class="mx-auto h-12 w-12 text-text-muted"
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
					<h3 class="mt-4 text-lg font-medium text-text">No scenes yet</h3>
					<p class="mt-2 text-text-secondary">Start writing by creating your first scene</p>
					<Button variant="primary" onclick={create_first_scene} class="mt-4">
						Create First Scene
					</Button>
				</div>
			{:else}
				<div class="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
					{#each recent_scenes as scene (scene.id)}
						<a
							href="/{data.project.id}/{scene.chapter_id}/{scene.id}"
							class="group block rounded-lg bg-background-secondary p-6 text-left no-underline shadow-sm ring-1 ring-border transition-all duration-200 hover:-translate-y-1 hover:shadow-md"
						>
							<div class="flex items-start justify-between">
								<div class="min-w-0 flex-1">
									<h3
										class="truncate text-lg font-medium text-text group-hover:text-text-secondary"
									>
										{scene.title}
									</h3>
									<p class="mt-1 text-sm text-text-secondary">
										{scene.chapter_title}
									</p>
								</div>
								<svg
									class="h-5 w-5 flex-shrink-0 text-text-muted transition-colors group-hover:text-text-secondary"
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
								<p class="mt-3 line-clamp-3 text-sm text-text-secondary">
									{get_scene_preview(scene.content)}
								</p>
							{:else}
								<p class="mt-3 text-sm text-text-muted italic">No content yet...</p>
							{/if}

							<div class="mt-4 flex items-center justify-between text-xs text-text-muted">
								<span>
									{scene.wordCount} words
								</span>
								<span>
									Updated {format_date(new Date(scene.updatedAt))}
								</span>
							</div>
						</a>
					{/each}
				</div>
			{/if}
		</div>

		<!-- Recent Notes -->
		<RecentNotes project_id={data.project.id} />

		<!-- Export Section -->
		<div class="mb-8">
			<h2 class="mb-6 text-xl font-semibold text-text">Export Project</h2>
			<div class="rounded-lg border border-border bg-background-secondary p-6">
				<div class="grid gap-6 md:grid-cols-2">
					<div>
						<h3 class="mb-2 font-medium text-text">Rich Text Format (RTF)</h3>
						<p class="mb-4 text-sm text-text-secondary">
							Export your project as a formatted RTF document that preserves formatting and can be
							opened in most word processors like Microsoft Word, Google Docs, or Pages.
						</p>
						<div class="space-y-1 text-xs text-text-muted">
							<div>• Preserves text formatting</div>
							<div>• Compatible with major word processors</div>
							<div>• Includes chapter and scene structure</div>
						</div>
						<div class="mt-4">
							<Button variant="primary" onclick={handle_export_rtf}>Export as RTF</Button>
						</div>
					</div>
					<div>
						<h3 class="mb-2 font-medium text-text">Plain Text (TXT)</h3>
						<p class="mb-4 text-sm text-text-secondary">
							Export your project as a simple text file with minimal formatting. Perfect for
							importing into other writing tools or for basic text editing.
						</p>
						<div class="space-y-1 text-xs text-text-muted">
							<div>• Universal compatibility</div>
							<div>• Small file size</div>
							<div>• Easy to process programmatically</div>
						</div>
						<div class="mt-4">
							<Button variant="outline" onclick={handle_export_txt}>Export as TXT</Button>
						</div>
					</div>
				</div>
			</div>
		</div>
	</div>
</div>

<!-- RTF Export Modal -->
<ExportModal
	bind:open={show_rtf_export_modal}
	project={current_project}
	format="rtf"
	onClose={() => (show_rtf_export_modal = false)}
/>

<!-- TXT Export Modal -->
<ExportModal
	bind:open={show_txt_export_modal}
	project={current_project}
	format="txt"
	onClose={() => (show_txt_export_modal = false)}
/>

<style>
	.line-clamp-3 {
		display: -webkit-box;
		line-clamp: 3;
		-webkit-line-clamp: 3;
		-webkit-box-orient: vertical;
		overflow: hidden;
	}
</style>
