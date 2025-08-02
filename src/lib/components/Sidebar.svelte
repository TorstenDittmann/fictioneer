<script lang="ts">
	import { documentStore } from '$lib/stores/documents.svelte.js';

	let { isVisible = true }: { isVisible?: boolean } = $props();

	// Computed stats
	const stats = $derived(documentStore.getTotalStats());

	let showCreateInput = $state(false);
	let newDocumentTitle = $state('');
	let createInputElement = $state<HTMLInputElement>();

	function createDocument() {
		showCreateInput = true;
		setTimeout(() => createInputElement?.focus(), 0);
	}

	function handleCreateSubmit() {
		const title = newDocumentTitle.trim() || 'Untitled Document';
		documentStore.createDocument(title);
		newDocumentTitle = '';
		showCreateInput = false;
	}

	function handleCreateCancel() {
		newDocumentTitle = '';
		showCreateInput = false;
	}

	function handleKeydown(event: KeyboardEvent) {
		if (event.key === 'Enter') {
			handleCreateSubmit();
		} else if (event.key === 'Escape') {
			handleCreateCancel();
		}
	}

	function selectDocument(id: string) {
		documentStore.setActiveDocument(id);
	}

	function deleteDocument(event: Event, id: string) {
		event.stopPropagation();
		if (documentStore.documents.length > 1) {
			documentStore.deleteDocument(id);
		}
	}

	function formatDate(date: Date): string {
		return new Intl.DateTimeFormat('en-US', {
			month: 'short',
			day: 'numeric',
			hour: '2-digit',
			minute: '2-digit'
		}).format(date);
	}

	function formatWordCount(count: number): string {
		if (count === 0) return '0 words';
		if (count === 1) return '1 word';
		if (count < 1000) return `${count} words`;
		return `${(count / 1000).toFixed(1)}k words`;
	}
</script>

<aside
	class="sidebar flex h-full flex-col border-r border-gray-200 bg-gray-100 transition-all duration-300 ease-in-out dark:border-gray-700 dark:bg-gray-900"
	class:hidden={!isVisible}
	class:w-80={isVisible}
	class:w-0={!isVisible}
