<script lang="ts">
	import type { ChartDataPoint } from '../types/progress.js';

	interface Props {
		data: ChartDataPoint[];
		width?: number;
		height?: number;
		class?: string;
	}

	let { data = [], width = 800, height = 200, class: additional_class = '' }: Props = $props();

	// Container element for responsive sizing
	let containerElement: HTMLDivElement;
	let actualWidth = $state(width);

	// Update width based on container size
	$effect(() => {
		if (containerElement) {
			const updateWidth = () => {
				actualWidth = containerElement.clientWidth || width;
			};

			updateWidth();
			window.addEventListener('resize', updateWidth);

			return () => {
				window.removeEventListener('resize', updateWidth);
			};
		}
	});

	// Chart dimensions and padding
	const padding = { top: 20, right: 20, bottom: 40, left: 40 };
	const chartWidth = $derived(actualWidth - padding.left - padding.right);
	const chartHeight = $derived(height - padding.top - padding.bottom);

	// Calculate scales
	const maxWords = $derived(
		Math.max(...data.map((d) => Math.max(d.wordsWritten, d.goalTarget)), 0)
	);
	const yScale = $derived((value: number) => chartHeight - (value / maxWords) * chartHeight);
	const xScale = $derived((index: number) => (index / Math.max(data.length - 1, 1)) * chartWidth);

	// Tooltip state
	let hoveredPoint: ChartDataPoint | null = $state(null);
	let tooltipX = $state(0);
	let tooltipY = $state(0);
	let showTooltip = $state(false);

	// Format date for display
	function formatDate(dateStr: string): string {
		const date = new Date(dateStr);
		return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
	}

	// Format number with commas
	function formatNumber(num: number): string {
		return num.toLocaleString();
	}

	// Handle mouse events for tooltip
	function handleMouseEnter(point: ChartDataPoint, event: MouseEvent) {
		hoveredPoint = point;
		showTooltip = true;

		const rect = (event.currentTarget as SVGElement).getBoundingClientRect();
		const svgRect = (event.currentTarget as SVGElement).closest('svg')?.getBoundingClientRect();

		if (svgRect) {
			tooltipX = rect.left - svgRect.left + rect.width / 2;
			tooltipY = rect.top - svgRect.top - 10;
		}
	}

	function handleMouseLeave() {
		showTooltip = false;
		hoveredPoint = null;
	}

	// Generate goal line path
	const goalLinePath = $derived(() => {
		if (data.length === 0) return '';

		const goalY = yScale(data[0]?.goalTarget || 0);
		return `M 0 ${goalY} L ${chartWidth} ${goalY}`;
	});

	// Generate trend line (simple linear regression)
	const trendLinePath = $derived(() => {
		if (data.length < 2) return '';

		const validPoints = data.filter((d) => d.wordsWritten > 0);
		if (validPoints.length < 2) return '';

		// Calculate linear regression
		const n = validPoints.length;
		const sumX = validPoints.reduce((sum, _, i) => sum + i, 0);
		const sumY = validPoints.reduce((sum, d) => sum + d.wordsWritten, 0);
		const sumXY = validPoints.reduce((sum, d, i) => sum + i * d.wordsWritten, 0);
		const sumXX = validPoints.reduce((sum, _, i) => sum + i * i, 0);

		const slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
		const intercept = (sumY - slope * sumX) / n;

		const startY = yScale(Math.max(0, intercept));
		const endY = yScale(Math.max(0, slope * (data.length - 1) + intercept));

		return `M 0 ${startY} L ${chartWidth} ${endY}`;
	});
</script>

