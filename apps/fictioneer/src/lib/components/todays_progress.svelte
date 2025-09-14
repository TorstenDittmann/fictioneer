<script lang="ts">
	import type { DailyProgress, ProgressGoals } from '../types/progress.js';

	interface Props {
		todaysProgress: DailyProgress | null;
		goals: ProgressGoals | null;
		class?: string;
	}

	let { todaysProgress, goals, class: additional_class = '' }: Props = $props();

	// Derived values for progress calculation
	const wordsWritten = $derived(todaysProgress?.wordsWritten || 0);
	const dailyGoal = $derived(goals?.dailyWordTarget || 500);
	const progressPercentage = $derived(Math.min(Math.round((wordsWritten / dailyGoal) * 100), 100));
	const goalMet = $derived(todaysProgress?.goalMet || false);
	const wordsRemaining = $derived(Math.max(dailyGoal - wordsWritten, 0));
	const wordsExceeded = $derived(Math.max(wordsWritten - dailyGoal, 0));

	// Format numbers with commas
	function formatNumber(num: number): string {
		return num.toLocaleString();
	}

	// Get motivational message based on progress
	function getMotivationalMessage(): string {
		if (goalMet) {
			if (wordsExceeded > dailyGoal * 0.5) {
				return "Outstanding! You're on fire today!";
			} else if (wordsExceeded > 0) {
				return "Excellent work! You've exceeded your goal!";
			} else {
				return "Perfect! You've hit your daily goal!";
			}
		} else if (progressPercentage >= 80) {
			return "Almost there! You're so close to your goal!";
		} else if (progressPercentage >= 50) {
			return "Great progress! You're halfway to your goal!";
		} else if (progressPercentage >= 25) {
			return 'Good start! Keep the momentum going!';
		} else if (wordsWritten > 0) {
			return "Every word counts! You've made a start!";
		} else {
			return 'Ready to begin? Your story is waiting!';
		}
	}

	// Get progress bar color based on status
	function getProgressBarColor(): string {
		if (goalMet) {
			return 'var(--color-accent)';
		} else if (progressPercentage >= 80) {
			return 'var(--color-accent)';
		} else if (progressPercentage >= 50) {
			return 'var(--color-accent-muted)';
		} else {
			return 'var(--color-accent-muted)';
		}
	}

	// Get status icon
	function getStatusIcon(): string {
		if (goalMet) {
			return '✓';
		} else if (progressPercentage >= 80) {
			return '◐';
		} else if (progressPercentage >= 50) {
			return '◑';
		} else if (wordsWritten > 0) {
			return '◒';
		} else {
			return '○';
		}
	}

	// Get time-based greeting
	function getTimeBasedGreeting(): string {
		const hour = new Date().getHours();
		if (hour < 12) {
			return 'Good morning';
		} else if (hour < 17) {
			return 'Good afternoon';
		} else {
			return 'Good evening';
		}
	}
</script>

<div class="todays-progress {additional_class}">
	<!-- Header -->
	<div class="mb-4 flex items-center justify-between">
		<h3 class="text-lg font-medium text-text">
			{getTimeBasedGreeting()}, Writer!
		</h3>
		<div class="text-2xl">
			{getStatusIcon()}
		</div>
	</div>

	<!-- Progress Overview -->
	<div class="mb-4 rounded-lg bg-background-tertiary p-4">
		<div class="mb-2 flex items-center justify-between">
			<span class="text-sm text-text-secondary">Today's Progress</span>
			<span class="text-sm font-medium text-text">
				{formatNumber(wordsWritten)} / {formatNumber(dailyGoal)} words
			</span>
		</div>

		<!-- Progress Bar -->
		<div class="relative mb-2 h-3 w-full overflow-hidden rounded-full bg-surface">
			<div
				class="absolute top-0 left-0 h-full rounded-full transition-all duration-500 ease-out"
				style="width: {progressPercentage}%; background-color: {getProgressBarColor()};"
			></div>

			<!-- Progress percentage overlay -->
			{#if progressPercentage > 15}
				<div class="absolute inset-0 flex items-center justify-center">
					<span class="text-xs font-medium text-text-inverse">
						{progressPercentage}%
					</span>
				</div>
			{/if}
		</div>

		<!-- Progress Details -->
		<div class="flex items-center justify-between text-xs text-text-secondary">
			<span>{progressPercentage}% complete</span>
			{#if goalMet && wordsExceeded > 0}
				<span class="text-accent">+{formatNumber(wordsExceeded)} extra words!</span>
			{:else if wordsRemaining > 0}
				<span>{formatNumber(wordsRemaining)} words to go</span>
			{/if}
		</div>
	</div>

	<!-- Motivational Message -->
	<div class="mb-4 rounded-lg bg-surface p-4">
		<div class="text-center">
			<p class="mb-2 text-sm text-text-secondary">
				{getMotivationalMessage()}
			</p>

			{#if goalMet}
				<div class="inline-flex items-center gap-2 rounded-full bg-accent/20 px-3 py-1">
					<span class="text-xs font-medium text-accent">Goal Achieved!</span>
				</div>
			{:else if progressPercentage >= 80}
				<div class="inline-flex items-center gap-2 rounded-full bg-accent-muted/20 px-3 py-1">
					<span class="text-xs font-medium text-accent-muted">Almost There!</span>
				</div>
			{:else if wordsWritten === 0}
				<div class="inline-flex items-center gap-2 rounded-full bg-surface-hover px-3 py-1">
					<span class="text-xs font-medium text-text-secondary">Ready to Start?</span>
				</div>
			{/if}
		</div>
	</div>

	<!-- Session Info -->
	{#if todaysProgress}
		<div class="flex items-center justify-between text-xs text-text-muted">
			<span>
				{todaysProgress.sessionsCount} writing session{todaysProgress.sessionsCount !== 1
					? 's'
					: ''} today
			</span>
			<span>
				Last updated: {new Date(todaysProgress.updatedAt).toLocaleTimeString('en-US', {
					hour: 'numeric',
					minute: '2-digit',
					hour12: true
				})}
			</span>
		</div>
	{:else}
		<div class="text-center text-xs text-text-muted">
			Start writing to begin tracking your progress
		</div>
	{/if}

	<!-- Quick Stats -->
	{#if wordsWritten > 0}
		<div class="mt-4 border-t border-border pt-4">
			<div class="grid grid-cols-2 gap-4 text-center">
				<div>
					<div class="text-lg font-medium text-text">
						{formatNumber(wordsWritten)}
					</div>
					<div class="text-xs text-text-secondary">Words Today</div>
				</div>
				<div>
					<div class="text-lg font-medium text-text">
						{progressPercentage}%
					</div>
					<div class="text-xs text-text-secondary">Goal Progress</div>
				</div>
			</div>
		</div>
	{/if}
</div>

<style>
	.todays-progress {
		width: 100%;
	}

	/* Smooth animations for progress updates */
	.todays-progress [style*='width'] {
		transition: width 0.5s ease-out;
	}

	/* Responsive adjustments */
	@media (max-width: 640px) {
		.todays-progress {
			font-size: 0.875rem;
		}

		.todays-progress .text-lg {
			font-size: 1rem;
		}

		.todays-progress .text-2xl {
			font-size: 1.5rem;
		}
	}
</style>
