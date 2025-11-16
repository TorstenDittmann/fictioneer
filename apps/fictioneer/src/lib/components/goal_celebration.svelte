<script lang="ts">
	import { AlertDialog } from 'bits-ui';
	import { progress_tracker } from '$lib/state/progress.svelte';
	import { onMount } from 'svelte';

	interface CelebrationData {
		wordsWritten?: number;
		goal?: number;
		excess?: number;
		streak?: number;
		percentage?: number;
		suggestedGoal?: number;
		dailyTarget?: number;
		isPersonalBest?: boolean;
		currentWords?: number;
		targetWords?: number;
		remainingWords?: number;
		currentGoal?: number;
		averageWords?: number;
	}

	// Props for controlling the celebration display
	let {
		open = $bindable(false),
		onClose
	}: {
		open: boolean;
		onClose?: () => void;
	} = $props();

	// Celebration state
	let celebrationType = $state<'daily' | 'streak' | 'project' | 'suggestion'>('daily');
	let celebrationData = $state<CelebrationData>({});
	let showConfetti = $state(false);

	// Auto-check for celebrations when progress updates
	let lastCheckedDate = $state<string>('');
	let lastCheckedStreak = $state(0);
	let lastCheckedProjectProgress = $state(0);

	onMount(() => {
		checkForCelebrations();
	});

	// Watch for progress changes and check for new celebrations
	$effect(() => {
		// Trigger on any progress tracker changes
		void progress_tracker.todaysProgress;
		void progress_tracker.currentStreak;
		void progress_tracker.progressStats;

		checkForCelebrations();
	});

	function checkForCelebrations() {
		const today = new Date().toISOString().split('T')[0];
		const todaysProgress = progress_tracker.todaysProgress;
		const currentStreak = progress_tracker.currentStreak;
		const goals = progress_tracker.currentGoals;

		// Check for daily goal achievement (only once per day)
		if (todaysProgress && todaysProgress.goalMet && lastCheckedDate !== today) {
			lastCheckedDate = today;
			showDailyCelebration(todaysProgress.wordsWritten, goals?.dailyWordTarget || 500);
			return;
		}

		// Check for streak milestones (only when streak increases)
		if (currentStreak > lastCheckedStreak && isStreakMilestone(currentStreak)) {
			lastCheckedStreak = currentStreak;
			showStreakCelebration(currentStreak);
			return;
		}

		// Check for project milestones
		if (goals?.projectWordTarget) {
			const currentProjectWords = calculateProjectWords();
			const progressPercentage = (currentProjectWords / goals.projectWordTarget) * 100;

			if (
				isProjectMilestone(progressPercentage) &&
				progressPercentage > lastCheckedProjectProgress
			) {
				lastCheckedProjectProgress = progressPercentage;
				showProjectCelebration(progressPercentage, currentProjectWords, goals.projectWordTarget);
				return;
			}
		}

		// Check for goal increase suggestion (after consistent achievement)
		if (shouldSuggestGoalIncrease()) {
			showGoalSuggestion();
			return;
		}
	}

	function showDailyCelebration(wordsWritten: number, dailyTarget: number) {
		celebrationType = 'daily';
		celebrationData = {
			wordsWritten,
			dailyTarget,
			excess: wordsWritten - dailyTarget,
			percentage: Math.round((wordsWritten / dailyTarget) * 100)
		};
		showConfetti = true;
		open = true;
	}

	function showStreakCelebration(streak: number) {
		celebrationType = 'streak';
		celebrationData = {
			streak,
			isPersonalBest: streak > (progress_tracker.longestStreak || 0)
		};
		showConfetti = true;
		open = true;
	}

	function showProjectCelebration(percentage: number, currentWords: number, targetWords: number) {
		celebrationType = 'project';
		celebrationData = {
			percentage: Math.round(percentage),
			currentWords,
			targetWords,
			remainingWords: targetWords - currentWords
		};
		showConfetti = true;
		open = true;
	}

	function showGoalSuggestion() {
		celebrationType = 'suggestion';
		const currentGoal = progress_tracker.dailyGoalTarget;
		const averageWords = progress_tracker.averageDailyWords;
		const suggestedGoal = Math.round(Math.max(currentGoal * 1.2, averageWords * 1.1));

		celebrationData = {
			currentGoal,
			suggestedGoal,
			averageWords: Math.round(averageWords)
		};
		showConfetti = false;
		open = true;
	}

	function isStreakMilestone(streak: number): boolean {
		// Celebrate at 3, 7, 14, 30, 50, 100 days, then every 50
		const milestones = [3, 7, 14, 30, 50, 100];
		if (milestones.includes(streak)) return true;
		if (streak > 100 && streak % 50 === 0) return true;
		return false;
	}

	function isProjectMilestone(percentage: number): boolean {
		// Celebrate at 25%, 50%, 75%, 90%, 100%
		const milestones = [25, 50, 75, 90, 100];
		return milestones.some(
			(milestone) => percentage >= milestone && lastCheckedProjectProgress < milestone
		);
	}

	function shouldSuggestGoalIncrease(): boolean {
		const recentProgress = progress_tracker.getProgressForDateRange(7);
		if (recentProgress.length < 5) return false; // Need at least 5 days of data

		// Check if user has exceeded their goal by 20%+ for 5+ days in the last week
		const exceededDays = recentProgress.filter((day) => {
			const target = progress_tracker.dailyGoalTarget;
			return day.wordsWritten >= target * 1.2;
		});

		return exceededDays.length >= 5;
	}

	function calculateProjectWords(): number {
		// This would need to be implemented based on the project structure
		// For now, we'll use a placeholder
		return progress_tracker.todaysWordCount || 0;
	}

	function handleClose() {
		open = false;
		showConfetti = false;
		onClose?.();
	}

	function handleGoalIncrease() {
		if (celebrationType === 'suggestion' && celebrationData.suggestedGoal) {
			progress_tracker.setDailyGoal(celebrationData.suggestedGoal);
		}
		handleClose();
	}

	// Celebration messages
	const dailyMessages = [
		"🎉 Fantastic work! You've crushed today's writing goal!",
		'✨ Amazing! Another successful writing day in the books!',
		"🚀 You're on fire! Goal achieved with style!",
		"💪 Incredible dedication! You've hit your target!",
		'🌟 Outstanding! Your consistency is paying off!'
	];

	const streakMessages = {
		3: "🔥 Three days strong! You're building momentum!",
		7: "⚡ One week streak! You're developing a solid habit!",
		14: '💎 Two weeks! Your dedication is truly impressive!',
		30: "🏆 Thirty days! You're a writing champion!",
		50: '🎖️ Fifty days! This is legendary commitment!',
		100: "👑 One hundred days! You're a writing master!"
	};

	function getDailyMessage(): string {
		return dailyMessages[Math.floor(Math.random() * dailyMessages.length)];
	}

	function getStreakMessage(streak: number): string {
		if (streakMessages[streak as keyof typeof streakMessages]) {
			return streakMessages[streak as keyof typeof streakMessages];
		}
		if (streak % 50 === 0) {
			return `🌟 ${streak} days! Your consistency is absolutely incredible!`;
		}
		return `🔥 ${streak} day streak! Keep the momentum going!`;
	}

	function getProjectMessage(percentage: number): string {
		if (percentage >= 100) return '🎊 PROJECT COMPLETE! You did it! Time to celebrate!';
		if (percentage >= 90) return "🏁 Almost there! You're in the final stretch!";
		if (percentage >= 75) return '💪 Three-quarters done! The finish line is in sight!';
		if (percentage >= 50) return "🎯 Halfway there! You're making incredible progress!";
		if (percentage >= 25) return "🚀 Quarter milestone reached! You're building momentum!";
		return '🌟 Great progress on your project!';
	}
