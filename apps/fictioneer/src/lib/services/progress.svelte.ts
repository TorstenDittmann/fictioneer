import { SvelteDate, SvelteMap } from 'svelte/reactivity';
import type {
	ProgressGoals,
	DailyProgress,
	ProgressStats,
	ChartDataPoint
} from '../types/progress.js';
import type { Project } from './projects.svelte.js';

/**
 * Service class for managing progress tracking functionality
 * Handles goal management, progress calculation, and statistics generation
 */
class ProgressService {
	/**
	 * Set daily word count goal for a project
	 */
	setDailyGoal(project: Project, wordTarget: number): boolean {
		if (!this.validateWordTarget(wordTarget)) {
			return false;
		}

		const now = new Date();

		if (!project.progressGoals) {
			project.progressGoals = {
				dailyWordTarget: wordTarget,
				createdAt: now,
				updatedAt: now
			};
		} else {
			project.progressGoals.dailyWordTarget = wordTarget;
			project.progressGoals.updatedAt = now;
		}

		return true;
	}

	/**
	 * Set project-level word count goal
	 */
	setProjectGoal(project: Project, wordTarget: number): boolean {
		if (!this.validateWordTarget(wordTarget)) {
			return false;
		}

		const now = new Date();

		if (!project.progressGoals) {
			project.progressGoals = {
				dailyWordTarget: 500, // Default daily goal
				projectWordTarget: wordTarget,
				createdAt: now,
				updatedAt: now
			};
		} else {
			project.progressGoals.projectWordTarget = wordTarget;
			project.progressGoals.updatedAt = now;
		}

		return true;
	}

	/**
	 * Update daily progress for a specific date
	 */
	updateDailyProgress(project: Project, date: string, wordsWritten: number): boolean {
		if (!this.validateDate(date) || !this.validateWordCount(wordsWritten)) {
			return false;
		}

		if (!project.dailyProgress) {
			project.dailyProgress = [];
		}

		const existingProgressIndex = project.dailyProgress.findIndex((p) => p.date === date);
		const now = new Date();
		const dailyGoal = project.progressGoals?.dailyWordTarget || 500;

		const progressEntry: DailyProgress = {
			date,
			wordsWritten,
			goalMet: wordsWritten >= dailyGoal,
			sessionsCount: 1, // Will be updated by session tracking
			createdAt:
				existingProgressIndex === -1 ? now : project.dailyProgress[existingProgressIndex].createdAt,
			updatedAt: now
		};

		if (existingProgressIndex === -1) {
			project.dailyProgress.push(progressEntry);
		} else {
			// Preserve session count when updating existing progress
			progressEntry.sessionsCount = project.dailyProgress[existingProgressIndex].sessionsCount;
			project.dailyProgress[existingProgressIndex] = progressEntry;
		}

		// Update progress statistics
		project.progressStats = this.calculateProgressStats(project);

		return true;
	}

	/**
	 * Calculate comprehensive progress statistics
	 */
	calculateProgressStats(project: Project): ProgressStats {
		const dailyProgress = project.dailyProgress || [];
		const progressGoals = project.progressGoals;

		if (dailyProgress.length === 0) {
			return {
				currentStreak: 0,
				longestStreak: 0,
				totalDaysActive: 0,
				averageDailyWords: 0
			};
		}

		// Sort progress by date
		const sortedProgress = [...dailyProgress].sort((a, b) => a.date.localeCompare(b.date));

		// Calculate streaks
		const { currentStreak, longestStreak } = this.calculateStreaks(sortedProgress);

		// Calculate active days and average
		const activeDays = sortedProgress.filter((p) => p.wordsWritten > 0);
		const totalDaysActive = activeDays.length;
		const totalWords = activeDays.reduce((sum, p) => sum + p.wordsWritten, 0);
		const averageDailyWords = totalDaysActive > 0 ? Math.round(totalWords / totalDaysActive) : 0;

		// Calculate estimated completion date
		let estimatedCompletionDate: Date | undefined;
		if (progressGoals?.projectWordTarget && averageDailyWords > 0) {
			const currentProjectWords = this.calculateProjectWordCount(project);
			const remainingWords = progressGoals.projectWordTarget - currentProjectWords;

			if (remainingWords > 0) {
				const daysToComplete = Math.ceil(remainingWords / averageDailyWords);
				estimatedCompletionDate = new SvelteDate();
				estimatedCompletionDate.setDate(estimatedCompletionDate.getDate() + daysToComplete);
			}
		}

		return {
			currentStreak,
			longestStreak,
			totalDaysActive,
			averageDailyWords,
			estimatedCompletionDate
		};
	}

	/**
	 * Get daily progress for the last N days
	 */
	getDailyProgress(project: Project, days: number): DailyProgress[] {
		if (!project.dailyProgress || days <= 0) {
			return [];
		}

		const endDate = new Date();
		const startDate = new SvelteDate();
		startDate.setDate(endDate.getDate() - days + 1);

		return project.dailyProgress
			.filter((p) => {
				const progressDate = new Date(p.date);
				return progressDate >= startDate && progressDate <= endDate;
			})
			.sort((a, b) => a.date.localeCompare(b.date));
	}

	/**
	 * Get today's progress
	 */
	getTodaysProgress(project: Project): DailyProgress | null {
		if (!project.dailyProgress) {
			return null;
		}

		const today = this.formatDate(new Date());
		return project.dailyProgress.find((p) => p.date === today) || null;
	}

