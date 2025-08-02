<script lang="ts">
	import { onMount } from 'svelte';
	import { documentStore } from '$lib/stores/documents.svelte.js';
	import Editor from '$lib/components/Editor.svelte';
	import Sidebar from '$lib/components/Sidebar.svelte';
	import Header from '$lib/components/Header.svelte';

	let isSidebarVisible = $state(true);
	let editorComponent = $state<Editor>();
	let editorStats = $state({ words: 0, characters: 0 });

	// Update editor stats periodically
	let statsInterval: ReturnType<typeof setInterval>;

	onMount(() => {
		// Initialize theme from localStorage
		const savedTheme = localStorage.getItem('theme');
		if (
			savedTheme === 'dark' ||
			(!savedTheme && window.matchMedia('(prefers-color-scheme: dark)').matches)
		) {
			document.documentElement.classList.add('dark');
		}

		// Update stats every 2 seconds
		statsInterval = setInterval(() => {
			if (editorComponent) {
				const stats = editorComponent.getStats();
				editorStats = { words: stats.words, characters: stats.characters };
			}
		}, 2000);

		return () => {
			if (statsInterval) {
				clearInterval(statsInterval);
			}
		};
	});

	function toggleSidebar() {
		isSidebarVisible = !isSidebarVisible;
	}

	function handleEditorUpdate() {
		// Update stats immediately on content change
		if (editorComponent) {
			const stats = editorComponent.getStats();
			editorStats = { words: stats.words, characters: stats.characters };
		}
	}

	// Handle keyboard shortcuts
	function handleKeydown(event: KeyboardEvent) {
		// Cmd/Ctrl + B to toggle sidebar
		if ((event.metaKey || event.ctrlKey) && event.key === 'b') {
			event.preventDefault();
			toggleSidebar();
		}

		// Cmd/Ctrl + N to create new document
		if ((event.metaKey || event.ctrlKey) && event.key === 'n') {
			event.preventDefault();
			documentStore.createDocument();
			setTimeout(() => editorComponent?.focus(), 100);
		}

		// Cmd/Ctrl + Shift + F to toggle focus mode
		if ((event.metaKey || event.ctrlKey) && event.shiftKey && event.key === 'F') {
			event.preventDefault();
			documentStore.toggleDistractionFree();
		}

		// ESC to exit focus mode
		if (event.key === 'Escape' && documentStore.isDistractionFree) {
			documentStore.setDistractionFree(false);
		}
	}
</script>

<svelte:window onkeydown={handleKeydown} />

<div class="app flex h-screen flex-col bg-white text-gray-900 dark:bg-gray-900 dark:text-gray-100">
	<!-- Header -->
	{#if !documentStore.isDistractionFree}
		<Header {isSidebarVisible} {editorStats} onToggleSidebar={toggleSidebar} />
	{/if}

	<!-- Main content area -->
	<div class="flex flex-1 overflow-hidden">
		<!-- Sidebar -->
		{#if !documentStore.isDistractionFree}
			<Sidebar isVisible={isSidebarVisible} />
		{/if}

		<!-- Editor area -->
		<main class="flex-1 overflow-hidden bg-white dark:bg-gray-900">
			{#if documentStore.activeDocument}
				<Editor
					bind:this={editorComponent}
					content={documentStore.activeDocument.content}
					placeholder="Start writing your story..."
					onUpdate={handleEditorUpdate}
				/>
			{:else}
				<!-- Empty state -->
				<div class="flex h-full items-center justify-center">
					<div class="text-center">
						<div
							class="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-gray-200 dark:bg-gray-800"
						>
							<svg
								class="h-8 w-8 text-gray-400"
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
						<h3 class="mb-2 text-lg font-medium text-gray-900 dark:text-gray-100">
							No document selected
						</h3>
						<p class="mb-4 text-gray-500 dark:text-gray-400">
							Create a new document to start writing
						</p>
						<button
							onclick={() => {
								documentStore.createDocument();
								setTimeout(() => editorComponent?.focus(), 100);
							}}
							class="rounded-lg bg-blue-600 px-4 py-2 text-white transition-colors duration-200 hover:bg-blue-700"
						>
							Create Document
						</button>
					</div>
				</div>
			{/if}
		</main>
	</div>

	<!-- Focus mode overlay -->
	{#if documentStore.isDistractionFree}
		<div class="fixed top-4 right-4 z-50">
			<button
				onclick={() => documentStore.setDistractionFree(false)}
				class="bg-opacity-20 hover:bg-opacity-30 rounded-full bg-black p-3 text-white backdrop-blur-sm transition-colors duration-200"
				title="Exit focus mode (ESC)"
				aria-label="Exit focus mode"
			>
				<svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
					<path
						stroke-linecap="round"
						stroke-linejoin="round"
						stroke-width="2"
						d="M6 18L18 6M6 6l12 12"
					/>
				</svg>
			</button>
		</div>

		<!-- Focus mode stats -->
		<div class="fixed bottom-4 left-1/2 z-50 -translate-x-1/2 transform">
			<div
				class="bg-opacity-20 rounded-full bg-black px-4 py-2 text-sm text-white backdrop-blur-sm"
			>
				{editorStats.words}
				{editorStats.words === 1 ? 'word' : 'words'} • {editorStats.characters} characters
			</div>
		</div>
	{/if}
</div>
