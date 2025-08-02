<script lang="ts">
	import { documentStore } from '$lib/stores/documents.svelte.js';

	interface Props {
		onToggleSidebar?: () => void;
		isSidebarVisible?: boolean;
		editorStats?: { words: number; characters: number };
	}

	let {
		onToggleSidebar,
		isSidebarVisible = true,
		editorStats = { words: 0, characters: 0 }
	}: Props = $props();

	function formatWordCount(count: number): string {
		if (count === 0) return '0 words';
		if (count === 1) return '1 word';
		if (count < 1000) return `${count} words`;
		return `${(count / 1000).toFixed(1)}k words`;
	}

	function formatCharacterCount(count: number): string {
		if (count < 1000) return `${count} chars`;
		return `${(count / 1000).toFixed(1)}k chars`;
	}

	function updateDocumentTitle(event: Event) {
		const target = event.target as HTMLInputElement;
		const activeDoc = documentStore.activeDocument;
		if (activeDoc && target.value.trim()) {
			documentStore.updateDocument(activeDoc.id, { title: target.value.trim() });
		}
	}

	function handleTitleKeydown(event: KeyboardEvent) {
		if (event.key === 'Enter') {
			(event.target as HTMLInputElement).blur();
		}
	}
</script>

<header
	class="header flex min-h-[60px] items-center justify-between border-b border-gray-200 bg-white px-4 py-3 dark:border-gray-700 dark:bg-gray-800"
>
	<!-- Left section -->
	<div class="flex items-center gap-3">
		<!-- Sidebar toggle -->
		<button
			onclick={onToggleSidebar}
			class="rounded-lg p-2 transition-colors duration-200 hover:bg-gray-100 dark:hover:bg-gray-700"
			title={isSidebarVisible ? 'Hide sidebar' : 'Show sidebar'}
		>
			<svg
				class="h-5 w-5 text-gray-600 dark:text-gray-400"
				fill="none"
				stroke="currentColor"
				viewBox="0 0 24 24"
			>
				{#if isSidebarVisible}
					<path
						stroke-linecap="round"
						stroke-linejoin="round"
						stroke-width="2"
						d="M11 19l-7-7 7-7m8 14l-7-7 7-7"
					/>
				{:else}
					<path
						stroke-linecap="round"
						stroke-linejoin="round"
						stroke-width="2"
						d="M13 5l7 7-7 7M5 5l7 7-7 7"
					/>
				{/if}
			</svg>
		</button>

		<!-- Document title -->
		{#if documentStore.activeDocument}
			<input
				type="text"
				value={documentStore.activeDocument.title}
				oninput={updateDocumentTitle}
				onkeydown={handleTitleKeydown}
				class="max-w-xs min-w-0 rounded border-none bg-transparent px-2 py-1 text-lg font-semibold text-gray-900 focus:ring-2 focus:ring-blue-500 focus:outline-none dark:text-gray-100 dark:focus:ring-blue-400"
				placeholder="Document title..."
			/>
		{:else}
			<div class="text-lg font-semibold text-gray-500 dark:text-gray-400">No document selected</div>
		{/if}
	</div>

	<!-- Center section - Statistics -->
	<div class="hidden items-center gap-6 text-sm text-gray-500 md:flex dark:text-gray-400">
		{#if documentStore.activeDocument}
			<div class="flex items-center gap-1">
				<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
					<path
						stroke-linecap="round"
						stroke-linejoin="round"
						stroke-width="2"
						d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
					/>
				</svg>
				<span>{formatWordCount(editorStats.words)}</span>
			</div>

			<div class="flex items-center gap-1">
				<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
					<path
						stroke-linecap="round"
						stroke-linejoin="round"
						stroke-width="2"
						d="M7 20l4-16m2 16l4-16M6 9h14M4 15h14"
					/>
				</svg>
				<span>{formatCharacterCount(editorStats.characters)}</span>
			</div>

			<div class="text-xs text-gray-400 dark:text-gray-500">
				Last edited {new Intl.DateTimeFormat('en-US', {
					month: 'short',
					day: 'numeric',
					hour: '2-digit',
					minute: '2-digit'
				}).format(documentStore.activeDocument.updatedAt)}
			</div>
		{/if}
	</div>

	<!-- Right section -->
	<div class="flex items-center gap-2">
		<!-- Focus mode toggle -->
		<button
			onclick={() => documentStore.toggleDistractionFree()}
			class="rounded-lg p-2 transition-colors duration-200 hover:bg-gray-100 dark:hover:bg-gray-700"
			class:bg-blue-100={documentStore.isDistractionFree}
			class:dark:bg-blue-950={documentStore.isDistractionFree}
			class:text-blue-600={documentStore.isDistractionFree}
			class:dark:text-blue-300={documentStore.isDistractionFree}
			title="Toggle focus mode"
			aria-label="Toggle focus mode"
		>
			<svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
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
		</button>

		<!-- Theme toggle -->
		<button
			onclick={() => {
				const html = document.documentElement;
				html.classList.toggle('dark');
				localStorage.setItem('theme', html.classList.contains('dark') ? 'dark' : 'light');
			}}
			class="rounded-lg p-2 transition-colors duration-200 hover:bg-gray-100 dark:hover:bg-gray-700"
			title="Toggle theme"
			aria-label="Toggle theme"
		>
			<svg
				class="hidden h-5 w-5 text-gray-600 dark:block dark:text-gray-400"
				fill="none"
				stroke="currentColor"
				viewBox="0 0 24 24"
			>
				<path
					stroke-linecap="round"
					stroke-linejoin="round"
					stroke-width="2"
					d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z"
				/>
			</svg>
			<svg
				class="block h-5 w-5 text-gray-600 dark:hidden dark:text-gray-400"
				fill="none"
				stroke="currentColor"
				viewBox="0 0 24 24"
			>
				<path
					stroke-linecap="round"
					stroke-linejoin="round"
					stroke-width="2"
					d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z"
				/>
			</svg>
		</button>

		<!-- Settings/Menu -->
		<button
			class="rounded-lg p-2 transition-colors duration-200 hover:bg-gray-100 dark:hover:bg-gray-700"
			title="Settings"
			aria-label="Settings"
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
					d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"
				/>
				<path
					stroke-linecap="round"
					stroke-linejoin="round"
					stroke-width="2"
					d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
				/>
			</svg>
		</button>
	</div>
</header>

<!-- Mobile stats bar -->
<div
	class="border-b border-gray-200 bg-gray-100 px-4 py-2 md:hidden dark:border-gray-700 dark:bg-gray-900"
>
	{#if documentStore.activeDocument}
		<div class="flex items-center justify-between text-sm text-gray-500 dark:text-gray-400">
			<div class="flex items-center gap-4">
				<span>{formatWordCount(editorStats.words)}</span>
				<span>{formatCharacterCount(editorStats.characters)}</span>
			</div>
			<div class="text-xs">
				{new Intl.DateTimeFormat('en-US', {
					month: 'short',
					day: 'numeric',
					hour: '2-digit',
					minute: '2-digit'
				}).format(documentStore.activeDocument.updatedAt)}
			</div>
		</div>
	{/if}
</div>