>
	<!-- Header -->
	<div class="border-b border-gray-200 p-4 dark:border-gray-700">
		<div class="mb-4 flex items-center justify-between">
			<h2 class="text-lg font-semibold text-gray-900 dark:text-gray-100">Documents</h2>
			<button
				onclick={createDocument}
				class="rounded-lg p-2 transition-colors duration-200 hover:bg-gray-200 dark:hover:bg-gray-800"
				title="Create new document"
				aria-label="Create new document"
			>
				<svg
					class="h-5 w-5 text-gray-600 dark:text-gray-400"
					fill="none"
					stroke="currentColor"
					viewBox="0 0 24 24"
				>
					<path
						stroke-linecap="round"
						stroke-linejoin="round"
						stroke-width="2"
						d="M12 4v16m8-8H4"
					/>
				</svg>
			</button>
		</div>

		<!-- Stats -->
		<div class="text-sm text-gray-500 dark:text-gray-400">
			{stats.totalDocuments}
			{stats.totalDocuments === 1 ? 'document' : 'documents'} • {formatWordCount(stats.totalWords)}
		</div>
	</div>

	<!-- Create new document input -->
	{#if showCreateInput}
		<div class="border-b border-gray-200 bg-blue-100 p-4 dark:border-gray-700 dark:bg-blue-950">
			<input
				bind:this={createInputElement}
				bind:value={newDocumentTitle}
				onkeydown={handleKeydown}
				onblur={handleCreateCancel}
				placeholder="Document title..."
				class="w-full rounded-lg border border-blue-300 bg-white px-3 py-2 text-sm text-gray-900 placeholder-gray-500 focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-blue-600 dark:bg-gray-800 dark:text-gray-100 dark:placeholder-gray-400 dark:focus:ring-blue-400"
			/>
			<div class="mt-2 flex gap-2">
				<button
					onclick={handleCreateSubmit}
					class="rounded-md bg-blue-600 px-3 py-1 text-xs text-white transition-colors duration-200 hover:bg-blue-700"
				>
					Create
				</button>
				<button
					onclick={handleCreateCancel}
					class="rounded-md bg-gray-300 px-3 py-1 text-xs text-gray-700 transition-colors duration-200 hover:bg-gray-400 dark:bg-gray-600 dark:text-gray-300 dark:hover:bg-gray-700"
				>
					Cancel
				</button>
			</div>
		</div>
	{/if}

	<!-- Document list -->
	<div class="flex-1 overflow-y-auto">
		{#each documentStore.documents as document (document.id)}
			<div
				class="document-item group relative cursor-pointer border-b border-gray-100 p-4 transition-colors duration-200 hover:bg-gray-100 dark:border-gray-800 dark:hover:bg-gray-800"
				class:bg-blue-100={documentStore.activeDocumentId === document.id}
				class:dark:bg-blue-950={documentStore.activeDocumentId === document.id}
				class:border-l-4={documentStore.activeDocumentId === document.id}
				class:border-l-blue-500={documentStore.activeDocumentId === document.id}
				onclick={() => selectDocument(document.id)}
				role="button"
				tabindex="0"
				onkeydown={(e) => e.key === 'Enter' && selectDocument(document.id)}
				aria-label="Select document {document.title}"
			>
				<div class="flex items-start justify-between">
					<div class="min-w-0 flex-1">
						<h3 class="truncate text-sm font-medium text-gray-900 dark:text-gray-100">
							{document.title}
						</h3>
						<div class="mt-1 space-y-1 text-xs text-gray-500 dark:text-gray-400">
							<div>{formatWordCount(document.wordCount)}</div>
							<div>{formatDate(document.updatedAt)}</div>
						</div>
					</div>

					{#if documentStore.documents.length > 1}
						<button
							onclick={(e) => deleteDocument(e, document.id)}
							class="rounded p-1 text-gray-400 opacity-0 transition-colors duration-200 group-hover:opacity-100 hover:bg-red-100 hover:text-red-600 dark:hover:bg-red-950 dark:hover:text-red-400"
							title="Delete document"
							aria-label="Delete document {document.title}"
						>
							<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
								<path
									stroke-linecap="round"
									stroke-linejoin="round"
									stroke-width="2"
									d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
								/>
							</svg>
						</button>
					{/if}
				</div>

				<!-- Content preview -->
				{#if document.content}
					<div class="mt-2 line-clamp-2 text-xs text-gray-400 dark:text-gray-500">
						{document.content.replace(/<[^>]*>/g, '').slice(0, 100)}...
					</div>
				{/if}
			</div>
		{/each}
	</div>

	<!-- Footer -->
	<div class="border-t border-gray-200 p-4 dark:border-gray-700">
		<button
			onclick={() => documentStore.toggleDistractionFree()}
			class="flex w-full items-center justify-center gap-2 rounded-lg bg-gray-200 px-3 py-2 text-sm text-gray-700 transition-colors duration-200 hover:bg-gray-300 dark:bg-gray-700 dark:text-gray-300 dark:hover:bg-gray-600"
		>
			<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
				<path
					stroke-linecap="round"
					stroke-linejoin="round"
					stroke-width="2"
					d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
				/>
				<path
					stroke-linecap="round"
					stroke-linejoin="round"
					stroke-width="2"
					d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"
				/>
			</svg>
			Focus Mode
		</button>
	</div>
</aside>

<style>
	.document-item:hover .group-hover\:opacity-100 {
		opacity: 1;
	}

	.line-clamp-2 {
		display: -webkit-box;
		-webkit-line-clamp: 2;
		line-clamp: 2;
		-webkit-box-orient: vertical;
		overflow: hidden;
	}
</style>
