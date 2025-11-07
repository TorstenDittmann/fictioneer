<script lang="ts">
	import { Dialog } from 'bits-ui';

	interface RephraseOption {
		type: string;
		alternative: string;
	}

	interface Props {
		open: boolean;
		original_text: string;
		rephrases: RephraseOption[];
		loading: boolean;
		onClose: () => void;
		onSelect: (rephrase: string) => void;
	}

	let {
		open = $bindable(),
		original_text,
		rephrases,
		loading,
		onClose,
		onSelect
	}: Props = $props();

	const type_labels = {
		vivid: 'More Vivid',
		tighter: 'Tighter',
		show_dont_tell: "Show Don't Tell",
		change_pov: 'Change POV',
		simplify: 'Simplify'
	};

	function get_type_label(type: string): string {
		return type_labels[type as keyof typeof type_labels] || type;
	}

	function handle_select(rephrase: string) {
		onSelect(rephrase);
		onClose();
	}
</script>

<Dialog.Root bind:open>
	<Dialog.Portal>
		<Dialog.Overlay class="fixed inset-0 z-50 bg-black/50" />
		<div class="fixed inset-0 z-50 flex items-center justify-center p-4">
			<Dialog.Content
				class="flex max-h-[80vh] w-full max-w-2xl flex-col overflow-hidden rounded-xl bg-background shadow-2xl"
			>
				<!-- Header -->
				<div class="flex shrink-0 items-center justify-between border-b border-border px-6 py-4">
					<Dialog.Title class="text-lg font-semibold text-text">Rephrase Suggestions</Dialog.Title>
					<Dialog.Close
						class="rounded-lg p-2 text-text-muted hover:bg-background-tertiary focus:ring-2 focus:ring-accent focus:outline-none"
						onclick={onClose}
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
					<!-- Original Text -->
					<div class="mb-6">
						<h3 class="mb-2 text-sm font-medium text-text-secondary">Original:</h3>
						<div
							class="rounded-lg border border-border bg-background-tertiary p-4 text-sm text-text"
						>
							{original_text}
						</div>
					</div>

					<!-- Loading State -->
					{#if loading}
						<div class="flex items-center justify-center py-8">
							<div class="flex items-center space-x-2">
								<div
									class="h-6 w-6 animate-spin rounded-full border-2 border-accent border-t-transparent"
								></div>
								<span class="text-text-secondary">Generating rephrases...</span>
							</div>
						</div>
					{:else if rephrases.length > 0}
						<!-- Rephrase Options -->
						<div class="space-y-4">
							{#each rephrases as rephrase (rephrase.type)}
								<div class="group">
									<div class="mb-2 flex items-center justify-between">
										<span class="text-xs font-medium tracking-wide text-accent uppercase">
											{get_type_label(rephrase.type)}
										</span>
									</div>
									<button
										class="w-full rounded-lg border border-border p-4 text-left text-sm text-text transition-all hover:bg-background-tertiary focus:border-transparent focus:ring-2 focus:ring-accent focus:outline-none"
										onclick={() => handle_select(rephrase.alternative)}
									>
										{rephrase.alternative}
									</button>
								</div>
							{/each}
						</div>
					{:else}
						<!-- Empty State -->
						<div class="flex flex-col items-center justify-center py-8 text-text-muted">
							<svg class="mb-3 h-12 w-12" fill="none" stroke="currentColor" viewBox="0 0 24 24">
								<path
									stroke-linecap="round"
									stroke-linejoin="round"
									stroke-width="1"
									d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z"
								/>
							</svg>
							<p>No rephrases available</p>
						</div>
					{/if}
				</div>

				<!-- Footer -->
				<div class="shrink-0 border-t border-border px-6 py-4">
					<div class="flex justify-end">
						<button
							class="rounded-lg border border-border px-4 py-2 text-sm font-medium text-text-secondary hover:bg-background-tertiary focus:ring-2 focus:ring-accent focus:outline-none"
							onclick={onClose}
						>
							Cancel
						</button>
					</div>
				</div>
			</Dialog.Content>
		</div>
	</Dialog.Portal>
</Dialog.Root>
