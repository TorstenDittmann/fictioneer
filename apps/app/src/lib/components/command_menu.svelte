<script lang="ts">
	import { Dialog } from 'bits-ui';
	import { projects } from '$lib/state/projects.svelte';
	import { goto } from '$app/navigation';
	import type { Scene, Chapter } from '$lib/state/projects.svelte';

	interface Props {
		open?: boolean;
		onOpenChange?: (open: boolean) => void;
	}

	let { open = $bindable(false), onOpenChange }: Props = $props();

	let search_query = $state('');
	let selected_index = $state(0);

	interface CommandItem {
		id: string;
		title: string;
		subtitle?: string;
		action: () => void;
		type: 'scene' | 'chapter' | 'navigation' | 'action' | 'recent';
		icon: string;
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
				action: () => goto(`/${current_project.id}/${scene_data.chapter_id}/${scene_data.id}`),
				type: 'recent',
				icon: 'M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z'
			});
		});

		// Navigation items
		items.push({
			id: 'overview',
			title: 'Project Overview',
			subtitle: 'Go to project dashboard',
			action: () => goto(`/${current_project.id}`),
			type: 'navigation',
			icon: 'M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2H5a2 2 0 00-2-2z'
		});

		items.push({
			id: 'settings',
			title: 'Project Settings',
			subtitle: 'Configure project preferences',
			action: () => goto(`/${current_project.id}/settings`),
			type: 'navigation',
			icon: 'M12 6V4m0 2a2 2 0 100 4m0-4a2 2 0 110 4m-6 8a2 2 0 100-4m0 4a2 2 0 100 4m0-4v2m0-6V4m6 6v10m6-2a2 2 0 100-4m0 4a2 2 0 100 4m0-4v2m0-6V4'
		});

		// Action items
		items.push({
			id: 'new-chapter',
			title: 'New Chapter',
			subtitle: 'Create a new chapter',
			action: () => {
				projects.createChapter();
				goto(`/${current_project.id}`);
			},
			type: 'action',
			icon: 'M12 6v6m0 0v6m0-6h6m-6 0H6'
		});

		items.push({
			id: 'new-scene',
			title: 'New Scene',
			subtitle: 'Create a new scene in current chapter',
			action: () => {
				const active_chapter = projects.activeChapter;
				if (active_chapter) {
					const scene_id = projects.createScene(active_chapter.id);
					goto(`/${current_project.id}/${active_chapter.id}/${scene_id}`);
				} else if (current_project.chapters.length > 0) {
					const first_chapter = current_project.chapters[0];
					const scene_id = projects.createScene(first_chapter.id);
					goto(`/${current_project.id}/${first_chapter.id}/${scene_id}`);
				} else {
					const chapter_id = projects.createChapter();
					const scene_id = projects.createScene(chapter_id);
					goto(`/${current_project.id}/${chapter_id}/${scene_id}`);
				}
			},
			type: 'action',
			icon: 'M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z'
		});

		items.push({
			id: 'toggle-distraction-free',
			title: 'Toggle Distraction Free Mode',
			subtitle: projects.isDistractionFree
				? 'Exit distraction free mode'
				: 'Enter distraction free mode',
			action: () => projects.toggleDistractionFree(),
			type: 'action',
			icon: projects.isDistractionFree
				? 'M15 12a3 3 0 11-6 0 3 3 0 016 0z'
				: 'M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.878 9.878L3 3m6.878 6.878L21 21'
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
						action: () => goto(`/${current_project.id}/${chapter.id}/${scene.id}`),
						type: 'scene',
						icon: 'M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z'
					});
				}
			});
		});

		return items;
	});

	// Filter items based on search query
	const filtered_items = $derived.by(() => {
		if (!search_query.trim()) return command_items;

		const query = search_query.toLowerCase().trim();
		return command_items.filter(
			(item) =>
				item.title.toLowerCase().includes(query) || item.subtitle?.toLowerCase().includes(query)
		);
	});

	// Group items for display
	const grouped_items = $derived.by(() => {
		const groups = {
			recent: filtered_items.filter((item) => item.type === 'recent'),
			navigation: filtered_items.filter((item) => item.type === 'navigation'),
			action: filtered_items.filter((item) => item.type === 'action'),
			scene: filtered_items.filter((item) => item.type === 'scene')
		};
		return groups;
	});

	// Handle keyboard navigation
	function handle_keydown(event: KeyboardEvent) {
		if (!open) return;

		switch (event.key) {
			case 'ArrowDown':
				event.preventDefault();
				selected_index = Math.min(selected_index + 1, filtered_items.length - 1);
				break;
			case 'ArrowUp':
				event.preventDefault();
				selected_index = Math.max(selected_index - 1, 0);
				break;
			case 'Enter':
				event.preventDefault();
				if (filtered_items[selected_index]) {
					execute_command(filtered_items[selected_index]);
				}
				break;
			case 'Escape':
				event.preventDefault();
				close_menu();
				break;
		}
	}

	function execute_command(item: CommandItem) {
		item.action();
		close_menu();
	}

	function close_menu() {
		open = false;
		onOpenChange?.(false);
		search_query = '';
		selected_index = 0;
	}

	function reset_selection() {
		selected_index = 0;
	}

	// Reset selection when search changes
	$effect(() => {
		void search_query;
		reset_selection();
	});

	function get_type_label(type: string): string {
		switch (type) {
			case 'recent':
				return 'Recent';
			case 'scene':
				return 'Scene';
			case 'chapter':
				return 'Chapter';
			case 'navigation':
				return 'Navigate';
			case 'action':
				return 'Action';
			default:
				return '';
		}
	}

	function get_type_color(type: string): string {
		switch (type) {
			case 'recent':
				return 'bg-gray-200 text-gray-900';
			case 'scene':
				return 'bg-gray-100 text-gray-900';
			case 'chapter':
				return 'bg-gray-200 text-gray-900';
			case 'navigation':
				return 'bg-gray-700 text-gray-100';
			case 'action':
				return 'bg-gray-700 text-gray-100';
			default:
				return 'bg-gray-100 text-gray-900';
		}
	}
