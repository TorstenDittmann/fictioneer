<script lang="ts">
	import { Dialog } from 'bits-ui';

	interface PromptTemplate {
		id: string;
		label: string;
		prompt: string;
	}

	interface Props {
		open: boolean;
		loading: boolean;
		generated_content: string;
		onClose: () => void;
		onGenerate: (prompt: string) => void;
		onCancel: () => void;
		onAccept: (content: string) => void;
		onReject: () => void;
	}

	let {
		open = $bindable(),
		loading,
		generated_content,
		onClose,
		onGenerate,
		onCancel,
		onAccept,
		onReject
	}: Props = $props();

	let custom_prompt = $state('');
	let selected_template = $state<string | null>(null);
	let content_container: HTMLDivElement | null = $state(null);

	const prompt_templates: PromptTemplate[] = [
		{
			id: 'continue',
			label: 'Continue Writing',
			prompt: 'Continue this story from where it left off, maintaining the same tone and style.'
		},
		{
			id: 'expand',
			label: 'Expand Scene',
			prompt:
				'Expand this scene with more vivid details, sensory descriptions, and emotional depth.'
		},
		{
			id: 'dialogue',
			label: 'Add Dialogue',
			prompt: 'Add natural dialogue to this scene that reveals character and advances the plot.'
		},
		{
			id: 'conflict',
			label: 'Add Conflict',
			prompt: 'Introduce compelling conflict or tension to this scene to increase engagement.'
		},
		{
			id: 'description',
			label: 'Enhance Description',
			prompt: 'Enhance the descriptive language to make this scene more immersive and atmospheric.'
		},
		{
			id: 'character',
			label: 'Develop Character',
			prompt:
				'Deepen character development in this scene through actions, thoughts, and interactions.'
		}
	];

	// Auto-scroll to bottom when content updates during streaming
	$effect(() => {
		if (generated_content && content_container && loading) {
			content_container.scrollTop = content_container.scrollHeight;
		}
	});

	function handle_template_select(template: PromptTemplate) {
		selected_template = template.id;
		custom_prompt = template.prompt;
	}

	function handle_generate() {
		if (custom_prompt.trim()) {
			onGenerate(custom_prompt.trim());
		}
	}

	function handle_cancel() {
		onCancel();
	}

	function handle_accept() {
		onAccept(generated_content);
		onClose();
		reset_modal();
	}

	function handle_reject() {
		onReject();
		reset_modal();
	}

	function handle_regenerate() {
		if (custom_prompt.trim()) {
			onGenerate(custom_prompt.trim());
		}
	}

	function handle_close() {
		if (loading) {
			onCancel();
		}
		onClose();
		reset_modal();
	}

	function reset_modal() {
		custom_prompt = '';
		selected_template = null;
	}

	function handle_keydown(e: KeyboardEvent) {
		if (e.key === 'Escape') {
			if (loading) {
				handle_cancel();
			} else {
				handle_close();
			}
		}
		// Submit with Cmd/Ctrl + Enter
		if ((e.metaKey || e.ctrlKey) && e.key === 'Enter' && custom_prompt.trim() && !loading) {
			e.preventDefault();
			handle_generate();
		}
	}
</script>

<svelte:window onkeydown={handle_keydown} />

