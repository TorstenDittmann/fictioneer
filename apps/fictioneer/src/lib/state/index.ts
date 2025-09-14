/**
 * State coordination and exports
 * This file manages the coordination between different state classes
 * to avoid circular dependencies and ensure proper synchronization
 */

import { projects } from './projects.svelte.js';
import { progress_tracker } from './progress.svelte.js';

// Set up the coordination between projects and progress tracker
progress_tracker.setProjectsReference(projects);
projects.setProgressTrackerReference(progress_tracker);

// Export all state instances
export { projects, progress_tracker };

// Export types
export type { Project, Scene, Chapter, Note } from './projects.svelte.js';
