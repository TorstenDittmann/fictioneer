<script lang="ts">
	import { save } from '@tauri-apps/plugin-dialog';
	import { Modal, Input, Textarea, Button, Label } from '$lib/components/ui';

	interface Props {
		open: boolean;
		onCreate?: (title: string, description: string, filePath: string) => Promise<void>;
		onCancel?: () => void;
	}

	let { open = $bindable(), onCreate, onCancel }: Props = $props();

	let project_title = $state('');
	let project_description = $state('');
	let selected_file_path = $state('');
	let is_creating = $state(false);

	// Reset form when modal opens
	$effect(() => {
		if (open) {
			project_title = '';
			project_description = '';
			selected_file_path = '';
			is_creating = false;
		}
	});

	async function handle_choose_location() {
		try {
			const suggested_filename =
				sanitize_filename(project_title || 'Untitled Project') + '.fictioneer';

			const file_path = await save({
				defaultPath: suggested_filename,
				filters: [
					{
						name: 'Fictioneer Project Files',
						extensions: ['fictioneer']
					}
				]
			});

			if (file_path) {
				selected_file_path = file_path;
			}
		} catch (error) {
			console.error('Failed to choose save location:', error);
		}
	}

	async function handle_create() {
		if (!project_title.trim()) {
			return;
		}

		if (!selected_file_path) {
			await handle_choose_location();
			if (!selected_file_path) return; // User cancelled file dialog
		}

		if (onCreate) {
			is_creating = true;
			try {
				await onCreate(project_title.trim(), project_description.trim(), selected_file_path);
				open = false;
			} catch (error) {
				console.error('Failed to create project:', error);
			} finally {
				is_creating = false;
			}
		}
	}

	function handle_cancel() {
		if (onCancel) {
			onCancel();
		}
		open = false;
	}

	function sanitize_filename(filename: string): string {
		return filename
			.replace(/[<>:"/\\|?*]/g, '_')
			.replace(/\s+/g, '_')
			.trim()
			.substring(0, 50);
	}

	function get_filename_from_path(path: string): string {
		return path.split('/').pop() || path;
	}
</script>

<Modal bind:open>
	<div class="grid gap-6">
		<div>
			<h2 class="text-lg font-semibold text-text">Create New Project</h2>
			<p class="text-sm text-text-secondary">
				Set up your new writing project. Choose a title, description, and save location.
			</p>
		</div>

		<div class="grid gap-4">
			<!-- Project Title -->
			<div class="grid gap-2">
				<Label for="project-title">Project Title</Label>
				<Input
					bind:value={project_title}
					id="project-title"
					placeholder="My Novel"
					required
					disabled={is_creating}
				/>
			</div>

			<!-- Project Description -->
			<div class="grid gap-2">
				<Label for="project-description">Description</Label>
				<Textarea
					bind:value={project_description}
					id="project-description"
					placeholder="A story about..."
					rows={3}
					disabled={is_creating}
				/>
			</div>

			<!-- Save Location -->
			<div class="grid gap-2">
				<Label for="save-location">Save Location</Label>
				<div class="flex gap-2">
					<Input
						id="save-location"
						value={selected_file_path ? get_filename_from_path(selected_file_path) : ''}
						placeholder="Choose where to save your project..."
						readonly
					/>
					<Button variant="secondary" onclick={handle_choose_location} disabled={is_creating}>
						Browse
					</Button>
				</div>
				{#if selected_file_path}
					<p class="text-xs text-text-muted" title={selected_file_path}>
						{selected_file_path}
					</p>
				{/if}
			</div>
		</div>

		<div class="flex flex-col gap-4">
			<div class="flex flex-col-reverse sm:flex-row sm:justify-end sm:space-x-2">
				<Button variant="secondary" onclick={handle_cancel} disabled={is_creating}>Cancel</Button>
				<Button onclick={handle_create} disabled={is_creating || !project_title.trim()}>
					{#if is_creating}
						Creating...
					{:else}
						Create Project
					{/if}
				</Button>
			</div>

			<div class="border-t border-border pt-4 text-center">
				<p class="text-xs text-text-muted">
					Press <kbd class="rounded bg-background-tertiary px-1">⌘Enter</kbd> to create
				</p>
			</div>
		</div>
	</div>
</Modal>