<Dialog.Root bind:open>
	<Dialog.Portal>
		<Dialog.Overlay class="fixed inset-0 z-50 bg-black/50 backdrop-blur-sm" />
		<div class="fixed inset-0 z-50 flex items-center justify-center p-4">
			<Dialog.Content
				class="flex max-h-[85vh] w-full max-w-2xl flex-col overflow-hidden rounded-2xl border border-border bg-background shadow-2xl"
			>
				<!-- Header -->
				<div class="flex shrink-0 items-center justify-between border-b border-border px-6 py-4">
					<div class="flex items-center gap-3">
						<div class="flex h-9 w-9 items-center justify-center rounded-lg bg-accent/10">
							<svg
								class="h-5 w-5 text-accent"
								fill="none"
								stroke="currentColor"
								viewBox="0 0 24 24"
							>
								<path
									stroke-linecap="round"
									stroke-linejoin="round"
									stroke-width="2"
									d="M9.813 15.904L9 18.75l-.813-2.846a4.5 4.5 0 00-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 003.09-3.09L9 5.25l.813 2.846a4.5 4.5 0 003.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 00-3.09 3.09zM18.259 8.715L18 9.75l-.259-1.035a3.375 3.375 0 00-2.455-2.456L14.25 6l1.036-.259a3.375 3.375 0 002.455-2.456L18 2.25l.259 1.035a3.375 3.375 0 002.456 2.456L21.75 6l-1.035.259a3.375 3.375 0 00-2.456 2.456z"
								/>
							</svg>
						</div>
						<Dialog.Title class="text-lg font-semibold text-text">AI Writing Assistant</Dialog.Title
						>
					</div>
					<Dialog.Close
						class="rounded-lg p-2 text-text-muted transition-colors hover:bg-background-tertiary hover:text-text focus:ring-2 focus:ring-accent focus:outline-none"
						onclick={handle_close}
					>
						<svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
							<path
								stroke-linecap="round"
								stroke-linejoin="round"
								stroke-width="2"
								d="M6 18L18 6M6 6l12 12"
							/>
						</svg>
					</Dialog.Close>
				</div>

				<!-- Content - Scrollable -->
				<div class="flex-1 overflow-y-auto p-6">
					<!-- Two-column layout when not loading and no content -->
					{#if !loading && !generated_content}
						<!-- Quick Prompt Templates -->
						<div class="mb-5">
							<h3 class="mb-3 text-sm font-medium text-text-secondary">Quick Prompts</h3>
							<div class="grid grid-cols-2 gap-2 sm:grid-cols-3">
								{#each prompt_templates as template (template.id)}
									<button
										class="group relative rounded-xl border border-border px-3 py-2.5 text-left text-sm font-medium text-text-secondary transition-all hover:border-accent/50 hover:bg-accent/5 hover:text-text focus:border-transparent focus:ring-2 focus:ring-accent focus:outline-none {selected_template ===
										template.id
											? 'border-accent bg-accent/10 text-accent'
											: ''}"
										onclick={() => handle_template_select(template)}
									>
										<span class="block truncate">{template.label}</span>
									</button>
								{/each}
							</div>
						</div>

						<!-- Custom Prompt Input -->
						<div class="mb-5">
							<label for="custom-prompt" class="mb-2 block text-sm font-medium text-text-secondary">
								Custom Prompt
							</label>
							<div class="relative">
								<textarea
									id="custom-prompt"
									bind:value={custom_prompt}
									placeholder="Describe what you want the AI to write..."
									class="w-full resize-none rounded-xl border border-border bg-background px-4 py-3 text-sm text-text placeholder-text-muted transition-colors focus:border-accent focus:ring-2 focus:ring-accent/20 focus:outline-none"
									rows="4"
								></textarea>
								<div class="absolute right-3 bottom-3 text-xs text-text-muted">
									<kbd class="rounded bg-background-tertiary px-1.5 py-0.5 font-mono text-xs"
										>Cmd</kbd
									>
									+
									<kbd class="rounded bg-background-tertiary px-1.5 py-0.5 font-mono text-xs"
										>Enter</kbd
									>
									to generate
								</div>
							</div>
						</div>

						<!-- Generate Button -->
						<button
							class="w-full rounded-xl bg-accent px-4 py-3 text-sm font-medium text-text-inverse transition-all hover:bg-accent-hover focus:ring-2 focus:ring-accent focus:ring-offset-2 focus:ring-offset-background focus:outline-none disabled:cursor-not-allowed disabled:opacity-50"
							onclick={handle_generate}
							disabled={!custom_prompt.trim()}
						>
							Generate Content
						</button>
					{:else}
						<!-- Streaming/Generated Content View -->
						<div class="space-y-4">
							<!-- Current Prompt Display -->
							<div class="rounded-xl bg-background-tertiary/50 p-4">
								<div class="mb-1 text-xs font-medium tracking-wide text-text-muted uppercase">
									Prompt
								</div>
								<p class="line-clamp-2 text-sm text-text-secondary">{custom_prompt}</p>
							</div>

							<!-- Generated Content -->
							<div>
								<div class="mb-2 flex items-center justify-between">
									<div class="flex items-center gap-2">
										{#if loading}
											<div class="flex items-center gap-2">
												<div
													class="h-2 w-2 animate-pulse rounded-full bg-accent"
													style="animation-delay: 0ms"
												></div>
												<div
													class="h-2 w-2 animate-pulse rounded-full bg-accent"
													style="animation-delay: 150ms"
												></div>
												<div
													class="h-2 w-2 animate-pulse rounded-full bg-accent"
													style="animation-delay: 300ms"
												></div>
											</div>
											<span class="text-sm font-medium text-accent">Writing...</span>
										{:else}
											<svg
												class="h-4 w-4 text-green-500"
												fill="none"
												stroke="currentColor"
												viewBox="0 0 24 24"
											>
												<path
													stroke-linecap="round"
													stroke-linejoin="round"
													stroke-width="2"
													d="M5 13l4 4L19 7"
												/>
											</svg>
											<span class="text-sm font-medium text-text-secondary">Complete</span>
										{/if}
									</div>
									{#if loading}
										<button
											class="flex items-center gap-1.5 rounded-lg px-3 py-1.5 text-xs font-medium text-text-secondary transition-colors hover:bg-background-tertiary hover:text-text"
											onclick={handle_cancel}
										>
											<svg
												class="h-3.5 w-3.5"
												fill="none"
												stroke="currentColor"
												viewBox="0 0 24 24"
											>
												<path
													stroke-linecap="round"
													stroke-linejoin="round"
													stroke-width="2"
													d="M6 18L18 6M6 6l12 12"
												/>
											</svg>
											Cancel
										</button>
									{/if}
								</div>
								<div
									bind:this={content_container}
									class="max-h-[300px] overflow-y-auto rounded-xl border border-border bg-background p-4 text-sm leading-relaxed text-text"
								>
									{#if generated_content}
										<div class="whitespace-pre-wrap">
											{generated_content}{#if loading}<span
													class="ml-0.5 inline-block h-4 w-0.5 animate-pulse bg-accent"
												></span>{/if}
										</div>
									{:else if loading}
										<div class="flex items-center gap-2 py-4 text-text-muted">
											<div
												class="h-4 w-4 animate-spin rounded-full border-2 border-accent border-t-transparent"
											></div>
											<span>Starting generation...</span>
										</div>
									{/if}
								</div>
							</div>
						</div>
					{/if}
				</div>

				<!-- Footer -->
				{#if generated_content && !loading}
					<div class="shrink-0 border-t border-border bg-background-secondary/30 px-6 py-4">
						<div class="flex items-center justify-between">
							<button
								class="flex items-center gap-2 rounded-lg px-4 py-2 text-sm font-medium text-text-secondary transition-colors hover:bg-background-tertiary hover:text-text focus:ring-2 focus:ring-accent focus:outline-none"
								onclick={handle_regenerate}
							>
								<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
									<path
										stroke-linecap="round"
										stroke-linejoin="round"
										stroke-width="2"
										d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
									/>
								</svg>
								Regenerate
							</button>
							<div class="flex gap-3">
								<button
									class="rounded-lg border border-border px-4 py-2 text-sm font-medium text-text-secondary transition-colors hover:bg-background-tertiary hover:text-text focus:ring-2 focus:ring-accent focus:outline-none"
									onclick={handle_reject}
								>
									Discard
								</button>
								<button
									class="rounded-lg bg-accent px-4 py-2 text-sm font-medium text-text-inverse transition-all hover:bg-accent-hover focus:ring-2 focus:ring-accent focus:ring-offset-2 focus:ring-offset-background focus:outline-none"
									onclick={handle_accept}
								>
									Insert
								</button>
							</div>
						</div>
					</div>
				{/if}
			</Dialog.Content>
		</div>
	</Dialog.Portal>
</Dialog.Root>
