import type {
	ProgressGoals,
	DailyProgress,
	ProgressStats,
	ChartDataPoint
} from '../types/progress.js';
import type { Project } from '../services/projects.svelte.js';
import type {
	ProjectsStateReference,
	ProgressTrackerState,
	ProjectsState
} from '../types/state.js';
import { progress_service } from '../services/progress.svelte.js';

/**
 * Reactive state management for progress tracking
 * Follows the existing state pattern used in projects.svelte.ts
 * This class works in coordination with the projects state for data synchronization
 */
class ProgressTracker implements ProgressTrackerState {
	private trigger = $state(0);
	private _projects: ProjectsStateReference | null = null; // Will be injected to avoid circular dependency

	constructor() {
		// Initialize any default state if needed
	}

	// Inject projects dependency to avoid circular imports
	setProjectsReference(projectsRef: ProjectsStateReference) {
		this._projects = projectsRef;
		// Set up bidirectional reference
		if ('setProgressTrackerReference' in projectsRef) {
			(projectsRef as ProjectsState).setProgressTrackerReference(this);
		}
	}

	// Get current project from injected projects reference
	private get currentProject(): Project | null {
		return this._projects?.project || null;
	}

	// Trigger reactivity by updating a counter
	private trigger_update() {
		this.trigger = Date.now();
	}

	// Getters for reactive progress data
	get todaysProgress(): DailyProgress | null {
		// Trigger reactivity
		void this.trigger;

		const project = this.currentProject;
		if (!project) return null;

		return progress_service.getTodaysProgress(project);
	}

	get currentGoals(): ProgressGoals | null {
		// Trigger reactivity
		void this.trigger;

		const project = this.currentProject;
		if (!project) return null;

		return project.progressGoals || null;
	}

	get progressStats(): ProgressStats | null {
		// Trigger reactivity
		void this.trigger;

		const project = this.currentProject;
		if (!project) return null;

		return project.progressStats || null;
	}

	get chartData(): ChartDataPoint[] {
		// Trigger reactivity
		void this.trigger;

		const project = this.currentProject;
		if (!project) return [];

		return progress_service.getChartData(project, 30);
	}

	get dailyProgressHistory(): DailyProgress[] {
		// Trigger reactivity
		void this.trigger;

		const project = this.currentProject;
		if (!project) return [];

		return progress_service.getDailyProgress(project, 30);
	}

	get hasGoals(): boolean {
		return this.currentGoals !== null;
	}

	get hasTodaysProgress(): boolean {
		return this.todaysProgress !== null;
	}

	get dailyGoalTarget(): number {
		return this.currentGoals?.dailyWordTarget || 500;
	}

	get projectGoalTarget(): number | null {
		return this.currentGoals?.projectWordTarget || null;
	}

	get todaysWordCount(): number {
		return this.todaysProgress?.wordsWritten || 0;
	}

	get todaysGoalMet(): boolean {
		return this.todaysProgress?.goalMet || false;
	}

	get todaysProgressPercentage(): number {
		const target = this.dailyGoalTarget;
		const current = this.todaysWordCount;

		if (target === 0) return 0;
		return Math.min(Math.round((current / target) * 100), 100);
	}

	get currentStreak(): number {
		return this.progressStats?.currentStreak || 0;
	}

	get longestStreak(): number {
		return this.progressStats?.longestStreak || 0;
	}

	get averageDailyWords(): number {
		return this.progressStats?.averageDailyWords || 0;
	}

	get estimatedCompletionDate(): Date | null {
		return this.progressStats?.estimatedCompletionDate || null;
	}

	// Methods for goal setting and progress updates
	setDailyGoal(target: number): boolean {
		const project = this.currentProject;
		if (!project) {
			throw new Error('No project loaded');
		}

		const success = progress_service.setDailyGoal(project, target);
		if (success) {
			// Trigger update in both progress tracker and projects state
			this.trigger_update();
			this._projects?.triggerUpdate?.();
		}
		return success;
	}

	setProjectGoal(target: number): boolean {
		const project = this.currentProject;
		if (!project) {
			throw new Error('No project loaded');
		}

		const success = progress_service.setProjectGoal(project, target);
		if (success) {
			// Trigger update in both progress tracker and projects state
			this.trigger_update();
			this._projects?.triggerUpdate?.();
		}
		return success;
	}

