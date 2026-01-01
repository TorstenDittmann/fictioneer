<script lang="ts">
	import { Command, Dialog } from 'bits-ui';
	import { projects } from '$lib/state/projects.svelte';
	import { layout_state } from '$lib/state/layout.svelte';
	import { license_key_state } from '$lib/state/license_key.svelte';
	import { goto } from '$app/navigation';
	import { resolve } from '$app/paths';
	import LicenseKeyModal from '$lib/components/license_key_modal.svelte';
	import type { Scene, Chapter } from '$lib/state/projects.svelte';

	interface Props {
		open?: boolean;
		onOpenChange?: (open: boolean) => void;
	}

	let { open = $bindable(false), onOpenChange }: Props = $props();

	let license_key_modal_open = $state(false);

	interface CommandItem {
		id: string;
		title: string;
		subtitle?: string;
		action: () => void;
		type: 'scene' | 'chapter' | 'navigation' | 'action' | 'recent';
		icon: string;
		keywords: string[];
	}

	// Get current project and build command items
	const current_project = $derived(projects.project);

	const command_items = $derived.by(() => {
		const items: CommandItem[] = [];

		if (!current_project) return items;

		// Get recent scenes for prioritization
		const recent_scenes = projects.recentScenes;

		// Recent scenes (priority items)
		recent_scenes.slice(0, 3).forEach((scene_data) => {
			items.push({
				id: `recent-scene-${scene_data.id}`,
				title: scene_data.title,
				subtitle: `Recent • ${scene_data.chapter_title} • ${scene_data.wordCount} words`,
				action: () => {
					goto(
						resolve('/[projectId]/[chapterId]/[sceneId]', {
							projectId: current_project.id,
							chapterId: scene_data.chapter_id,
							sceneId: scene_data.id
						})
					);
					close_menu();
				},
				type: 'recent',
				icon: 'M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z',
				keywords: ['recent', 'scene', scene_data.title, scene_data.chapter_title]
			});
		});

		// Navigation items
		items.push({
			id: 'overview',
			title: 'Project Overview',
			subtitle: 'Go to project dashboard',
			action: () => {
				goto(
					resolve('/[projectId]', {
						projectId: current_project.id
					})
				);
				close_menu();
			},
			type: 'navigation',
			icon: 'M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2H5a2 2 0 00-2-2z',
			keywords: ['overview', 'dashboard', 'project', 'home']
		});

		items.push({
			id: 'settings',
			title: 'Project Settings',
			subtitle: 'Configure project preferences',
			action: () => {
				goto(
					resolve('/[projectId]/settings', {
						projectId: current_project.id
					})
				);
				close_menu();
			},
			type: 'navigation',
			icon: 'M12 6V4m0 2a2 2 0 100 4m0-4a2 2 0 110 4m-6 8a2 2 0 100-4m0 4a2 2 0 100 4m0-4v2m0-6V4m6 6v10m6-2a2 2 0 100-4m0 4a2 2 0 100 4m0-4v2m0-6V4',
			keywords: ['settings', 'preferences', 'configure', 'options']
		});

		// Action items
		items.push({
			id: 'new-chapter',
			title: 'New Chapter',
			subtitle: 'Create a new chapter',
			action: () => {
				projects.createChapter();
				goto(
					resolve('/[projectId]', {
						projectId: current_project.id
					})
				);
				close_menu();
			},
			type: 'action',
			icon: 'M12 6v6m0 0v6m0-6h6m-6 0H6',
			keywords: ['new', 'create', 'chapter', 'add']
		});

		items.push({
			id: 'new-scene',
			title: 'New Scene',
			subtitle: 'Create a new scene in current chapter',
			action: () => {
				const active_chapter = projects.activeChapter;
				if (active_chapter) {
					const scene_id = projects.createScene(active_chapter.id);
					goto(
						resolve('/[projectId]/[chapterId]/[sceneId]', {
							projectId: current_project.id,
							chapterId: active_chapter.id,
							sceneId: scene_id
						})
					);
				} else if (current_project.chapters.length > 0) {
					const first_chapter = current_project.chapters[0];
					const scene_id = projects.createScene(first_chapter.id);
					goto(
						resolve('/[projectId]/[chapterId]/[sceneId]', {
							projectId: current_project.id,
							chapterId: first_chapter.id,
							sceneId: scene_id
						})
					);
				} else {
					const chapter_id = projects.createChapter();
					const scene_id = projects.createScene(chapter_id);
					goto(
						resolve('/[projectId]/[chapterId]/[sceneId]', {
							projectId: current_project.id,
							chapterId: chapter_id,
							sceneId: scene_id
						})
					);
				}
				close_menu();
			},
			type: 'action',
			icon: 'M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z',
			keywords: ['new', 'create', 'scene', 'add', 'write']
		});

		items.push({
			id: 'toggle-distraction-free',
			title: 'Toggle Distraction Free Mode',
			subtitle: layout_state.is_distraction_free
				? 'Exit distraction free mode'
				: 'Enter distraction free mode',
			action: () => {
				layout_state.toggle_distraction_free();
				close_menu();
			},
			type: 'action',
			icon: layout_state.is_distraction_free
				? 'M15 12a3 3 0 11-6 0 3 3 0 016 0z'
				: 'M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.878 9.878L3 3m6.878 6.878L21 21',
			keywords: ['distraction', 'free', 'focus', 'mode', 'toggle', 'zen']
		});

		items.push({
			id: 'ai-license-key',
			title: 'AI License Key',
			subtitle: license_key_state.has_license_key
				? license_key_state.is_valid
					? 'License key is valid'
					: 'License key needs verification'
				: 'Configure AI license key',
			action: () => {
				license_key_modal_open = true;
				close_menu();
			},
			type: 'action',
			icon: 'M15.75 5.25a3 3 0 013 3m3 0a6 6 0 01-7.029 5.912c-.563-.097-.91-.56-.91-1.128v-.55m5.939 4.77a4.5 4.5 0 01-7.5-2.221c0-.52.35-.99.85-1.1l.5-.1M8.25 5.25a3 3 0 00-3 3m0 0a6 6 0 007.029 5.912c.563-.097.91-.56.91-1.128v-.55m-5.939 4.77a4.5 4.5 0 007.5-2.221c0-.52-.35-.99-.85-1.1l-.5-.1',
			keywords: ['ai', 'license', 'key', 'settings', 'configure', 'authentication']
		});

		// Add all scenes from all chapters (excluding recent ones to avoid duplicates)
		const recent_scene_ids = new Set(recent_scenes.map((s) => s.id));
		current_project.chapters.forEach((chapter: Chapter) => {
			chapter.scenes.forEach((scene: Scene) => {
				if (!recent_scene_ids.has(scene.id)) {
					items.push({
						id: `scene-${scene.id}`,
						title: scene.title,
						subtitle: `${chapter.title} • ${scene.wordCount} words`,
						action: () => {
							goto(
								resolve('/[projectId]/[chapterId]/[sceneId]', {
									projectId: current_project.id,
									chapterId: chapter.id,
									sceneId: scene.id
								})
							);
							close_menu();
						},
						type: 'scene',
						icon: 'M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z',
						keywords: ['scene', scene.title, chapter.title, 'write', 'edit']
					});
				}
			});
		});

		return items;
	});

	// Group configurations for rendering
	const GROUP_ORDER: Array<{ key: CommandItem['type']; label: string }> = [
		{ key: 'recent', label: 'Recent' },
		{ key: 'navigation', label: 'Navigation' },
		{ key: 'action', label: 'Actions' },
		{ key: 'scene', label: 'Scenes' }
	];

	// Group items for display
	const grouped_items = $derived.by(() => {
		return GROUP_ORDER.map((group) => ({
			...group,
			items: command_items.filter((item) => item.type === group.key)
		})).filter((group) => group.items.length > 0);
	});

	function close_menu() {
		open = false;
		if (onOpenChange) {
			onOpenChange(false);
		}
	}
