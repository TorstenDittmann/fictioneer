<script lang="ts">
	import { Modal, Input, Label, Button } from '$lib/components/ui';
	import { progress_tracker } from '$lib/state/progress.svelte';
	import { onMount } from 'svelte';

	let { open = $bindable(false) }: { open: boolean } = $props();

	// Form state
	let dailyGoal = $state(500);
	let projectGoal = $state<number | null>(null);
	let projectGoalEnabled = $state(false);

	// Validation state
	let dailyGoalError = $state('');
	let projectGoalError = $state('');

	// UI state
	let isSubmitting = $state(false);
	let showConfirmation = $state(false);
	let hasExistingGoals = $state(false);

	// Load existing goals when component mounts or opens
	onMount(() => {
		loadExistingGoals();
	});

	$effect(() => {
		if (open) {
			loadExistingGoals();
		}
	});

	function loadExistingGoals() {
		const currentGoals = progress_tracker.currentGoals;
		hasExistingGoals = currentGoals !== null;

		if (currentGoals) {
			dailyGoal = currentGoals.dailyWordTarget;
			projectGoal = currentGoals.projectWordTarget || null;
			projectGoalEnabled = currentGoals.projectWordTarget !== undefined;
		} else {
			// Set defaults
			dailyGoal = 500;
			projectGoal = null;
			projectGoalEnabled = false;
		}

		// Clear any previous errors
		dailyGoalError = '';
		projectGoalError = '';
	}

	function validateForm(): boolean {
		let isValid = true;

		// Validate daily goal
		if (!dailyGoal || dailyGoal <= 0) {
			dailyGoalError = 'Daily goal must be greater than 0';
			isValid = false;
		} else if (dailyGoal > 10000) {
			dailyGoalError = 'Daily goal seems unreasonably high (max 10,000 words)';
			isValid = false;
		} else {
			dailyGoalError = '';
		}

		// Validate project goal if enabled
		if (projectGoalEnabled) {
			if (!projectGoal || projectGoal <= 0) {
				projectGoalError = 'Project goal must be greater than 0';
				isValid = false;
			} else if (projectGoal > 1000000) {
				projectGoalError = 'Project goal seems unreasonably high (max 1,000,000 words)';
				isValid = false;
			} else if (projectGoal < dailyGoal) {
				projectGoalError = 'Project goal should be larger than daily goal';
				isValid = false;
			} else {
				projectGoalError = '';
			}
		} else {
			projectGoalError = '';
		}

		return isValid;
	}

	function handleSubmit() {
		if (!validateForm()) {
			return;
		}

		// If goals already exist, show confirmation dialog
		if (hasExistingGoals) {
			showConfirmation = true;
		} else {
			saveGoals();
		}
	}

	function saveGoals() {
		isSubmitting = true;

		try {
			// Set daily goal
			const dailySuccess = progress_tracker.setDailyGoal(dailyGoal);
			if (!dailySuccess) {
				throw new Error('Failed to set daily goal');
			}

			// Set project goal if enabled
			if (projectGoalEnabled && projectGoal) {
				const projectSuccess = progress_tracker.setProjectGoal(projectGoal);
				if (!projectSuccess) {
					throw new Error('Failed to set project goal');
				}
			}

			// Close modal and confirmation dialog
			showConfirmation = false;
			open = false;
		} catch (error) {
			console.error('Error saving goals:', error);
			// You could add a toast notification here
		} finally {
			isSubmitting = false;
		}
	}

	function cancelConfirmation() {
		showConfirmation = false;
		// Reload existing goals to reset form
		loadExistingGoals();
	}

	function handleCancel() {
		if (showConfirmation) {
			cancelConfirmation();
		} else {
			open = false;
			// Reset form to existing values
			loadExistingGoals();
		}
	}

	// Format numbers for display
	function formatNumber(value: number | null): string {
		return value?.toString() || '';
	}

	// Parse number input
	function parseNumber(value: string): number | null {
		const parsed = parseInt(value, 10);
		return isNaN(parsed) ? null : parsed;
	}
</script>

