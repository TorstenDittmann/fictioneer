<script lang="ts">
	import type { ProgressStats, ProgressGoals } from '../types/progress.js';

	interface Props {
		stats: ProgressStats | null;
		goals: ProgressGoals | null;
		totalProjectWords: number;
		class?: string;
	}

	let { stats, goals, totalProjectWords = 0, class: additional_class = '' }: Props = $props();

	// Format numbers with commas
	function formatNumber(num: number): string {
		return num.toLocaleString();
	}

	// Format date for display
	function formatDate(date: Date): string {
		return date.toLocaleDateString('en-US', {
			month: 'short',
			day: 'numeric',
			year: 'numeric'
		});
	}

	// Calculate project completion percentage
	const projectCompletionPercentage = $derived(() => {
		if (!goals?.projectWordTarget || goals.projectWordTarget === 0) {
			return null;
		}
		return Math.min(Math.round((totalProjectWords / goals.projectWordTarget) * 100), 100);
	});

	// Calculate words remaining for project
	const wordsRemainingForProject = $derived(() => {
		if (!goals?.projectWordTarget) {
			return null;
		}
		return Math.max(goals.projectWordTarget - totalProjectWords, 0);
	});

	// Get streak status message
	function getStreakMessage(streak: number): string {
		if (streak === 0) {
			return 'Start your streak today!';
		} else if (streak === 1) {
			return 'Great start! Keep it going!';
		} else if (streak < 7) {
			return `${streak} days strong!`;
		} else if (streak < 30) {
			return `Amazing ${streak}-day streak!`;
		} else {
			return `Incredible ${streak}-day streak!`;
		}
	}

	// Get completion status message
	function getCompletionMessage(): string {
		if (!goals?.projectWordTarget) {
			return 'Set a project goal to track completion';
		}

		const percentage = projectCompletionPercentage();
		if (percentage === null) return '';

		if (percentage >= 100) {
			return 'Project complete! Congratulations!';
		} else if (percentage >= 90) {
			return "Almost finished! You're in the final stretch!";
		} else if (percentage >= 75) {
			return 'Three-quarters done! Excellent progress!';
		} else if (percentage >= 50) {
			return 'Halfway there! Keep up the momentum!';
		} else if (percentage >= 25) {
			return "Quarter complete! You're making great progress!";
		} else if (percentage > 0) {
			return 'Good start! Every word brings you closer!';
		} else {
			return 'Ready to begin your writing journey!';
		}
	}

	// Get estimated completion message
	function getEstimatedCompletionMessage(): string {
		if (!stats?.estimatedCompletionDate) {
			return 'Keep writing to get completion estimate';
		}

		const today = new Date();
		const completionDate = stats.estimatedCompletionDate;
		const daysUntilCompletion = Math.ceil(
			(completionDate.getTime() - today.getTime()) / (1000 * 60 * 60 * 24)
		);

		if (daysUntilCompletion <= 0) {
			return 'You should be done by now!';
		} else if (daysUntilCompletion === 1) {
			return 'Estimated completion: Tomorrow!';
		} else if (daysUntilCompletion <= 7) {
			return `Estimated completion: ${daysUntilCompletion} days`;
		} else if (daysUntilCompletion <= 30) {
			const weeks = Math.ceil(daysUntilCompletion / 7);
			return `Estimated completion: ${weeks} week${weeks !== 1 ? 's' : ''}`;
		} else {
			const months = Math.ceil(daysUntilCompletion / 30);
			return `Estimated completion: ${months} month${months !== 1 ? 's' : ''}`;
		}
	}

	// Get velocity indicator
	function getVelocityIndicator(): { icon: string; message: string; color: string } {
		const avgWords = stats?.averageDailyWords || 0;
		const dailyGoal = goals?.dailyWordTarget || 500;

		if (avgWords >= dailyGoal * 1.5) {
			return { icon: '↗', message: 'Excellent velocity!', color: 'text-accent' };
		} else if (avgWords >= dailyGoal) {
			return { icon: '↗', message: 'Great velocity!', color: 'text-accent' };
		} else if (avgWords >= dailyGoal * 0.7) {
			return { icon: '→', message: 'Good velocity', color: 'text-accent-muted' };
		} else if (avgWords > 0) {
			return { icon: '↘', message: 'Building momentum', color: 'text-text-secondary' };
		} else {
			return { icon: '—', message: 'Start writing to track velocity', color: 'text-text-muted' };
		}
	}

	const velocityInfo = $derived(getVelocityIndicator());
</script>

