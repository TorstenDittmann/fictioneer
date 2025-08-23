<script lang="ts">
	import type { Project } from '$lib/services/projects.svelte.js';
	import type { ExportOptions } from '$lib/services/export.svelte.js';
	import { export_service } from '$lib/services/export.svelte.js';
	import { Button } from '$lib/components/ui';
	import { Dialog } from 'bits-ui';

	let {
		project,
		open = $bindable(false),
		format,
		onClose
	}: {
		project: Project;
		open: boolean;
		format: 'rtf' | 'txt';
		onClose: () => void;
	} = $props();

	let export_options = $state<ExportOptions>({
		include_title: true,
		include_chapter_titles: true,
		include_scene_titles: true,
		include_word_count: false,
		format: format
	});

	let is_exporting = $state(false);
	let export_error = $state<string | null>(null);

	async function handle_export() {
		console.log('Export button clicked');
		console.log('Project object:', project);
		console.log('Export options:', export_options);

		if (!project) {
			console.error('No project available for export');
			export_error = 'No project available for export';
			return;
		}

		is_exporting = true;
		export_error = null;

		try {
			console.log('Starting export process...');
			await export_service.export_project(project, export_options);
			console.log('Export completed successfully');
			onClose();
		} catch (error) {
			console.error('Export failed:', error);
			export_error = error instanceof Error ? error.message : 'Export failed. Please try again.';
		} finally {
			is_exporting = false;
		}
	}

	function handle_cancel() {
		onClose();
	}
</script>

<Dialog.Root bind:open>
	<Dialog.Portal>
		<Dialog.Overlay
			class="data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0 fixed inset-0 z-50 bg-black/80"
		/>
		<Dialog.Content
			class="data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0 data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-95 data-[state=closed]:slide-out-to-left-1/2 data-[state=closed]:slide-out-to-top-[48%] data-[state=open]:slide-in-from-left-1/2 data-[state=open]:slide-in-from-top-[48%] fixed top-[50%] left-[50%] z-50 grid w-full max-w-lg translate-x-[-50%] translate-y-[-50%] gap-4 border border-border bg-background p-6 shadow-lg duration-200 sm:rounded-lg"
		>
			<Dialog.Title class="text-lg font-semibold text-text">
				Export as {format === 'rtf' ? 'RTF' : 'Plain Text'}
			</Dialog.Title>

			<div class="space-y-6">
				<!-- Format Info -->
				<div class="mb-6 rounded-lg border border-border bg-background-tertiary p-4">
					<div class="flex items-center">
						<svg
							class="mr-2 h-5 w-5 text-accent"
							fill="none"
							stroke="currentColor"
							viewBox="0 0 24 24"
						>
							<path
								stroke-linecap="round"
								stroke-linejoin="round"
								stroke-width="2"
								d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
							/>
						</svg>
						<h3 class="text-paper-text text-sm font-medium">
							{format === 'rtf' ? 'Rich Text Format (RTF)' : 'Plain Text (TXT)'}
						</h3>
					</div>
					<p class="text-paper-text-light mt-2 text-sm">
						{format === 'rtf'
							? 'Export your project as a formatted RTF document that preserves formatting and can be opened in most word processors like Microsoft Word, Google Docs, or Pages.'
							: 'Export your project as a simple text file with minimal formatting. Perfect for importing into other writing tools or for basic text editing.'}
					</p>
				</div>

				<!-- Export Options -->
				<div>
					<div class="text-paper-text mb-2 block text-sm font-medium">Include in Export</div>
					<div class="space-y-2">
						<label class="flex cursor-pointer items-center">
							<input
								id="include-title"
								type="checkbox"
								bind:checked={export_options.include_title}
								class="text-paper-accent focus:ring-paper-accent border-paper-border h-4 w-4 rounded"
							/>
							<span class="text-paper-text ml-2 text-sm">Project Title</span>
						</label>
						<label class="flex cursor-pointer items-center">
							<input
								id="include-chapters"
								type="checkbox"
								bind:checked={export_options.include_chapter_titles}
								class="text-paper-accent focus:ring-paper-accent border-paper-border h-4 w-4 rounded"
							/>
							<span class="text-paper-text ml-2 text-sm">Chapter Titles</span>
						</label>
						<label class="flex cursor-pointer items-center">
							<input
								id="include-scenes"
								type="checkbox"
								bind:checked={export_options.include_scene_titles}
								class="text-paper-accent focus:ring-paper-accent border-paper-border h-4 w-4 rounded"
							/>
							<span class="text-paper-text ml-2 text-sm">Scene Titles</span>
						</label>
						<label class="flex cursor-pointer items-center">
							<input
								id="include-wordcount"
								type="checkbox"
								bind:checked={export_options.include_word_count}
								class="text-paper-accent focus:ring-paper-accent border-paper-border h-4 w-4 rounded"
							/>
							<span class="text-paper-text ml-2 text-sm">Word Count (per scene)</span>
						</label>
					</div>
				</div>

				<!-- Project Info -->
				<div class="bg-paper-beige rounded-lg p-4">
					<h4 class="text-paper-text mb-2 text-sm font-medium">Project Summary</h4>
					<div class="text-paper-text-light space-y-1 text-sm">
						<div><strong>Title:</strong> {project.title}</div>
						<div><strong>Chapters:</strong> {project.chapters.length}</div>
						<div>
							<strong>Total Scenes:</strong>
							{project.chapters.reduce((acc, chapter) => acc + chapter.scenes.length, 0)}
						</div>
						<div>
							<strong>Total Words:</strong>
							{project.chapters
								.reduce(
									(acc, chapter) =>
										acc + chapter.scenes.reduce((sceneAcc, scene) => sceneAcc + scene.wordCount, 0),
									0
								)
								.toLocaleString()}
						</div>
					</div>
				</div>

				<!-- Error Display -->
				{#if export_error}
					<div class="rounded-md border border-accent bg-surface p-4">
						<div class="flex">
							<div class="flex-shrink-0">
								<svg class="h-5 w-5 text-accent" viewBox="0 0 20 20" fill="currentColor">
									<path
										fill-rule="evenodd"
										d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
										clip-rule="evenodd"
									/>
								</svg>
							</div>
							<div class="ml-3">
								<h3 class="text-sm font-medium text-text">Export Error</h3>
								<div class="mt-2 text-sm text-text-secondary">
									{export_error}
								</div>
							</div>
						</div>
					</div>
				{/if}

				<!-- Actions -->
				<div class="border-paper-border flex justify-end space-x-3 border-t pt-4">
					<Button variant="secondary" onclick={handle_cancel} disabled={is_exporting}>
						Cancel
					</Button>
					<Button variant="primary" onclick={handle_export} disabled={is_exporting}>
						{is_exporting ? 'Exporting...' : 'Export'}
					</Button>
				</div>
			</div>
		</Dialog.Content>
	</Dialog.Portal>
</Dialog.Root>