	updateProgress(): boolean {
		const project = this.currentProject;
		if (!project) {
			throw new Error('No project loaded');
		}

		// Calculate current project word count
		let totalWords = 0;
		for (const chapter of project.chapters) {
			for (const scene of chapter.scenes) {
				totalWords += scene.wordCount;
			}
		}

		// Get today's date
		const today = new Date().toISOString().split('T')[0];

		// Update daily progress with current word count
		const success = progress_service.updateDailyProgress(project, today, totalWords);
		if (success) {
			// Trigger update in both progress tracker and projects state
			this.trigger_update();
			this._projects?.triggerUpdate?.();
		}
		return success;
	}

	incrementSessionCount(): boolean {
		const project = this.currentProject;
		if (!project) {
			throw new Error('No project loaded');
		}

		const success = progress_service.incrementSessionCount(project);
		if (success) {
			// Trigger update in both progress tracker and projects state
			this.trigger_update();
			this._projects?.triggerUpdate?.();
		}
		return success;
	}

	/**
	 * Calculate progress for a specific date range
	 */
	getProgressForDateRange(days: number): DailyProgress[] {
		const project = this.currentProject;
		if (!project) return [];

		return progress_service.getDailyProgress(project, days);
	}

	/**
	 * Get chart data for a specific number of days
	 */
	getChartDataForDays(days: number): ChartDataPoint[] {
		const project = this.currentProject;
		if (!project) return [];

		return progress_service.getChartData(project, days);
	}

	/**
	 * Check if a specific goal is met for today
	 */
	isGoalMetToday(): boolean {
		const progress = this.todaysProgress;
		const goals = this.currentGoals;

		if (!progress || !goals) return false;

		return progress_service.isGoalMet(progress, goals);
	}

	/**
	 * Calculate streak information
	 */
	calculateCurrentStreak(): number {
		const project = this.currentProject;
		if (!project || !project.dailyProgress) return 0;

		return progress_service.calculateStreak(project.dailyProgress);
	}

	/**
	 * Force recalculation of progress statistics
	 */
	recalculateStats(): boolean {
		const project = this.currentProject;
		if (!project) {
			throw new Error('No project loaded');
		}

		project.progressStats = progress_service.calculateProgressStats(project);
		// Trigger update in both progress tracker and projects state
		this.trigger_update();
		this._projects?.triggerUpdate?.();
		return true;
	}

	/**
	 * Reset all progress data (for testing or fresh start)
	 */
	resetProgress(): boolean {
		const project = this.currentProject;
		if (!project) {
			throw new Error('No project loaded');
		}

		project.dailyProgress = [];
		project.progressStats = progress_service.calculateProgressStats(project);
		// Trigger update in both progress tracker and projects state
		this.trigger_update();
		this._projects?.triggerUpdate?.();
		return true;
	}

	/**
	 * Initialize progress tracking for a new project
	 */
	initializeProgress(dailyGoal: number = 500, projectGoal?: number): boolean {
		const project = this.currentProject;
		if (!project) {
			throw new Error('No project loaded');
		}

		// Set up initial goals
		const success = progress_service.setDailyGoal(project, dailyGoal);
		if (!success) return false;

		if (projectGoal) {
			const projectSuccess = progress_service.setProjectGoal(project, projectGoal);
			if (!projectSuccess) return false;
		}

		// Initialize empty progress arrays
		if (!project.dailyProgress) {
			project.dailyProgress = [];
		}

		// Calculate initial stats
		project.progressStats = progress_service.calculateProgressStats(project);

		// Trigger update in both progress tracker and projects state
		this.trigger_update();
		this._projects?.triggerUpdate?.();
		return true;
	}

	/**
	 * Synchronize with projects state changes
	 * This method should be called when projects state updates
	 */
	syncWithProjectsState(): void {
		this.trigger_update();
	}

	/**
	 * Expose trigger_update method for projects state to call
	 * This ensures proper reactivity synchronization
	 */
	triggerUpdate(): void {
		this.trigger_update();
	}
}

// Export a singleton instance
export const progress_tracker = new ProgressTracker();
