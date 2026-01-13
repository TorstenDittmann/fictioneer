/**
 * State coordination and exports
 * This file manages the coordination between different state classes
 * to avoid circular dependencies and ensure proper synchronization
 */

import { projects } from './projects.svelte.js';
import { progress_tracker } from './progress.svelte.js';
import { analysis_state } from './analysis.svelte.js';

// Set up the coordination between projects and progress tracker
progress_tracker.setProjectsReference(projects);
projects.setProgressTrackerReference(progress_tracker);

// Export all state instances
export { projects, progress_tracker, analysis_state };

// Export types
export type { Project, Scene, Chapter, Note } from './projects.svelte.js';

// Export analysis helpers
export {
	get_highlight_color,
	get_highlight_label,
	get_highlight_icon,
	ALL_HIGHLIGHT_TYPES
} from './analysis.svelte.js';