<Modal bind:open>
	<div class="space-y-4 p-2">
		<div class="flex items-center justify-between">
			<h2 class="text-lg font-semibold text-text">
				{hasExistingGoals ? 'Update Writing Goals' : 'Set Writing Goals'}
			</h2>
		</div>

		{#if !showConfirmation}
			<!-- Main form -->
			<div class="space-y-4">
				<p class="text-sm text-text-secondary">
					Set your writing goals to track progress and stay motivated. You can change these anytime.
				</p>

				<!-- Daily Goal -->
				<div class="space-y-2">
					<Label for="daily-goal" class="text-sm font-medium text-text">
						Daily Word Count Goal
					</Label>
					<Input
						id="daily-goal"
						type="number"
						min="1"
						max="10000"
						placeholder="500"
						value={formatNumber(dailyGoal)}
						oninput={(e) => {
							const value = parseNumber(e.currentTarget.value);
							dailyGoal = value || 0;
							if (dailyGoalError) {
								dailyGoalError = '';
							}
						}}
						class={dailyGoalError ? 'border-red-500 focus:ring-red-500' : ''}
					/>
					{#if dailyGoalError}
						<p class="text-xs text-red-500">{dailyGoalError}</p>
					{/if}
					<p class="text-xs text-text-muted">
						Recommended: 250-1000 words per day for consistent progress
					</p>
				</div>

				<!-- Project Goal Toggle -->
				<div class="space-y-2">
					<label class="flex items-center gap-2 rounded-md border border-border bg-background p-3">
						<input
							type="checkbox"
							bind:checked={projectGoalEnabled}
							onchange={() => {
								if (!projectGoalEnabled) {
									projectGoal = null;
									projectGoalError = '';
								}
							}}
						/>
						<span class="text-sm text-text">Set overall project word count goal</span>
					</label>
				</div>

				<!-- Project Goal -->
				{#if projectGoalEnabled}
					<div class="space-y-2">
						<Label for="project-goal" class="text-sm font-medium text-text">
							Project Word Count Goal
						</Label>
						<Input
							id="project-goal"
							type="number"
							min="1"
							max="1000000"
							placeholder="80000"
							value={formatNumber(projectGoal)}
							oninput={(e) => {
								const value = parseNumber(e.currentTarget.value);
								projectGoal = value;
								if (projectGoalError) {
									projectGoalError = '';
								}
							}}
							class={projectGoalError ? 'border-red-500 focus:ring-red-500' : ''}
						/>
						{#if projectGoalError}
							<p class="text-xs text-red-500">{projectGoalError}</p>
						{/if}
						<p class="text-xs text-text-muted">
							Typical novel: 70,000-100,000 words • Novella: 20,000-50,000 words
						</p>
					</div>
				{/if}

				<!-- Current Goals Display -->
				{#if hasExistingGoals}
					<div class="rounded-md border border-border bg-surface p-3">
						<h4 class="mb-2 text-sm font-medium text-text">Current Goals</h4>
						<div class="space-y-1 text-xs text-text-secondary">
							<p>Daily: {progress_tracker.dailyGoalTarget.toLocaleString()} words</p>
							{#if progress_tracker.projectGoalTarget}
								<p>Project: {progress_tracker.projectGoalTarget.toLocaleString()} words</p>
							{/if}
						</div>
					</div>
				{/if}
			</div>

			<!-- Form Actions -->
			<div class="flex justify-end gap-2 pt-2">
				<Button variant="secondary" onclick={handleCancel} disabled={isSubmitting}>Cancel</Button>
				<Button variant="primary" onclick={handleSubmit} disabled={isSubmitting}>
					{isSubmitting ? 'Saving...' : hasExistingGoals ? 'Update Goals' : 'Set Goals'}
				</Button>
			</div>
		{:else}
			<!-- Confirmation Dialog -->
			<div class="space-y-4">
				<div
					class="rounded-md border border-amber-200 bg-amber-50 p-4 dark:border-amber-800 dark:bg-amber-900/20"
				>
					<h3 class="mb-2 text-sm font-medium text-amber-800 dark:text-amber-200">
						Confirm Goal Changes
					</h3>
					<p class="mb-3 text-sm text-amber-700 dark:text-amber-300">
						You're about to update your writing goals. This will affect your progress tracking going
						forward.
					</p>

					<div class="space-y-2 text-xs">
						<div class="flex justify-between">
							<span class="text-amber-700 dark:text-amber-300">Current daily goal:</span>
							<span class="font-medium"
								>{progress_tracker.dailyGoalTarget.toLocaleString()} words</span
							>
						</div>
						<div class="flex justify-between">
							<span class="text-amber-700 dark:text-amber-300">New daily goal:</span>
							<span class="font-medium">{dailyGoal.toLocaleString()} words</span>
						</div>

						{#if progress_tracker.projectGoalTarget || (projectGoalEnabled && projectGoal)}
							<div class="flex justify-between">
								<span class="text-amber-700 dark:text-amber-300">Current project goal:</span>
								<span class="font-medium">
									{progress_tracker.projectGoalTarget?.toLocaleString() || 'None'} words
								</span>
							</div>
							<div class="flex justify-between">
								<span class="text-amber-700 dark:text-amber-300">New project goal:</span>
								<span class="font-medium">
									{projectGoalEnabled && projectGoal ? projectGoal.toLocaleString() : 'None'} words
								</span>
							</div>
						{/if}
					</div>
				</div>
			</div>

			<!-- Confirmation Actions -->
			<div class="flex justify-end gap-2 pt-2">
				<Button variant="secondary" onclick={cancelConfirmation} disabled={isSubmitting}>
					Cancel
				</Button>
				<Button variant="primary" onclick={saveGoals} disabled={isSubmitting}>
					{isSubmitting ? 'Updating...' : 'Confirm Changes'}
				</Button>
			</div>
		{/if}
	</div>
</Modal>