</script>

<!-- Confetti Animation (CSS-only) -->
{#if showConfetti}
	<div class="pointer-events-none fixed inset-0 z-60 overflow-hidden">
		<!-- eslint-disable-next-line @typescript-eslint/no-unused-vars -->
		{#each Array(50) as _, i (i)}
			<div
				class="absolute h-2 w-2 animate-bounce bg-accent opacity-80"
				style="
					left: {Math.random() * 100}%;
					top: -10px;
					animation-delay: {Math.random() * 2}s;
					animation-duration: {2 + Math.random() * 2}s;
					background-color: hsl({Math.random() * 360}, 70%, 60%);
				"
			></div>
		{/each}
	</div>
{/if}

<AlertDialog.Root bind:open>
	<AlertDialog.Portal>
		<AlertDialog.Overlay
			class="data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0 fixed inset-0 z-50 bg-black/50"
		/>
		<AlertDialog.Content
			class="data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0 data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-95 data-[state=closed]:slide-out-to-left-1/2 data-[state=closed]:slide-out-to-top-[48%] data-[state=open]:slide-in-from-left-1/2 data-[state=open]:slide-in-from-top-[48%] fixed top-1/2 left-1/2 z-50 grid w-full max-w-lg -translate-x-1/2 -translate-y-1/2 gap-4 rounded-lg border border-border bg-background p-6 shadow-lg duration-200"
		>
			{#if celebrationType === 'daily'}
				<div class="flex flex-col space-y-4 text-center">
					<div class="mb-2 text-4xl">🎉</div>
					<AlertDialog.Title class="text-xl font-bold text-text">
						Daily Goal Achieved!
					</AlertDialog.Title>
					<AlertDialog.Description class="text-text-secondary">
						{getDailyMessage()}
					</AlertDialog.Description>

					<div class="space-y-2 rounded-lg bg-surface p-4">
						<div class="flex justify-between text-sm">
							<span>Words written today:</span>
							<span class="font-semibold text-accent"
								>{celebrationData.wordsWritten?.toLocaleString()}</span
							>
						</div>
						<div class="flex justify-between text-sm">
							<span>Daily goal:</span>
							<span>{celebrationData.dailyTarget?.toLocaleString()}</span>
						</div>
						{#if celebrationData.excess && celebrationData.excess > 0}
							<div class="flex justify-between text-sm text-green-600 dark:text-green-400">
								<span>Bonus words:</span>
								<span class="font-semibold">+{celebrationData.excess?.toLocaleString()}</span>
							</div>
						{/if}
					</div>
				</div>
			{:else if celebrationType === 'streak'}
				<div class="flex flex-col space-y-4 text-center">
					<div class="mb-2 text-4xl">🔥</div>
					<AlertDialog.Title class="text-xl font-bold text-text">
						{celebrationData.streak} Day Streak!
					</AlertDialog.Title>
					<AlertDialog.Description class="text-text-secondary">
						{getStreakMessage(celebrationData.streak || 0)}
					</AlertDialog.Description>

					{#if celebrationData.isPersonalBest}
						<div
							class="rounded-lg bg-linear-to-r from-yellow-100 to-yellow-200 p-3 dark:from-yellow-900/30 dark:to-yellow-800/30"
						>
							<p class="text-sm font-medium text-yellow-800 dark:text-yellow-200">
								🏆 New Personal Best!
							</p>
						</div>
					{/if}
				</div>
			{:else if celebrationType === 'project'}
				<div class="flex flex-col space-y-4 text-center">
					<div class="mb-2 text-4xl">
						{(celebrationData.percentage || 0) >= 100 ? '🎊' : '🎯'}
					</div>
					<AlertDialog.Title class="text-xl font-bold text-text">
						{celebrationData.percentage}% Complete!
					</AlertDialog.Title>
					<AlertDialog.Description class="text-text-secondary">
						{getProjectMessage(celebrationData.percentage || 0)}
					</AlertDialog.Description>

					<div class="space-y-2 rounded-lg bg-surface p-4">
						<div class="flex justify-between text-sm">
							<span>Current progress:</span>
							<span class="font-semibold"
								>{celebrationData.currentWords?.toLocaleString()} words</span
							>
						</div>
						<div class="flex justify-between text-sm">
							<span>Project goal:</span>
							<span>{celebrationData.targetWords?.toLocaleString()} words</span>
						</div>
						{#if (celebrationData.percentage || 0) < 100}
							<div class="flex justify-between text-sm text-blue-600 dark:text-blue-400">
								<span>Remaining:</span>
								<span>{celebrationData.remainingWords?.toLocaleString()} words</span>
							</div>
						{/if}
					</div>
				</div>
			{:else if celebrationType === 'suggestion'}
				<div class="flex flex-col space-y-4 text-center">
					<div class="mb-2 text-4xl">💪</div>
					<AlertDialog.Title class="text-xl font-bold text-text">
						Ready for a Challenge?
					</AlertDialog.Title>
					<AlertDialog.Description class="text-text-secondary">
						You've been consistently exceeding your daily goal! Consider increasing your target to
						match your amazing progress.
					</AlertDialog.Description>

					<div class="space-y-2 rounded-lg bg-surface p-4">
						<div class="flex justify-between text-sm">
							<span>Current daily goal:</span>
							<span>{celebrationData.currentGoal?.toLocaleString()} words</span>
						</div>
						<div class="flex justify-between text-sm">
							<span>Your recent average:</span>
							<span class="font-semibold text-accent"
								>{celebrationData.averageWords?.toLocaleString()} words</span
							>
						</div>
						<div class="flex justify-between text-sm text-green-600 dark:text-green-400">
							<span>Suggested new goal:</span>
							<span class="font-semibold"
								>{celebrationData.suggestedGoal?.toLocaleString()} words</span
							>
						</div>
					</div>
				</div>
			{/if}

			<div class="flex flex-col-reverse sm:flex-row sm:justify-end sm:space-x-2">
				<AlertDialog.Cancel
					class="mt-2 inline-flex h-9 items-center justify-center rounded-md border border-border bg-transparent px-4 py-2 text-sm font-medium text-text transition-colors hover:bg-background-tertiary focus:bg-background-tertiary focus:ring-2 focus:ring-accent focus:ring-offset-2 focus:outline-none disabled:cursor-not-allowed disabled:opacity-50 sm:mt-0"
					onclick={handleClose}
				>
					{celebrationType === 'suggestion' ? 'Keep Current Goal' : 'Close'}
				</AlertDialog.Cancel>

				{#if celebrationType === 'suggestion'}
					<AlertDialog.Action
						class="inline-flex h-9 items-center justify-center rounded-md bg-accent px-4 py-2 text-sm font-medium text-text-inverse transition-colors hover:bg-accent-hover focus:ring-2 focus:ring-accent focus:ring-offset-2 focus:outline-none disabled:cursor-not-allowed disabled:opacity-50"
						onclick={handleGoalIncrease}
					>
						Increase Goal
					</AlertDialog.Action>
				{:else}
					<AlertDialog.Action
						class="inline-flex h-9 items-center justify-center rounded-md bg-accent px-4 py-2 text-sm font-medium text-text-inverse transition-colors hover:bg-accent-hover focus:ring-2 focus:ring-accent focus:ring-offset-2 focus:outline-none disabled:cursor-not-allowed disabled:opacity-50"
						onclick={handleClose}
					>
						Awesome!
					</AlertDialog.Action>
				{/if}
			</div>
		</AlertDialog.Content>
	</AlertDialog.Portal>
</AlertDialog.Root>

<style>
	@keyframes confetti-fall {
		0% {
			transform: translateY(-100vh) rotate(0deg);
			opacity: 1;
		}
		100% {
			transform: translateY(100vh) rotate(360deg);
			opacity: 0;
		}
	}

	.animate-bounce {
		animation: confetti-fall 3s linear infinite;
	}
</style>