</script>

<svelte:window onkeydown={handle_keydown} />

<Dialog.Root bind:open {onOpenChange}>
	<Dialog.Portal>
		<Dialog.Overlay class="fixed inset-0 z-50 bg-gray-900/50 backdrop-blur-sm" />
		<Dialog.Content
			class="fixed top-1/2 left-1/2 z-50 w-full max-w-2xl -translate-x-1/2 -translate-y-1/2 transform"
		>
			<div class="rounded-lg border border-gray-200 bg-white shadow-xl">
				<!-- Search Input -->
				<div class="border-b border-gray-200 px-4 py-3">
					<div class="flex items-center gap-3">
						<svg
							class="h-5 w-5 text-gray-400"
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
						<input
							bind:value={search_query}
							placeholder="Search scenes, chapters, or actions..."
							class="flex-1 bg-transparent text-lg text-gray-900 placeholder-gray-500 outline-none"
						/>
						<div class="flex items-center gap-1">
							<kbd class="rounded bg-gray-100 px-2 py-1 text-xs font-medium text-gray-600">
								ESC
							</kbd>
						</div>
					</div>
				</div>

				<!-- Command List -->
				<div class="max-h-96 overflow-y-auto">
					{#if filtered_items.length === 0}
						<div class="p-8 text-center">
							<svg
								class="mx-auto h-12 w-12 text-gray-400"
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
							<h3 class="mt-4 text-lg font-medium text-gray-900">No results found</h3>
							<p class="mt-2 text-gray-600">Try adjusting your search terms</p>
						</div>
					{:else}
						<div class="p-2">
							{#if search_query.trim()}
								<!-- Show flat list when searching -->
								{#each filtered_items as item, index (item.id)}
									<button
										class="flex w-full items-center gap-3 rounded-lg p-3 text-left transition-colors duration-150 {index ===
										selected_index
											? 'bg-gray-100'
											: 'hover:bg-gray-100'}"
										onclick={() => execute_command(item)}
										onmouseenter={() => (selected_index = index)}
									>
										<!-- Icon -->
										<div
											class="flex h-8 w-8 flex-shrink-0 items-center justify-center rounded-md {index ===
											selected_index
												? 'bg-gray-200 text-gray-700'
												: 'bg-gray-100 text-gray-600'}"
										>
											<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
												<path
													stroke-linecap="round"
													stroke-linejoin="round"
													stroke-width="2"
													d={item.icon}
												/>
											</svg>
										</div>

										<!-- Content -->
										<div class="min-w-0 flex-1">
											<div class="flex items-center gap-2">
												<span
													class="font-medium text-gray-900 {index === selected_index
														? 'text-gray-900'
														: ''}"
												>
													{item.title}
												</span>
												<span
													class="rounded-full px-2 py-0.5 text-xs font-medium {get_type_color(
														item.type
													)}"
												>
													{get_type_label(item.type)}
												</span>
											</div>
											{#if item.subtitle}
												<p
													class="mt-1 text-sm text-gray-600 {index === selected_index
														? 'text-gray-700'
														: ''}"
												>
													{item.subtitle}
												</p>
											{/if}
										</div>

										<!-- Keyboard hint -->
										{#if index === selected_index}
											<div class="flex items-center gap-1">
												<kbd
													class="rounded bg-gray-200 px-2 py-1 text-xs font-medium text-gray-700"
												>
													↵
												</kbd>
											</div>
										{/if}
									</button>
								{/each}
							{:else}
								<!-- Show grouped items when no search -->
								{@const groups = grouped_items}

								{#if groups.recent.length > 0}
									<div class="mb-2">
										<div class="px-3 py-1 text-xs font-medium text-gray-500">Recent</div>
										{#each groups.recent as item, local_index (item.id)}
											{@const global_index = local_index}
											<button
												class="flex w-full items-center gap-3 rounded-lg p-3 text-left transition-colors duration-150 {global_index ===
												selected_index
													? 'bg-gray-100'
													: 'hover:bg-gray-50'}"
												onclick={() => execute_command(item)}
												onmouseenter={() => (selected_index = global_index)}
											>
												<!-- Icon -->
												<div
													class="flex h-8 w-8 flex-shrink-0 items-center justify-center rounded-md {global_index ===
													selected_index
														? 'bg-gray-200 text-gray-700'
														: 'bg-gray-100 text-gray-600'}"
												>
													<svg
														class="h-4 w-4"
														fill="none"
														stroke="currentColor"
														viewBox="0 0 24 24"
													>
														<path
															stroke-linecap="round"
															stroke-linejoin="round"
															stroke-width="2"
															d={item.icon}
														/>
													</svg>
												</div>

												<!-- Content -->
												<div class="min-w-0 flex-1">
													<div class="flex items-center gap-2">
														<span
															class="font-medium text-gray-900 {global_index === selected_index
																? 'text-gray-900'
																: ''}"
														>
															{item.title}
														</span>
														<span
															class="rounded-full px-2 py-0.5 text-xs font-medium {get_type_color(
																item.type
															)}"
														>
															{get_type_label(item.type)}
														</span>
													</div>
													{#if item.subtitle}
														<p
															class="mt-1 text-sm text-gray-600 {global_index === selected_index
																? 'text-gray-700'
																: ''}"
														>
															{item.subtitle}
														</p>
													{/if}
												</div>

												<!-- Keyboard hint -->
												{#if global_index === selected_index}
													<div class="flex items-center gap-1">
														<kbd
															class="rounded bg-gray-200 px-2 py-1 text-xs font-medium text-gray-700"
														>
															↵
														</kbd>
													</div>
												{/if}
											</button>
										{/each}
									</div>
								{/if}

								{#if groups.navigation.length > 0}
									<div class="mb-2">
										<div class="px-3 py-1 text-xs font-medium text-gray-500">Navigate</div>
										{#each groups.navigation as item, local_index (item.id)}
											{@const global_index = groups.recent.length + local_index}
											<button
												class="flex w-full items-center gap-3 rounded-lg p-3 text-left transition-colors duration-150 {global_index ===
												selected_index
													? 'bg-gray-100'
													: 'hover:bg-gray-50'}"
												onclick={() => execute_command(item)}
												onmouseenter={() => (selected_index = global_index)}
											>
												<!-- Icon -->
												<div
													class="flex h-8 w-8 flex-shrink-0 items-center justify-center rounded-md {global_index ===
													selected_index
														? 'bg-gray-200 text-gray-700'
														: 'bg-gray-100 text-gray-600'}"
												>
													<svg
														class="h-4 w-4"
														fill="none"
														stroke="currentColor"
														viewBox="0 0 24 24"
													>
														<path
															stroke-linecap="round"
															stroke-linejoin="round"
															stroke-width="2"
															d={item.icon}
														/>
													</svg>
												</div>

												<!-- Content -->
												<div class="min-w-0 flex-1">
													<div class="flex items-center gap-2">
														<span
															class="font-medium text-gray-900 {global_index === selected_index
																? 'text-gray-900'
																: ''}"
														>
															{item.title}
														</span>
														<span
															class="rounded-full px-2 py-0.5 text-xs font-medium {get_type_color(
																item.type
															)}"
														>
															{get_type_label(item.type)}
														</span>
													</div>
													{#if item.subtitle}
														<p
															class="mt-1 text-sm text-gray-600 {global_index === selected_index
																? 'text-gray-700'
																: ''}"
														>
															{item.subtitle}
														</p>
													{/if}
												</div>

												<!-- Keyboard hint -->
												{#if global_index === selected_index}
													<div class="flex items-center gap-1">
														<kbd
															class="rounded bg-gray-200 px-2 py-1 text-xs font-medium text-gray-700"
														>
															↵
														</kbd>
													</div>
												{/if}
											</button>
										{/each}
									</div>
								{/if}

								{#if groups.action.length > 0}
									<div class="mb-2">
										<div class="px-3 py-1 text-xs font-medium text-gray-500">Actions</div>
										{#each groups.action as item, local_index (item.id)}
											{@const global_index =
												groups.recent.length + groups.navigation.length + local_index}
											<button
												class="flex w-full items-center gap-3 rounded-lg p-3 text-left transition-colors duration-150 {global_index ===
												selected_index
													? 'bg-gray-100'
													: 'hover:bg-gray-50'}"
												onclick={() => execute_command(item)}
												onmouseenter={() => (selected_index = global_index)}
											>
												<!-- Icon -->
												<div
													class="flex h-8 w-8 flex-shrink-0 items-center justify-center rounded-md {global_index ===
													selected_index
														? 'bg-gray-200 text-gray-700'
														: 'bg-gray-100 text-gray-600'}"
												>
													<svg
														class="h-4 w-4"
														fill="none"
														stroke="currentColor"
														viewBox="0 0 24 24"
													>
														<path
															stroke-linecap="round"
															stroke-linejoin="round"
															stroke-width="2"
															d={item.icon}
														/>
													</svg>
												</div>

												<!-- Content -->
												<div class="min-w-0 flex-1">
													<div class="flex items-center gap-2">
														<span
															class="font-medium text-gray-900 {global_index === selected_index
																? 'text-gray-900'
																: ''}"
														>
															{item.title}
														</span>
														<span
															class="rounded-full px-2 py-0.5 text-xs font-medium {get_type_color(
																item.type
															)}"
														>
															{get_type_label(item.type)}
														</span>
													</div>
													{#if item.subtitle}
														<p
															class="mt-1 text-sm text-gray-600 {global_index === selected_index
																? 'text-gray-700'
																: ''}"
														>
															{item.subtitle}
														</p>
													{/if}
												</div>

												<!-- Keyboard hint -->
												{#if global_index === selected_index}
													<div class="flex items-center gap-1">
														<kbd
															class="rounded bg-gray-200 px-2 py-1 text-xs font-medium text-gray-700"
														>
															↵
														</kbd>
													</div>
												{/if}
											</button>
										{/each}
									</div>
								{/if}

								{#if groups.scene.length > 0}
									<div class="mb-2">
										<div class="px-3 py-1 text-xs font-medium text-gray-500">All Scenes</div>
										{#each groups.scene as item, local_index (item.id)}
											{@const global_index =
												groups.recent.length +
												groups.navigation.length +
												groups.action.length +
												local_index}
											<button
												class="flex w-full items-center gap-3 rounded-lg p-3 text-left transition-colors duration-150 {global_index ===
												selected_index
													? 'bg-gray-100'
													: 'hover:bg-gray-50'}"
												onclick={() => execute_command(item)}
												onmouseenter={() => (selected_index = global_index)}
											>
												<!-- Icon -->
												<div
													class="flex h-8 w-8 flex-shrink-0 items-center justify-center rounded-md {global_index ===
													selected_index
														? 'bg-gray-200 text-gray-700'
														: 'bg-gray-100 text-gray-600'}"
												>
													<svg
														class="h-4 w-4"
														fill="none"
														stroke="currentColor"
														viewBox="0 0 24 24"
													>
														<path
															stroke-linecap="round"
															stroke-linejoin="round"
															stroke-width="2"
															d={item.icon}
														/>
													</svg>
												</div>

												<!-- Content -->
												<div class="min-w-0 flex-1">
													<div class="flex items-center gap-2">
														<span
															class="font-medium text-gray-900 {global_index === selected_index
																? 'text-gray-900'
																: ''}"
														>
															{item.title}
														</span>
														<span
															class="rounded-full px-2 py-0.5 text-xs font-medium {get_type_color(
																item.type
															)}"
														>
															{get_type_label(item.type)}
														</span>
													</div>
													{#if item.subtitle}
														<p
															class="mt-1 text-sm text-gray-600 {global_index === selected_index
																? 'text-gray-700'
																: ''}"
														>
															{item.subtitle}
														</p>
													{/if}
												</div>

												<!-- Keyboard hint -->
												{#if global_index === selected_index}
													<div class="flex items-center gap-1">
														<kbd
															class="rounded bg-gray-200 px-2 py-1 text-xs font-medium text-gray-700"
														>
															↵
														</kbd>
													</div>
												{/if}
											</button>
										{/each}
									</div>
								{/if}
							{/if}
						</div>
					{/if}
				</div>

				<!-- Footer -->
				<div class="border-t border-gray-200 px-4 py-2">
					<div class="flex items-center justify-between text-xs text-gray-500">
						<div class="flex items-center gap-4">
							<div class="flex items-center gap-1">
								<kbd class="rounded bg-gray-100 px-1.5 py-0.5 font-mono">↑</kbd>
								<kbd class="rounded bg-gray-100 px-1.5 py-0.5 font-mono">↓</kbd>
								<span>to navigate</span>
							</div>
							<div class="flex items-center gap-1">
								<kbd class="rounded bg-gray-100 px-1.5 py-0.5 font-mono">↵</kbd>
								<span>to select</span>
							</div>
						</div>
						<div class="flex items-center gap-1">
							<kbd class="rounded bg-gray-100 px-1.5 py-0.5 font-mono">ESC</kbd>
							<span>to close</span>
						</div>
					</div>
				</div>
			</div>
		</Dialog.Content>
	</Dialog.Portal>
</Dialog.Root>