<div class="progress-stats {additional_class}">
	<!-- Header -->
	<div class="mb-6 flex items-center justify-between">
		<h3 class="text-lg font-medium text-text">Writing Statistics</h3>
		<div class="text-xl">{velocityInfo.icon}</div>
	</div>

	<!-- Main Stats Grid -->
	<div class="mb-6 grid grid-cols-1 gap-4 sm:grid-cols-2">
		<!-- Current Streak -->
		<div class="rounded-lg bg-background-tertiary p-4">
			<div class="text-center">
				<div class="mb-1 text-2xl font-bold text-accent">
					{stats?.currentStreak || 0}
				</div>
				<div class="mb-2 text-xs text-text-secondary">Current Streak</div>
				<div class="text-xs text-text-muted">
					{getStreakMessage(stats?.currentStreak || 0)}
				</div>
			</div>
		</div>

		<!-- Longest Streak -->
		<div class="rounded-lg bg-background-tertiary p-4">
			<div class="text-center">
				<div class="mb-1 text-2xl font-bold text-accent-muted">
					{stats?.longestStreak || 0}
				</div>
				<div class="mb-2 text-xs text-text-secondary">Best Streak</div>
				<div class="text-xs text-text-muted">
					{stats?.longestStreak ? 'Personal record!' : 'No streak yet'}
				</div>
			</div>
		</div>

		<!-- Average Daily Words -->
		<div class="rounded-lg bg-background-tertiary p-4">
			<div class="text-center">
				<div class="mb-1 text-2xl font-bold text-text">
					{formatNumber(stats?.averageDailyWords || 0)}
				</div>
				<div class="mb-2 text-xs text-text-secondary">Avg Daily Words</div>
				<div class="text-xs {velocityInfo.color}">
					{velocityInfo.message}
				</div>
			</div>
		</div>

		<!-- Active Days -->
		<div class="rounded-lg bg-background-tertiary p-4">
			<div class="text-center">
				<div class="mb-1 text-2xl font-bold text-text">
					{stats?.totalDaysActive || 0}
				</div>
				<div class="mb-2 text-xs text-text-secondary">Active Days</div>
				<div class="text-xs text-text-muted">
					{stats?.totalDaysActive ? 'Keep it up!' : 'Start today!'}
				</div>
			</div>
		</div>
	</div>

	<!-- Project Progress Section -->
	{#if goals?.projectWordTarget}
		<div class="mb-4 rounded-lg bg-surface p-4">
			<div class="mb-3 flex items-center justify-between">
				<h4 class="text-sm font-medium text-text">Project Progress</h4>
				<span class="text-xs text-text-secondary">
					{formatNumber(totalProjectWords)} / {formatNumber(goals.projectWordTarget)} words
				</span>
			</div>

			<!-- Project Progress Bar -->
			<div class="relative mb-3 h-2 w-full overflow-hidden rounded-full bg-background-tertiary">
				<div
					class="absolute top-0 left-0 h-full rounded-full bg-accent transition-all duration-500 ease-out"
					style="width: {projectCompletionPercentage || 0}%;"
				></div>
			</div>

			<div class="flex items-center justify-between text-xs">
				<span class="text-text-secondary">
					{projectCompletionPercentage() || 0}% complete
				</span>
				{#if wordsRemainingForProject() && wordsRemainingForProject()! > 0}
					<span class="text-text-muted">
						{formatNumber(wordsRemainingForProject()!)} words to go
					</span>
				{/if}
			</div>

			<div class="mt-2 text-center text-xs text-accent-muted">
				{getCompletionMessage()}
			</div>
		</div>
	{/if}

	<!-- Estimated Completion -->
	{#if stats?.estimatedCompletionDate && goals?.projectWordTarget}
		<div class="mb-4 rounded-lg bg-surface p-4">
			<div class="text-center">
				<div class="mb-1 text-sm font-medium text-text">Estimated Completion</div>
				<div class="mb-1 text-lg font-bold text-accent">
					{formatDate(stats.estimatedCompletionDate)}
				</div>
				<div class="text-xs text-text-secondary">
					{getEstimatedCompletionMessage()}
				</div>
			</div>
		</div>
	{/if}

	<!-- Writing Insights -->
	{#if stats && stats.totalDaysActive > 0}
		<div class="rounded-lg bg-background-tertiary p-4">
			<h4 class="mb-3 text-sm font-medium text-text">Writing Insights</h4>

			<div class="space-y-2 text-xs">
				{#if stats.averageDailyWords > 0}
					<div class="flex items-center justify-between">
						<span class="text-text-secondary">Writing consistency:</span>
						<span class="text-text">
							{Math.round((stats.currentStreak / Math.max(stats.totalDaysActive, 1)) * 100)}%
						</span>
					</div>
				{/if}

				{#if goals?.dailyWordTarget}
					<div class="flex items-center justify-between">
						<span class="text-text-secondary">Goal achievement rate:</span>
						<span class="text-text">
							{Math.round((stats.averageDailyWords / goals.dailyWordTarget) * 100)}%
						</span>
					</div>
				{/if}

				{#if stats.totalDaysActive > 7}
					<div class="flex items-center justify-between">
						<span class="text-text-secondary">Weekly average:</span>
						<span class="text-text">
							{formatNumber(Math.round(stats.averageDailyWords * 7))} words
						</span>
					</div>
				{/if}

				{#if goals?.projectWordTarget && stats.averageDailyWords > 0}
					<div class="flex items-center justify-between">
						<span class="text-text-secondary">Days to completion:</span>
						<span class="text-text">
							{Math.ceil((goals.projectWordTarget - totalProjectWords) / stats.averageDailyWords)} days
						</span>
					</div>
				{/if}
			</div>
		</div>
	{:else}
		<div class="rounded-lg bg-background-tertiary p-4 text-center">
			<div class="text-sm text-text-secondary">
				Start writing to see detailed insights about your progress!
			</div>
		</div>
	{/if}
</div>

<style>
	.progress-stats {
		width: 100%;
	}

	/* Smooth animations for progress bars */
	.progress-stats [style*='width'] {
		transition: width 0.5s ease-out;
	}

	/* Responsive adjustments */
	@media (max-width: 640px) {
		.progress-stats {
			font-size: 0.875rem;
		}
	}
</style>