	/**
	 * Check if daily goal is met for given progress
	 */
	isGoalMet(progress: DailyProgress, goals: ProgressGoals): boolean {
		return progress.wordsWritten >= goals.dailyWordTarget;
	}

	/**
	 * Calculate current and longest streaks
	 */
	calculateStreak(dailyProgress: DailyProgress[]): number {
		const { currentStreak } = this.calculateStreaks(dailyProgress);
		return currentStreak;
	}

	/**
	 * Generate chart data for visualization
	 */
	getChartData(project: Project, days: number = 30): ChartDataPoint[] {
		const dailyGoal = project.progressGoals?.dailyWordTarget || 500;
		const endDate = new Date();
		const startDate = new SvelteDate();
		startDate.setDate(endDate.getDate() - days + 1);

		const chartData: ChartDataPoint[] = [];
		const progressMap = new SvelteMap<string, DailyProgress>();

		// Create a map of existing progress data
		if (project.dailyProgress) {
			project.dailyProgress.forEach((p) => progressMap.set(p.date, p));
		}

		// Generate data points for each day in the range
		for (let d = new SvelteDate(startDate); d <= endDate; d.setDate(d.getDate() + 1)) {
			const dateStr = this.formatDate(d);
			const progress = progressMap.get(dateStr);
			const isToday = dateStr === this.formatDate(new Date());

			chartData.push({
				date: dateStr,
				wordsWritten: progress?.wordsWritten || 0,
				goalTarget: dailyGoal,
				goalMet: progress?.goalMet || false,
				isToday
			});
		}

		return chartData;
	}

	/**
	 * Calculate total project word count from all scenes
	 */
	private calculateProjectWordCount(project: Project): number {
		let totalWords = 0;

		for (const chapter of project.chapters) {
			for (const scene of chapter.scenes) {
				totalWords += scene.wordCount;
			}
		}

		return totalWords;
	}

	/**
	 * Calculate both current and longest streaks
	 */
	private calculateStreaks(sortedProgress: DailyProgress[]): {
		currentStreak: number;
		longestStreak: number;
	} {
		if (sortedProgress.length === 0) {
			return { currentStreak: 0, longestStreak: 0 };
		}

		let currentStreak = 0;
		let longestStreak = 0;
		let tempStreak = 0;

		// Calculate streaks from most recent backwards
		const today = this.formatDate(new Date());
		const reversedProgress = [...sortedProgress].reverse();

		for (let i = 0; i < reversedProgress.length; i++) {
			const progress = reversedProgress[i];

			if (progress.goalMet) {
				tempStreak++;

				// If this is the first entry or it's today, start counting current streak
				if (
					i === 0 &&
					(progress.date === today || this.isConsecutiveDay(progress.date, today, i))
				) {
					currentStreak = tempStreak;
				} else if (currentStreak > 0 && i > 0) {
					// Check if this day is consecutive to the previous day in our streak
					const prevProgress = reversedProgress[i - 1];
					if (!this.isConsecutiveDay(progress.date, prevProgress.date, 1)) {
						// Streak broken, but we already have our current streak
						break;
					} else {
						currentStreak = tempStreak;
					}
				}

				longestStreak = Math.max(longestStreak, tempStreak);
			} else {
				// Goal not met, reset temp streak
				if (i === 0 || currentStreak === 0) {
					// If this is today or we haven't established a current streak, reset current streak
					currentStreak = 0;
				}
				tempStreak = 0;
			}
		}

		return { currentStreak, longestStreak };
	}

	/**
	 * Check if two dates are consecutive days
	 */
	private isConsecutiveDay(date1: string, date2: string, expectedDiff: number): boolean {
		const d1 = new Date(date1);
		const d2 = new Date(date2);
		const diffTime = Math.abs(d2.getTime() - d1.getTime());
		const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
		return diffDays === expectedDiff;
	}

	/**
	 * Format date as ISO string (YYYY-MM-DD)
	 */
	private formatDate(date: Date): string {
		return date.toISOString().split('T')[0];
	}

	/**
	 * Validate word target input
	 */
	private validateWordTarget(target: number): boolean {
		return (
			typeof target === 'number' &&
			target > 0 &&
			target <= 50000 && // Reasonable upper limit
			Number.isInteger(target)
		);
	}

	/**
	 * Validate word count input
	 */
	private validateWordCount(count: number): boolean {
		return typeof count === 'number' && count >= 0 && Number.isInteger(count);
	}

	/**
	 * Validate date string format (YYYY-MM-DD)
	 */
	private validateDate(dateStr: string): boolean {
		const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
		if (!dateRegex.test(dateStr)) {
			return false;
		}

		const date = new Date(dateStr);
		return (
			date instanceof Date && !isNaN(date.getTime()) && date.toISOString().split('T')[0] === dateStr
		);
	}

	/**
	 * Increment session count for today
	 */
	incrementSessionCount(project: Project): boolean {
		const today = this.formatDate(new Date());

		if (!project.dailyProgress) {
			project.dailyProgress = [];
		}

		const todayProgressIndex = project.dailyProgress.findIndex((p) => p.date === today);

		if (todayProgressIndex === -1) {
			// Create new progress entry for today
			const now = new Date();

			project.dailyProgress.push({
				date: today,
				wordsWritten: 0,
				goalMet: false,
				sessionsCount: 1,
				createdAt: now,
				updatedAt: now
			});
		} else {
			// Increment existing session count
			project.dailyProgress[todayProgressIndex].sessionsCount++;
			project.dailyProgress[todayProgressIndex].updatedAt = new Date();
		}

		return true;
	}
}

// Export a singleton instance
export const progress_service = new ProgressService();
