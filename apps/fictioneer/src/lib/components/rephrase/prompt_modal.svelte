<script lang="ts">
	import { Dialog } from 'bits-ui';

	interface Props {
		open: boolean;
		loading: boolean;
		generated_content: string;
		onClose: () => void;
		onGenerate: (prompt: string) => void;
		onInsert: (content: string) => void;
	}

	let {
		open = $bindable(),
		loading,
		generated_content,
		onClose,
		onGenerate,
		onInsert
	}: Props = $props();

	let prompt_input = $state('');

	function handle_generate() {
		if (prompt_input.trim()) {
			onGenerate(prompt_input.trim());
		}
	}

	function handle_insert() {
		onInsert(generated_content);
		onClose();
	}
</script>

<Dialog.Root bind:open>
	<Dialog.Portal>
		<Dialog.Overlay class="fixed inset-0 z-50 bg-black/50" />
		<Dialog.Content
			class="fixed top-[50%] left-[50%] z-50 w-full max-w-2xl translate-x-[-50%] translate-y-[-50%] rounded-lg border border-border bg-surface p-6 shadow-xl"
		>
			<div class="mb-4">
				<Dialog.Title class="text-lg font-semibold text-text">AI Writing Assistant</Dialog.Title>
				<Dialog.Description class="text-sm text-text-secondary">
					Describe what you'd like to generate
				</Dialog.Description>
			</div>

			<div class="mb-4">
				<textarea
					class="focus:border-primary w-full rounded-md border border-border bg-background px-3 py-2 text-sm text-text placeholder-text-secondary focus:outline-none"
					rows="4"
					placeholder="e.g., Write a dramatic scene where the protagonist discovers a hidden letter..."
					bind:value={prompt_input}
					disabled={loading}
				></textarea>
			</div>

			<div class="mb-4 flex justify-end gap-2">
				<button
					class="bg-primary text-primary-foreground hover:bg-primary/90 rounded-md px-4 py-2 text-sm font-medium transition-colors disabled:opacity-50"
					onclick={handle_generate}
					disabled={loading || !prompt_input.trim()}
				>
					{#if loading}
						Generating...
					{:else}
						Generate
					{/if}
				</button>
			</div>

			{#if generated_content}
				<div class="mb-4">
					<h3 class="mb-2 text-sm font-medium text-text">Generated Content:</h3>
					<div
						class="max-h-64 overflow-y-auto rounded-md border border-border bg-background p-3 text-sm text-text"
					>
						{generated_content}
					</div>
				</div>

				<div class="flex justify-end gap-2">
					<Dialog.Close
						class="rounded-md border border-border bg-background px-4 py-2 text-sm font-medium text-text transition-colors hover:bg-background-tertiary"
					>
						Cancel
					</Dialog.Close>
					<button
						class="bg-primary text-primary-foreground hover:bg-primary/90 rounded-md px-4 py-2 text-sm font-medium transition-colors"
						onclick={handle_insert}
					>
						Insert at Cursor
					</button>
				</div>
			{:else if loading}
				<div class="mb-4 flex items-center justify-center py-8">
					<div class="text-sm text-text-secondary">Generating content...</div>
				</div>
			{/if}
		</Dialog.Content>
	</Dialog.Portal>
</Dialog.Root>
