/**
 * Type definitions for state management cross-references
 * These interfaces help avoid circular dependency issues while maintaining type safety
 */

import type { Project } from '../services/projects.svelte.js';
import type { ProgressGoals, DailyProgress, ProgressStats } from './progress.js';

/**
 * Interface for Projects state that can be referenced by ProgressTracker
 */
export interface ProjectsStateReference {
	project: Project | null;
	triggerUpdate: () => void;
}

/**
 * Interface for ProgressTracker that can be referenced by Projects state
 */
export interface ProgressTrackerReference {
	syncWithProjectsState?: () => void;
}

/**
 * Extended interfaces for the actual state classes
 */
export interface ProjectsState extends ProjectsStateReference {
	setProgressTrackerReference(ref: ProgressTrackerReference): void;
}

export interface ProgressTrackerState extends ProgressTrackerReference {
	setProjectsReference(ref: ProjectsStateReference): void;
	// Progress tracking properties
	todaysProgress: DailyProgress | null;
	currentGoals: ProgressGoals | null;
	progressStats: ProgressStats | null;
	currentStreak: number;
	chartData: unknown[];
}
