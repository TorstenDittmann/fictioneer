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
		onAccept: (content: string) => void;
		onReject: () => void;
	}

	let {
		open = $bindable(),
		loading,
		generated_content,
		onClose,
		onGenerate,
		onAccept,
		onReject
	}: Props = $props();

	let custom_prompt = $state('');
	let selected_template = $state<string | null>(null);

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

	function handle_template_select(template: PromptTemplate) {
		selected_template = template.id;
		custom_prompt = template.prompt;
	}

	function handle_generate() {
		if (custom_prompt.trim()) {
			onGenerate(custom_prompt.trim());
		}
	}

	function handle_accept() {
		onAccept(generated_content);
		onClose();
		reset_modal();
	}

	function handle_reject() {
		onReject();
		onClose();
		reset_modal();
	}

	function handle_close() {
		onClose();
		reset_modal();
	}

	function reset_modal() {
		custom_prompt = '';
		selected_template = null;
	}

	function handle_keydown(e: KeyboardEvent) {
		if (e.key === 'Escape' && !loading) {
			handle_close();
		}
	}
</script>

<svelte:window onkeydown={handle_keydown} />

<Dialog.Root bind:open>
	<Dialog.Portal>
		<Dialog.Overlay class="fixed inset-0 z-50 bg-black/50" />
		<div class="fixed inset-0 z-50 flex items-center justify-center p-4">
			<Dialog.Content
				class="flex max-h-[90vh] w-full max-w-3xl flex-col overflow-hidden rounded-xl bg-background shadow-2xl"
			>
				<!-- Header -->
				<div class="flex shrink-0 items-center justify-between border-b border-border px-6 py-4">
					<Dialog.Title class="text-lg font-semibold text-text">AI Writing Assistant</Dialog.Title>
					<Dialog.Close
						class="rounded-lg p-2 text-text-muted hover:bg-background-tertiary focus:ring-2 focus:ring-accent focus:outline-none"
						onclick={handle_close}
						disabled={loading}
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
					<!-- Quick Prompt Templates -->
					<div class="mb-6">
						<h3 class="mb-3 text-sm font-medium text-text-secondary">Quick Prompts:</h3>
						<div class="grid grid-cols-2 gap-2 sm:grid-cols-3">
							{#each prompt_templates as template (template.id)}
								<button
									class="rounded-lg border border-border px-3 py-2 text-xs font-medium text-text-secondary transition-all hover:bg-background-tertiary hover:text-text focus:border-transparent focus:ring-2 focus:ring-accent focus:outline-none {selected_template ===
									template.id
										? 'border-accent bg-accent/20 text-accent'
										: ''}"
									onclick={() => handle_template_select(template)}
									disabled={loading}
								>
									{template.label}
								</button>
							{/each}
						</div>
					</div>

					<!-- Custom Prompt Input -->
					<div class="mb-6">
						<label for="custom-prompt" class="mb-2 block text-sm font-medium text-text-secondary">
							Custom Prompt:
						</label>
						<textarea
							id="custom-prompt"
							bind:value={custom_prompt}
							placeholder="Describe what you want the AI to write..."
							class="w-full resize-none rounded-lg border border-border bg-background-tertiary px-4 py-3 text-sm text-text placeholder-text-muted focus:border-transparent focus:ring-2 focus:ring-accent focus:outline-none"
							rows="3"
							disabled={loading}
						></textarea>
					</div>

					<!-- Generate Button -->
					<div class="mb-6 flex justify-end">
						<button
							class="rounded-lg bg-accent px-4 py-2 text-sm font-medium text-text-inverse transition-all hover:bg-accent-hover focus:ring-2 focus:ring-accent focus:outline-none disabled:cursor-not-allowed disabled:opacity-50"
							onclick={handle_generate}
							disabled={loading || !custom_prompt.trim()}
						>
							{#if loading}
								<div class="flex items-center space-x-2">
									<div
										class="h-4 w-4 animate-spin rounded-full border-2 border-text-inverse border-t-transparent"
									></div>
									<span>Generating...</span>
								</div>
							{:else}
								Generate Content
							{/if}
						</button>
					</div>

					<!-- Generated Content -->
					{#if generated_content || loading}
						<div>
							<h3 class="mb-2 text-sm font-medium text-text-secondary">
								{#if loading}
									Generating content...
								{:else}
									Generated Content:
								{/if}
							</h3>
							<div
								class="min-h-[200px] rounded-lg border border-border bg-background-tertiary p-4 text-sm text-text"
							>
								{#if loading}
									<div class="flex items-center justify-center py-8">
										<div class="flex items-center space-x-2">
											<div
												class="h-6 w-6 animate-spin rounded-full border-2 border-accent border-t-transparent"
											></div>
											<span class="text-text-secondary">AI is writing...</span>
										</div>
									</div>
								{:else if generated_content}
									<div class="whitespace-pre-wrap">{generated_content}</div>
								{:else}
									<div class="flex flex-col items-center justify-center py-8 text-text-muted">
										<svg
											class="mb-3 h-12 w-12"
											fill="none"
											stroke="currentColor"
											viewBox="0 0 24 24"
										>
											<path
												stroke-linecap="round"
												stroke-linejoin="round"
												stroke-width="1"
												d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"
											/>
										</svg>
										<p>Generated content will appear here</p>
									</div>
								{/if}
							</div>
						</div>
					{/if}
				</div>

				<!-- Footer -->
				{#if generated_content && !loading}
					<div class="shrink-0 border-t border-border px-6 py-4">
						<div class="flex justify-end space-x-3">
							<button
								class="rounded-lg border border-border px-4 py-2 text-sm font-medium text-text-secondary transition-all hover:bg-background-tertiary focus:ring-2 focus:ring-accent focus:outline-none"
								onclick={handle_reject}
							>
								Reject
							</button>
							<button
								class="rounded-lg bg-accent px-4 py-2 text-sm font-medium text-text-inverse transition-all hover:bg-accent-hover focus:ring-2 focus:ring-accent focus:outline-none"
								onclick={handle_accept}
							>
								Accept & Apply
							</button>
						</div>
					</div>
				{/if}
			</Dialog.Content>
		</div>
	</Dialog.Portal>
</Dialog.Root>
