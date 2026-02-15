<script lang="ts">
	import type { Project } from '$lib/state/projects.svelte.js';
	import type { ExportOptions } from '$lib/services/export/types.js';
	import type { EpubTemplateDefinition } from '$lib/services/export/epub/types.js';
	import { export_service } from '$lib/services/export/export_service.js';
	import { Button, Input, Label } from '$lib/components/ui';
	import { Dialog } from 'bits-ui';

	let {
		project,
		open = $bindable(false),
		format,
		onClose
	}: {
		project: Project;
		open: boolean;
		format: 'rtf' | 'txt' | 'epub';
		onClose: () => void;
	} = $props();
	const get_project = () => project;

	let export_options = $state<ExportOptions>({
		include_title: true,
		include_chapter_titles: true,
		include_scene_titles: true,
		include_word_count: false,
		format: 'rtf'
	});
	const epub_templates: EpubTemplateDefinition[] = export_service.get_epub_templates();
	const epub_language_options = [
		{ code: 'en', label: 'English' },
		{ code: 'de', label: 'German' },
		{ code: 'fr', label: 'French' },
		{ code: 'es', label: 'Spanish' },
		{ code: 'it', label: 'Italian' },
		{ code: 'pt', label: 'Portuguese' },
		{ code: 'nl', label: 'Dutch' }
	] as const;

	let selected_template_name = $state(epub_templates[0]?.key || '');
	let epub_author = $state(get_project().epub_metadata?.author || '');
	let epub_publisher = $state(get_project().epub_metadata?.publisher || '');
	let epub_language = $state(get_project().epub_metadata?.language || 'en');
	let epub_rights = $state(get_project().epub_metadata?.rights || '');
	let epub_subjects_input = $state(get_project().epub_metadata?.subjects.join(', ') || '');

	let is_exporting = $state(false);
	let export_error = $state<string | null>(null);

	const selected_template = $derived(
		epub_templates.find((template) => template.key === selected_template_name) || null
	);

	function parse_subjects(subjects_input: string): string[] {
		return subjects_input
			.split(',')
			.map((subject) => subject.trim())
			.filter((subject) => subject.length > 0);
	}

	async function handle_export() {
		if (!project) {
			export_error = 'No project available for export';
			return;
		}

		is_exporting = true;
		export_error = null;

		try {
			export_options.format = format;

			if (format === 'epub') {
				export_options.epub = {
					template_name: selected_template_name || undefined,
					metadata: {
						author: epub_author.trim(),
						publisher: epub_publisher.trim(),
						language: epub_language.trim() || 'en',
						rights: epub_rights.trim(),
						subjects: parse_subjects(epub_subjects_input)
					}
				};
			} else {
				export_options.epub = undefined;
			}

			await export_service.export_project(project, export_options);
			onClose();
		} catch (error) {
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
			class="data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0 fixed inset-0 z-50 grid h-[100vh] w-[100vw] max-w-none grid-rows-[auto,1fr] border-0 bg-background p-0 shadow-lg duration-200"
		>
			<div class="border-b border-border px-6 py-4">
				<Dialog.Title class="text-lg font-semibold text-text">
					Export as {format === 'rtf' ? 'RTF' : format === 'epub' ? 'EPUB' : 'Plain Text'}
				</Dialog.Title>
			</div>

			<div class="overflow-y-auto px-6 py-6">
				<div class="mx-auto w-full max-w-6xl space-y-6">
					<div class="rounded-lg border border-border bg-background-tertiary p-4">
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
							<h3 class="text-sm font-medium text-paper-text">
								{format === 'rtf'
									? 'Rich Text Format (RTF)'
									: format === 'epub'
										? 'EPUB eBook'
										: 'Plain Text (TXT)'}
							</h3>
						</div>
						<p class="mt-2 text-sm text-paper-text-light">
							{format === 'rtf'
								? 'Export your project as a formatted RTF document that preserves formatting and can be opened in most word processors like Microsoft Word, Google Docs, or Pages.'
								: format === 'epub'
									? 'Export your project as a professional EPUB eBook file that can be read on e-readers, tablets, and smartphones. Includes proper formatting, navigation, and metadata.'
									: 'Export your project as a simple text file with minimal formatting. Perfect for importing into other writing tools or for basic text editing.'}
						</p>
					</div>

					<div class="rounded-lg border border-border bg-background p-4">
						<div class="mb-3 block text-sm font-semibold text-text">Include in Export</div>
						<div class="space-y-2">
							<label
								class="flex cursor-pointer items-center rounded-md px-2 py-1 hover:bg-background-tertiary"
							>
								<input
									id="include-title"
									type="checkbox"
									bind:checked={export_options.include_title}
									class="h-4 w-4 rounded border-paper-border text-paper-accent focus:ring-paper-accent"
								/>
								<span class="ml-2 text-sm text-paper-text">Project Title</span>
							</label>
							<label
								class="flex cursor-pointer items-center rounded-md px-2 py-1 hover:bg-background-tertiary"
							>
								<input
									id="include-chapters"
									type="checkbox"
									bind:checked={export_options.include_chapter_titles}
									class="h-4 w-4 rounded border-paper-border text-paper-accent focus:ring-paper-accent"
								/>
								<span class="ml-2 text-sm text-paper-text">Chapter Titles</span>
							</label>
							<label
								class="flex cursor-pointer items-center rounded-md px-2 py-1 hover:bg-background-tertiary"
							>
								<input
									id="include-scenes"
									type="checkbox"
									bind:checked={export_options.include_scene_titles}
									class="h-4 w-4 rounded border-paper-border text-paper-accent focus:ring-paper-accent"
								/>
								<span class="ml-2 text-sm text-paper-text">Scene Titles</span>
							</label>
							<label
								class="flex cursor-pointer items-center rounded-md px-2 py-1 hover:bg-background-tertiary"
							>
								<input
									id="include-wordcount"
									type="checkbox"
									bind:checked={export_options.include_word_count}
									class="h-4 w-4 rounded border-paper-border text-paper-accent focus:ring-paper-accent"
								/>
								<span class="ml-2 text-sm text-paper-text">Word Count (per scene)</span>
							</label>
						</div>
					</div>

					{#if format === 'epub'}
						<div class="rounded-lg border border-accent/30 bg-surface p-4">
							<div class="mb-1 text-sm font-semibold text-text">EPUB Publishing Details</div>
							<p class="mb-4 text-xs text-text-secondary">
								Choose a template and provide metadata for better compatibility across e-readers.
							</p>

							<div class="space-y-4">
								<div class="rounded-md border border-border bg-background p-3">
									<Label for="epub-template" class="mb-2 block text-sm font-medium text-text"
										>Template</Label
									>
									<select
										id="epub-template"
										bind:value={selected_template_name}
										class="h-10 w-full rounded-md border border-border bg-background px-3 text-sm text-text focus:border-accent focus:outline-none"
									>
										{#each epub_templates as template (template.key)}
											<option value={template.key}>{template.name}</option>
										{/each}
									</select>
									{#if selected_template}
										<p class="mt-2 text-xs text-text-secondary">{selected_template.description}</p>
									{/if}
								</div>

								<div class="rounded-md border border-border bg-background p-3">
									<div class="mb-3 text-sm font-medium text-text">Metadata</div>
									<div class="grid grid-cols-1 gap-3 sm:grid-cols-2">
										<div class="grid gap-1">
											<Label for="epub-author">Author</Label>
											<Input id="epub-author" bind:value={epub_author} placeholder="Author name" />
										</div>
										<div class="grid gap-1">
											<Label for="epub-publisher">Publisher</Label>
											<Input
												id="epub-publisher"
												bind:value={epub_publisher}
												placeholder="Publisher"
											/>
										</div>
										<div class="grid gap-1">
											<Label for="epub-language">Language</Label>
											<select
												id="epub-language"
												bind:value={epub_language}
												class="h-10 w-full rounded-md border border-border bg-background px-3 text-sm text-text focus:border-accent focus:outline-none"
											>
												{#each epub_language_options as language_option (language_option.code)}
													<option value={language_option.code}>{language_option.label}</option>
												{/each}
											</select>
										</div>
										<div class="grid gap-1">
											<Label for="epub-rights">Rights</Label>
											<Input
												id="epub-rights"
												bind:value={epub_rights}
												placeholder="Copyright or rights statement"
											/>
										</div>
										<div class="grid gap-1 sm:col-span-2">
											<Label for="epub-subjects">Subjects</Label>
											<Input
												id="epub-subjects"
												bind:value={epub_subjects_input}
												placeholder="Fantasy, Adventure, Young Adult"
											/>
											<p class="text-xs text-text-secondary">Separate with commas.</p>
										</div>
									</div>
								</div>
							</div>
						</div>
					{/if}

					<div class="rounded-lg bg-paper-beige p-4">
						<h4 class="mb-2 text-sm font-medium text-paper-text">Project Summary</h4>
						<div class="space-y-1 text-sm text-paper-text-light">
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
											acc +
											chapter.scenes.reduce((sceneAcc, scene) => sceneAcc + scene.wordCount, 0),
										0
									)
									.toLocaleString()}
							</div>
						</div>
					</div>

					{#if export_error}
						<div class="rounded-md border border-accent bg-surface p-4">
							<div class="flex">
								<div class="shrink-0">
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

					<div class="flex justify-end space-x-3 border-t border-paper-border pt-4">
						<Button variant="secondary" onclick={handle_cancel} disabled={is_exporting}>
							Cancel
						</Button>
						<Button variant="primary" onclick={handle_export} disabled={is_exporting}>
							{is_exporting ? 'Exporting...' : 'Export'}
						</Button>
					</div>
				</div>
			</div>
		</Dialog.Content>
	</Dialog.Portal>
</Dialog.Root>