<div class="progress-chart {additional_class}" bind:this={containerElement}>
	<div class="relative w-full">
		<svg width={actualWidth} {height} class="w-full overflow-visible">
			<!-- Chart background -->
			<rect
				x={padding.left}
				y={padding.top}
				width={chartWidth}
				height={chartHeight}
				fill="transparent"
				stroke="var(--color-border)"
				stroke-width="1"
			/>

			<!-- Grid lines -->
			<!-- eslint-disable-next-line @typescript-eslint/no-unused-vars -->
			{#each Array(5) as _, i (i)}
				{@const y = padding.top + (i / 4) * chartHeight}
				{@const value = Math.round(maxWords * (1 - i / 4))}

				<!-- Horizontal grid line -->
				<line
					x1={padding.left}
					y1={y}
					x2={padding.left + chartWidth}
					y2={y}
					stroke="var(--color-border)"
					stroke-width="0.5"
					opacity="0.3"
				/>

				<!-- Y-axis label -->
				<text x={padding.left - 10} y={y + 4} text-anchor="end" class="fill-text-muted text-xs">
					{formatNumber(value)}
				</text>
			{/each}

			<!-- Goal line -->
			{#if data.length > 0}
				<path
					d={goalLinePath()}
					stroke="var(--color-accent-muted)"
					stroke-width="2"
					stroke-dasharray="5,5"
					opacity="0.7"
					transform="translate({padding.left}, {padding.top})"
				/>
			{/if}

			<!-- Trend line -->
			{#if trendLinePath()}
				<path
					d={trendLinePath()}
					stroke="var(--color-accent)"
					stroke-width="1"
					opacity="0.5"
					transform="translate({padding.left}, {padding.top})"
				/>
			{/if}

			<!-- Data bars -->
			{#each data as point, i (point.date)}
				{@const barWidth = Math.max(chartWidth / data.length - 2, 8)}
				{@const barHeight = (point.wordsWritten / maxWords) * chartHeight}
				{@const x = xScale(i) - barWidth / 2}
				{@const y = chartHeight - barHeight}

				<rect
					x={padding.left + x}
					y={padding.top + y}
					width={barWidth}
					height={barHeight}
					fill={point.goalMet
						? 'var(--color-accent)'
						: point.wordsWritten > 0
							? 'var(--color-accent-muted)'
							: 'var(--color-border)'}
					stroke={point.isToday ? 'var(--color-text)' : 'transparent'}
					stroke-width={point.isToday ? 2 : 0}
					class="cursor-pointer transition-all duration-200 hover:opacity-80"
					role="button"
					tabindex="0"
					onmouseenter={(e) => handleMouseEnter(point, e)}
					onmouseleave={handleMouseLeave}
					onkeydown={(e) => {
						if (e.key === 'Enter' || e.key === ' ') {
							// Create a synthetic mouse event for keyboard interaction
							const syntheticEvent = new MouseEvent('mouseenter', {
								clientX: 0,
								clientY: 0,
								bubbles: true
							});
							handleMouseEnter(point, syntheticEvent);
						}
					}}
				/>
			{/each}

			<!-- X-axis labels (show every 5th day) -->
			{#each data as point, i (point.date + '-label')}
				{#if i % 5 === 0 || i === data.length - 1}
					{@const x = xScale(i)}
					<text
						x={padding.left + x}
						y={height - 10}
						text-anchor="middle"
						class="fill-text-muted text-xs"
					>
						{formatDate(point.date)}
					</text>
				{/if}
			{/each}
		</svg>

		<!-- Tooltip -->
		{#if showTooltip && hoveredPoint}
			<div
				class="pointer-events-none absolute z-10 rounded-lg border border-border bg-background-secondary p-3 whitespace-nowrap shadow-lg"
				style="left: {tooltipX}px; top: {tooltipY}px; transform: translateX(-50%) translateY(-100%);"
			>
				<div class="mb-1 text-sm font-medium text-text">
					{formatDate(hoveredPoint.date)}
				</div>
				<div class="text-xs text-text-secondary">
					Words: {formatNumber(hoveredPoint.wordsWritten)}
				</div>
				<div class="text-xs text-text-secondary">
					Goal: {formatNumber(hoveredPoint.goalTarget)}
				</div>
				{#if hoveredPoint.goalMet}
					<div class="mt-1 text-xs text-accent">✓ Goal achieved!</div>
				{:else if hoveredPoint.wordsWritten > 0}
					<div class="mt-1 text-xs text-accent-muted">
						{Math.round((hoveredPoint.wordsWritten / hoveredPoint.goalTarget) * 100)}% of goal
					</div>
				{:else}
					<div class="mt-1 text-xs text-text-muted">No writing</div>
				{/if}
				{#if hoveredPoint.isToday}
					<div class="mt-1 text-xs font-medium text-text">Today</div>
				{/if}
			</div>
		{/if}
	</div>

	<!-- Legend -->
	<div class="mt-4 flex items-center justify-center gap-6 text-xs text-text-secondary">
		<div class="flex items-center gap-2">
			<div class="h-3 w-3 rounded bg-accent"></div>
			<span>Goal achieved</span>
		</div>
		<div class="flex items-center gap-2">
			<div class="h-3 w-3 rounded bg-accent-muted"></div>
			<span>Progress made</span>
		</div>
		<div class="flex items-center gap-2">
			<div class="h-3 w-3 rounded bg-border"></div>
			<span>No writing</span>
		</div>
		<div class="flex items-center gap-2">
			<div
				class="h-1 w-3 bg-accent-muted opacity-70"
				style="border-top: 2px dashed var(--color-accent-muted);"
			></div>
			<span>Daily goal</span>
		</div>
	</div>
</div>

<style>
	.progress-chart {
		width: 100%;
	}

	/* Ensure proper text rendering in SVG */
	text {
		font-family: inherit;
		user-select: none;
	}

	/* Responsive adjustments */
	@media (max-width: 640px) {
		.progress-chart {
			font-size: 0.75rem;
		}
	}
</style>
