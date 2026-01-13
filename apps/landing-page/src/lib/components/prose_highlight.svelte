<script lang="ts">
	import { Tooltip } from 'bits-ui';

	type HighlightType = 'adverb' | 'filter' | 'vague' | 'telling';

	interface Props {
		type: HighlightType;
		word: string;
		message: string;
		suggestion: string;
	}

	let { type, word, message, suggestion }: Props = $props();

	const type_config: Record<
		HighlightType,
		{ label: string; border: string; bg: string; badge: string; text: string }
	> = {
		adverb: {
			label: 'Adverb',
			border: 'border-blue-500/50',
			bg: 'bg-blue-500/15',
			badge: 'bg-blue-500/20',
			text: 'text-blue-600'
		},
		filter: {
			label: 'Filter Word',
			border: 'border-purple-500/50',
			bg: 'bg-purple-500/15',
			badge: 'bg-purple-500/20',
			text: 'text-purple-600'
		},
		vague: {
			label: 'Vague Word',
			border: 'border-gray-500/50 border-dotted',
			bg: 'bg-gray-500/15',
			badge: 'bg-gray-500/20',
			text: 'text-gray-600'
		},
		telling: {
			label: 'Telling',
			border: 'border-amber-500/50',
			bg: 'bg-amber-500/15',
			badge: 'bg-amber-500/20',
			text: 'text-amber-600'
		}
	};

	const config = $derived(type_config[type]);
</script>

<Tooltip.Root delayDuration={100}>
	<Tooltip.Trigger
		class="prose-highlight-word relative inline-block cursor-help rounded-sm border-b-2 whitespace-nowrap {config.border} {config.bg} px-0.5"
	>
		{word}
	</Tooltip.Trigger>
	<Tooltip.Portal>
		<Tooltip.Content
			sideOffset={8}
			side="top"
			class="z-50 w-80 rounded-lg border border-paper-border bg-paper-cream p-4 shadow-lg"
		>
			<div class="mb-2">
				<span
					class="inline-block rounded px-2 py-1 text-xs font-semibold tracking-wide uppercase {config.badge} {config.text}"
				>
					{config.label}
				</span>
			</div>
			<p class="mb-1.5 text-sm font-medium text-paper-text">
				{message}
			</p>
			<p class="text-xs text-paper-text-muted">
				{suggestion}
			</p>
		</Tooltip.Content>
	</Tooltip.Portal>
</Tooltip.Root>