</script>

{#snippet commandItem(item: CommandItem)}
	<Command.Item
		class="flex cursor-pointer items-center gap-3 px-3 py-2.5 text-sm text-text select-none hover:bg-background-tertiary data-selected:bg-background-tertiary"
		value={item.id}
		keywords={item.keywords}
		onSelect={item.action}
	>
		<div class="flex h-8 w-8 items-center justify-center">
			<svg class="h-4 w-4 text-accent" fill="none" stroke="currentColor" viewBox="0 0 24 24">
				<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d={item.icon} />
			</svg>
		</div>
		<div class="min-w-0 flex-1">
			<div class="flex items-center gap-2">
				<span class="truncate font-medium">{item.title}</span>
			</div>
			{#if item.subtitle}
				<p class="truncate text-xs" style="color: var(--color-text-muted);">{item.subtitle}</p>
			{/if}
		</div>
	</Command.Item>
{/snippet}

<Dialog.Root bind:open {onOpenChange}>
	<Dialog.Portal>
		<Dialog.Overlay class="fixed inset-0 z-50 bg-black/50 backdrop-blur-sm" />
		<Dialog.Content
			class="fixed top-[50%] left-[50%] z-50 w-full max-w-[94%] translate-x-[-50%] translate-y-[-50%] sm:max-w-[490px] md:w-full"
		>
			<Dialog.Title class="sr-only">Command Menu</Dialog.Title>
			<Dialog.Description class="sr-only">
				Search and navigate through your project. Use arrow keys to navigate and Enter to select.
			</Dialog.Description>

			<Command.Root
				class="flex h-full w-full flex-col overflow-hidden rounded-lg border shadow-xl outline-none"
				style="background-color: var(--color-surface); border-color: var(--color-border);"
				loop={true}
			>
				<div class="border-b px-4 py-3" style="border-color: var(--color-border);">
					<div class="flex items-center gap-3">
						<svg
							class="h-5 w-5"
							style="color: var(--color-text-muted);"
							fill="none"
							stroke="currentColor"
							viewBox="0 0 24 24"
						>
							<path
								stroke-linecap="round"
								stroke-linejoin="round"
								stroke-width="2"
								d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
							/>
						</svg>
						<Command.Input
							class="flex-1 bg-transparent text-sm"
							style="color: var(--color-text); outline: 0; box-shadow: none; border: none; border-radius: 0;"
							placeholder="Search commands, scenes, and actions..."
						/>
						<div class="flex items-center gap-1">
							<kbd
								class="rounded px-2 py-1 text-xs font-medium"
								style="background-color: var(--color-background-tertiary); color: var(--color-text);"
							>
								Esc
							</kbd>
						</div>
					</div>
				</div>

				<Command.List class="max-h-96 overflow-y-auto">
					<Command.Viewport>
						<Command.Empty
							class="flex w-full items-center justify-center p-8 text-center"
							style="color: var(--color-text-muted);"
						>
							<div>
								<svg
									class="mx-auto h-12 w-12"
									style="color: var(--color-text-muted);"
									fill="none"
									stroke="currentColor"
									viewBox="0 0 24 24"
								>
									<path
										stroke-linecap="round"
										stroke-linejoin="round"
										stroke-width="2"
										d="M9.172 16.172a4 4 0 015.656 0M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
									/>
								</svg>
								<h3 class="mt-4 text-lg font-medium" style="color: var(--color-text);">
									No results found
								</h3>
								<p class="mt-2" style="color: var(--color-text-secondary);">
									Try searching for something else.
								</p>
							</div>
						</Command.Empty>

						{#each grouped_items as group, index (group.key)}
							{#if index > 0}
								<Command.Separator
									class="h-px w-full border-t"
									style="border-color: var(--color-border);"
								/>
							{/if}
							<Command.Group>
								<Command.GroupHeading
									class="px-3 py-2 text-xs font-medium"
									style="color: var(--color-text-muted);"
								>
									{group.label}
								</Command.GroupHeading>
								<Command.GroupItems>
									{#each group.items as item (item.id)}
										{@render commandItem(item)}
									{/each}
								</Command.GroupItems>
							</Command.Group>
						{/each}
					</Command.Viewport>
				</Command.List>

				<div class="border-t px-4 py-2" style="border-color: var(--color-border);">
					<div
						class="flex items-center justify-between text-xs"
						style="color: var(--color-text-muted);"
					>
						<div class="flex items-center gap-4">
							<div class="flex items-center gap-1">
								<kbd
									class="rounded px-1.5 py-0.5 font-mono"
									style="background-color: var(--color-background-tertiary); color: var(--color-text);"
									>↑</kbd
								>
								<kbd
									class="rounded px-1.5 py-0.5 font-mono"
									style="background-color: var(--color-background-tertiary); color: var(--color-text);"
									>↓</kbd
								>
								<span>to navigate</span>
							</div>
							<div class="flex items-center gap-1">
								<kbd
									class="rounded px-1.5 py-0.5 font-mono"
									style="background-color: var(--color-background-tertiary); color: var(--color-text);"
									>↵</kbd
								>
								<span>to select</span>
							</div>
						</div>
						<div class="flex items-center gap-1">
							<kbd
								class="rounded px-1.5 py-0.5 font-mono"
								style="background-color: var(--color-background-tertiary); color: var(--color-text);"
								>esc</kbd
							>
							<span>to close</span>
						</div>
					</div>
				</div>
			</Command.Root>
		</Dialog.Content>
	</Dialog.Portal>
</Dialog.Root>

<LicenseKeyModal bind:open={license_key_modal_open} />
