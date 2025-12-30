<script lang="ts">
	import type { ChartDataPoint } from '../types/progress.js';

	interface Props {
		data: ChartDataPoint[];
		width?: number;
		height?: number;
		class?: string;
	}

	let { data = [], width = 800, height = 200, class: additional_class = '' }: Props = $props();

	// Responsive width using bind:clientWidth
	let containerWidth = $state(width);
	const actualWidth = $derived(containerWidth > 0 ? containerWidth : width);

	// Chart dimensions and padding
	const padding = { top: 20, right: 20, bottom: 40, left: 40 };
	const chartWidth = $derived(actualWidth - padding.left - padding.right);
	const chartHeight = $derived(height - padding.top - padding.bottom);

	// Calculate max value with safe fallback (include goal target for proper scaling)
	const maxWords = $derived.by(() => {
		if (data.length === 0) return 1;
		const max = Math.max(...data.map((d) => Math.max(d.wordsWritten, d.goalTarget)));
		return max > 0 ? max : 1;
	});

	// Generate goal line path
	const goalLinePath = $derived.by(() => {
		if (data.length === 0) return '';
		const goalTarget = data[0]?.goalTarget ?? 0;
		if (goalTarget <= 0) return '';
		const goalY = chartHeight - (goalTarget / maxWords) * chartHeight;
		return `M ${padding.left} ${padding.top + goalY} L ${padding.left + chartWidth} ${padding.top + goalY}`;
	});

	function xScale(index: number): number {
		const divisor = Math.max(data.length - 1, 1);
		return (index / divisor) * chartWidth;
	}

	// Tooltip state
	let hoveredPoint: ChartDataPoint | null = $state(null);
	let hoveredIndex = $state(-1);
	let showTooltip = $state(false);

	// Compute tooltip position based on hovered bar index
	const tooltipPosition = $derived.by(() => {
		if (hoveredIndex < 0 || !data[hoveredIndex]) {
			return { x: 0, y: 0 };
		}
		const barHeight = (data[hoveredIndex].wordsWritten / maxWords) * chartHeight;
		const x = padding.left + xScale(hoveredIndex);
		const y = padding.top + (chartHeight - barHeight) - 10;
		return { x, y };
	});

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
	function handleMouseEnter(point: ChartDataPoint, index: number) {
		hoveredPoint = point;
		hoveredIndex = index;
		showTooltip = true;
	}

	function handleMouseLeave() {
		showTooltip = false;
		hoveredPoint = null;
		hoveredIndex = -1;
	}

	// Calculate bar dimensions
	function getBarWidth(): number {
		return Math.max(chartWidth / Math.max(data.length, 1) - 2, 8);
	}

	function getBarHeight(wordsWritten: number): number {
		return (wordsWritten / maxWords) * chartHeight;
	}

	function getBarX(index: number): number {
		const barWidth = getBarWidth();
		return xScale(index) - barWidth / 2;
	}

	function getBarY(wordsWritten: number): number {
		return chartHeight - getBarHeight(wordsWritten);
	}
</script>

<div class="progress-chart {additional_class}" bind:clientWidth={containerWidth}>
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
			{#each Array(5).keys() as i (i)}
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
			{#if goalLinePath}
				<path
					d={goalLinePath}
					stroke="var(--color-accent-muted)"
					stroke-width="2"
					stroke-dasharray="5,5"
					opacity="0.7"
				/>
			{/if}

			<!-- Data bars -->
			{#each data as point, i (point.date)}
				{@const barWidth = getBarWidth()}
				{@const barHeight = getBarHeight(point.wordsWritten)}
				{@const x = getBarX(i)}
				{@const y = getBarY(point.wordsWritten)}

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
					onfocus={() => handleMouseEnter(point, i)}
					onblur={handleMouseLeave}
					onmouseenter={() => handleMouseEnter(point, i)}
					onmouseleave={handleMouseLeave}
					onkeydown={(e) => {
						if (e.key === 'Escape') {
							handleMouseLeave();
						}
					}}
				/>
			{/each}

			<!-- X-axis labels (show every 5th day) -->
			{#each data as point, i (point.date + '-label')}
				{#if i % 5 === 0 || i === data.length - 1}
					<text
						x={padding.left + xScale(i)}
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
				style="left: {tooltipPosition.x}px; top: {tooltipPosition.y}px; transform: translateX(-50%) translateY(-100%);"
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
					<div class="mt-1 text-xs text-accent">Goal achieved!</div>
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
			<div class="h-3 w-3 rounded bg-border"></div>
			<span>No writing</span>
		</div>
		<div class="flex items-center gap-2">
			<div class="h-0.5 w-4 border-t-2 border-dashed border-accent-muted opacity-70"></div>
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
