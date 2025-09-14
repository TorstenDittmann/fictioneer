/**
 * Progress tracking type definitions for Fictioneer
 * These interfaces extend the existing project data model to support progress tracking
 */

/**
 * Progress goals configuration for a project
 */
export interface ProgressGoals {
	/** Daily word count target (default: 500) */
	dailyWordTarget: number;
	/** Optional overall project word count goal */
	projectWordTarget?: number;
	/** When the goals were created */
	createdAt: Date;
	/** When the goals were last updated */
	updatedAt: Date;
}

/**
 * Daily progress tracking data
 */
export interface DailyProgress {
	/** ISO date string (YYYY-MM-DD) */
	date: string;
	/** Words written on this specific day */
	wordsWritten: number;
	/** Whether the daily goal was achieved */
	goalMet: boolean;
	/** Number of writing sessions on this day */
	sessionsCount: number;
	/** When this progress entry was created */
	createdAt: Date;
	/** When this progress entry was last updated */
	updatedAt: Date;
}

/**
 * Calculated progress statistics
 */
export interface ProgressStats {
	/** Current consecutive days with goal met */
	currentStreak: number;
	/** Longest streak ever achieved */
	longestStreak: number;
	/** Total days with any writing activity */
	totalDaysActive: number;
	/** Average words per active day */
	averageDailyWords: number;
	/** Estimated completion date based on current velocity and remaining work */
	estimatedCompletionDate?: Date;
}

/**
 * Chart data point for visualization
 */
export interface ChartDataPoint {
	/** ISO date string */
	date: string;
	/** Words written that day */
	wordsWritten: number;
	/** Daily goal for that day */
	goalTarget: number;
	/** Whether goal was achieved */
	goalMet: boolean;
	/** Whether this is today's data */
	isToday: boolean;
}

/**
 * Extended project interface with progress tracking fields
 * This extends the base Project interface from the services layer
 */
export interface ProjectWithProgress {
	/** Progress goals configuration */
	progressGoals?: ProgressGoals;
	/** Array of daily progress entries */
	dailyProgress?: DailyProgress[];
	/** Calculated progress statistics */
	progressStats?: ProgressStats;
}
