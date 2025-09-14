<script lang="ts">
	import { progress_tracker } from '$lib/state/progress.svelte';
	import { projects } from '$lib/state/projects.svelte';
	import ProgressGoals from './progress_goals.svelte';
	import TodaysProgress from './todays_progress.svelte';
	import ProgressChart from './progress_chart.svelte';
	import ProgressStats from './progress_stats.svelte';

	import { Button } from './ui';

	interface Props {
		class?: string;
	}

	let { class: additional_class = '' }: Props = $props();

	// Modal states
	let showGoalsModal = $state(false);

	// Reactive data from progress tracker
	const todaysProgress = $derived(progress_tracker.todaysProgress);
	const currentGoals = $derived(progress_tracker.currentGoals);
	const progressStats = $derived(progress_tracker.progressStats);
	const chartData = $derived(progress_tracker.chartData);
	const hasGoals = $derived(progress_tracker.hasGoals);
	const totalProjectWords = $derived(calculateTotalProjectWords());

	// Calculate total project words from current project
	function calculateTotalProjectWords(): number {
		const project = projects.project;
		if (!project) return 0;

		let totalWords = 0;
		for (const chapter of project.chapters) {
			for (const scene of chapter.scenes) {
				totalWords += scene.wordCount;
			}
		}
		return totalWords;
	}

	// Handle goal setup
	function handleSetupGoals() {
		showGoalsModal = true;
	}

	// Check if we should show the dashboard
	const shouldShowDashboard = $derived(hasGoals || todaysProgress !== null);
</script>

<div class="progress-dashboard {additional_class}">
	{#if shouldShowDashboard}
		<!-- Progress Dashboard Header -->
		<div class="mb-6 flex items-center justify-between">
			<h2 class="text-xl font-semibold text-text">Writing Progress</h2>
			<Button variant="outline" onclick={handleSetupGoals} class="px-3 py-1 text-xs">
				{hasGoals ? 'Update Goals' : 'Set Goals'}
			</Button>
		</div>

		<!-- Dashboard Content -->
		<div class="space-y-6">
			<!-- Today's Progress Section -->
			{#if hasGoals}
				<div class="rounded-lg bg-background-secondary p-6 shadow-sm ring-1 ring-border">
					<TodaysProgress {todaysProgress} goals={currentGoals} class="w-full" />
				</div>
			{/if}

			<!-- Progress Chart and Stats Stack -->
			<div class="space-y-6">
				<!-- Progress Chart -->
				<div class="rounded-lg bg-background-secondary p-6 shadow-sm ring-1 ring-border">
					<h3 class="mb-4 text-lg font-medium text-text">30-Day Progress</h3>
					{#if chartData.length > 0}
						<ProgressChart data={chartData} class="w-full" />
					{:else}
						<div class="flex h-48 items-center justify-center text-center">
							<div>
								<p class="text-sm text-text-secondary">Start writing to see your progress chart</p>
							</div>
						</div>
					{/if}
				</div>

				<!-- Progress Statistics -->
				<div class="rounded-lg bg-background-secondary p-6 shadow-sm ring-1 ring-border">
					<ProgressStats
						stats={progressStats}
						goals={currentGoals}
						{totalProjectWords}
						class="w-full"
					/>
				</div>
			</div>
		</div>
	{:else}
		<!-- Setup Prompt -->
		<div class="rounded-lg bg-background-secondary p-8 text-center shadow-sm ring-1 ring-border">
			<div class="mx-auto max-w-md">
				<div class="mb-4 text-4xl">📊</div>
				<h2 class="mb-2 text-xl font-semibold text-text">Track Your Writing Progress</h2>
				<p class="mb-6 text-text-secondary">
					Set daily writing goals and track your progress with visual charts, statistics, and
					motivational feedback.
				</p>

				<div class="mb-6 space-y-3 text-sm text-text-muted">
					<div class="flex items-center justify-center gap-2">
						<span>•</span>
						<span>Visual progress charts</span>
					</div>
					<div class="flex items-center justify-center gap-2">
						<span>•</span>
						<span>Writing streak tracking</span>
					</div>
					<div class="flex items-center justify-center gap-2">
						<span>•</span>
						<span>Goal achievement celebrations</span>
					</div>
					<div class="flex items-center justify-center gap-2">
						<span>•</span>
						<span>Detailed writing statistics</span>
					</div>
				</div>

				<Button variant="primary" onclick={handleSetupGoals} class="px-6">
					Set Up Progress Tracking
				</Button>
			</div>
		</div>
	{/if}
</div>

<!-- Goals Modal -->
<ProgressGoals bind:open={showGoalsModal} />

<!-- Celebration Modal (disabled for now to prevent auto-opening) -->
<!-- <GoalCelebration 
	bind:open={showCelebration} 
	onClose={handleCelebrationClose}
/> -->

<style>
	.progress-dashboard {
		width: 100%;
	}

	/* Responsive adjustments */
	@media (max-width: 640px) {
		.progress-dashboard {
			font-size: 0.875rem;
		}
	}
</style>
