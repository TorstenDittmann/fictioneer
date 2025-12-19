import type { ProgressGoals, DailyProgress, ProgressStats } from '../types/progress.js';
import type { ProgressTrackerReference, ProjectsState } from '../types/state.js';

export interface Scene {
	id: string;
	title: string;
	content: string;
	createdAt: Date;
	updatedAt: Date;
	wordCount: number;
	characterCount: number;
	order: number;
}

export interface Chapter {
	id: string;
	title: string;
	createdAt: Date;
	updatedAt: Date;
	scenes: Scene[];
	order: number;
}

export interface Note {
	id: string;
	title: string;
	description: string;
	createdAt: Date;
	updatedAt: Date;
	order: number;
}

export interface Project {
	id: string;
	title: string;
	description: string;
	createdAt: Date;
	updatedAt: Date;
	chapters: Chapter[];
	notes: Note[];
	lastOpenedSceneId?: string;
	// Progress tracking fields
	progressGoals?: ProgressGoals;
	dailyProgress?: DailyProgress[];
	progressStats?: ProgressStats;
	dailyWordSnapshots?: Record<string, number>;
}

import { projects_service } from '$lib/services/projects.svelte.js';
import { progress_service } from '$lib/services/progress.svelte.js';

class Projects implements ProjectsState {
	private trigger = $state(0);
	private active_chapter_id = $state<string | null>(null);
	private active_scene_id = $state<string | null>(null);
	private expanded_chapters = $state<string[]>([]);
	private _progressTracker: ProgressTrackerReference | null = null; // Will be injected to avoid circular dependency

	constructor() {
		this.initializeExpandedChapters();
	}

	// Set progress tracker reference for bidirectional communication
	setProgressTrackerReference(progressTrackerRef: ProgressTrackerReference) {
		this._progressTracker = progressTrackerRef;
	}

	private initializeExpandedChapters() {
		// Auto-expand first chapter if no chapters are expanded
		const project = this.project;
		if (project && project.chapters.length > 0 && this.expanded_chapters.length === 0) {
			this.expanded_chapters = [project.chapters[0].id];
		}
	}

	// Trigger reactivity by updating a counter
	private trigger_update() {
		this.trigger = Date.now();
		// Notify progress tracker of state changes
		this._progressTracker?.syncWithProjectsState?.();
	}

	// Public method to trigger updates (for progress tracker coordination)
	public triggerUpdate() {
		this.trigger_update();
	}

	// Getters
	get project(): Project | null {
		// Trigger reactivity
		void this.trigger;
		return projects_service.get_current_project();
	}

	get activeChapter(): Chapter | null {
		if (!this.active_chapter_id) return null;
		return projects_service.get_chapter(this.active_chapter_id);
	}

	get activeScene(): Scene | null {
		const chapter = this.activeChapter;
		if (!chapter || !this.active_scene_id) return null;
		return chapter.scenes.find((scene) => scene.id === this.active_scene_id) || null;
	}

	get activeChapterId(): string | null {
		return this.active_chapter_id;
	}

	get activeSceneId(): string | null {
		return this.active_scene_id;
	}

	get expandedChapters(): string[] {
		return this.expanded_chapters;
	}

	get fileStatus() {
		return projects_service.get_file_status();
	}

	get hasProject(): boolean {
		return projects_service.has_project();
	}

	get recentProjects() {
		return projects_service.get_recent_projects();
	}

	get recentScenes() {
		// Trigger reactivity
		void this.trigger;
		return projects_service.get_recent_scenes();
	}

	// File operations
	async createNewProject(title: string, description: string, filePath: string): Promise<boolean> {
		try {
			const project = await projects_service.new_project(title, description, filePath);
			if (!project) return false;

			this.trigger_update();
			this.initializeExpandedChapters();

			// Set active chapter and scene to first available
			if (project.chapters.length > 0) {
				this.active_chapter_id = project.chapters[0].id;
				const first_scene = project.chapters[0].scenes[0];
				if (first_scene) {
					this.active_scene_id = first_scene.id;
				}
			}

			// Initialize progress tracking for new project
			this.initializeProgressTracking();

			return true;
		} catch (error) {
			console.error('Failed to create new project:', error);
			return false;
		}
	}

	async newProject(title: string = 'Untitled Project', description: string = ''): Promise<boolean> {
		try {
			const project = await projects_service.new_project(title, description);
			if (!project) return false;

			this.trigger_update();
			this.initializeExpandedChapters();

			// Set active chapter and scene to first available
			if (project.chapters.length > 0) {
				this.active_chapter_id = project.chapters[0].id;
				const first_scene = project.chapters[0].scenes[0];
				if (first_scene) {
					this.active_scene_id = first_scene.id;
				}
			}

			// Initialize progress tracking for new project
			this.initializeProgressTracking();

			return true;
		} catch (error) {
			console.error('Failed to create new project:', error);
			return false;
		}
	}

	async openProject(): Promise<boolean> {
		try {
			const project = await projects_service.open_project();
			if (!project) return false;

			this.trigger_update();
			this.initializeExpandedChapters();

			// Set active chapter and scene to last opened or first available
			if (project.lastOpenedSceneId) {
				// Find the scene and set the chapter/scene accordingly
				for (const chapter of project.chapters) {
					const scene = chapter.scenes.find((s) => s.id === project.lastOpenedSceneId);
					if (scene) {
						this.active_chapter_id = chapter.id;
						this.active_scene_id = scene.id;
						this.autoExpandActiveChapter();
						return true;
					}
				}
			}

			// Default to first chapter and scene
			const first_chapter = project.chapters[0];
			if (first_chapter) {
				this.active_chapter_id = first_chapter.id;
				const first_scene = first_chapter.scenes[0];
				if (first_scene) {
					this.active_scene_id = first_scene.id;
				}
			}

			this.autoExpandActiveChapter();

			// Update progress tracking when opening project
			this.updateProgressTracking();

			return true;
		} catch (error) {
			console.error('Failed to open project:', error);
			return false;
		}
	}

	async openRecentProject(filePath: string): Promise<boolean> {
		try {
			const project = await projects_service.open_project_from_path(filePath);
			if (!project) return false;

			this.trigger_update();
			this.initializeExpandedChapters();

			// Set active chapter and scene to last opened or first available
			if (project.lastOpenedSceneId) {
				// Find the scene and set the chapter/scene accordingly
				for (const chapter of project.chapters) {
					const scene = chapter.scenes.find((s) => s.id === project.lastOpenedSceneId);
					if (scene) {
						this.active_chapter_id = chapter.id;
						this.active_scene_id = scene.id;
						this.autoExpandActiveChapter();
						return true;
					}
				}
			}

			// Default to first chapter and scene
			const first_chapter = project.chapters[0];
			if (first_chapter) {
				this.active_chapter_id = first_chapter.id;
				const first_scene = first_chapter.scenes[0];
				if (first_scene) {
					this.active_scene_id = first_scene.id;
				}
			}

			this.autoExpandActiveChapter();

			// Update progress tracking when opening project
			this.updateProgressTracking();

			return true;
		} catch (error) {
			console.error('Failed to open recent project:', error);
			return false;
		}
	}

	async closeProject(): Promise<boolean> {
		try {
			const can_close = await projects_service.close_project();
			if (can_close) {
				this.active_chapter_id = null;
				this.active_scene_id = null;
				this.expanded_chapters = [];
				this.trigger_update();
			}
			return can_close;
		} catch (error) {
			console.error('Failed to close project:', error);
			return false;
		}
	}

	// Project methods
	updateProject(updates: Partial<Omit<Project, 'id' | 'createdAt' | 'chapters'>>) {
		const success = projects_service.update_project(updates);
		if (success) {
			this.trigger_update();
		} else {
			throw new Error('Failed to update project');
		}
	}

	// Chapter methods
	createChapter(title: string = 'Untitled Chapter'): string {
		const chapter_id = projects_service.create_chapter(title);
		if (!chapter_id) {
			throw new Error('Failed to create chapter');
		}
		this.trigger_update();
		this.active_chapter_id = chapter_id;
		return chapter_id;
	}

	updateChapter(
		chapter_id: string,
		updates: Partial<Omit<Chapter, 'id' | 'createdAt' | 'scenes'>>
	) {
		const success = projects_service.update_chapter(chapter_id, updates);
		if (!success) {
			throw new Error(`Failed to update chapter ${chapter_id}`);
		}
		this.trigger_update();
	}

	deleteChapter(chapter_id: string) {
		const success = projects_service.delete_chapter(chapter_id);
		if (!success) {
			throw new Error(`Failed to delete chapter ${chapter_id}`);
		}
		this.trigger_update();

		// If we deleted the active chapter, switch to the first available one
		if (this.active_chapter_id === chapter_id) {
			const project = this.project;
			if (project) {
				const first_chapter = project.chapters[0];
				if (first_chapter) {
					this.active_chapter_id = first_chapter.id;
					const first_scene = first_chapter.scenes[0];
					if (first_scene) {
						this.active_scene_id = first_scene.id;
					}
				}
			}
		}
	}

	setActiveChapter(chapter_id: string) {
		const project = this.project;
		if (!project) {
			throw new Error('No project loaded');
		}

		const chapter = project.chapters.find((c) => c.id === chapter_id);
		if (!chapter) {
			throw new Error(`Chapter ${chapter_id} not found in project`);
		}
		this.active_chapter_id = chapter_id;
		// Set to first scene in chapter
		const first_scene = chapter.scenes[0];
		if (first_scene) {
			this.active_scene_id = first_scene.id;
		}
	}

	// Scene methods
	createScene(chapter_id: string, title: string = 'Untitled Scene'): string {
		const scene_id = projects_service.create_scene(chapter_id, title);
		if (!scene_id) {
			throw new Error(`Failed to create scene in chapter ${chapter_id}`);
		}
		this.trigger_update();
		this.active_scene_id = scene_id;
		return scene_id;
	}

	updateScene(
		chapter_id: string,
		scene_id: string,
		updates: Partial<Omit<Scene, 'id' | 'createdAt'>>
	) {
		const success = projects_service.update_scene(chapter_id, scene_id, updates);
		if (!success) {
			throw new Error(`Failed to update scene ${scene_id} in chapter ${chapter_id}`);
		}

		// Trigger progress update when scene content changes
		this.updateProgressTracking();

		this.trigger_update();
	}

	deleteScene(chapter_id: string, scene_id: string) {
		const success = projects_service.delete_scene(chapter_id, scene_id);
		if (!success) {
			throw new Error(`Failed to delete scene ${scene_id} in chapter ${chapter_id}`);
		}
		this.trigger_update();

		// If we deleted the active scene, switch to the first available one
		if (this.active_scene_id === scene_id) {
			const project = this.project;
			if (project) {
				const chapter = project.chapters.find((c) => c.id === chapter_id);
				if (chapter) {
					const first_scene = chapter.scenes[0];
					if (first_scene) {
						this.active_scene_id = first_scene.id;
					}
				}
			}
		}
	}

	setActiveScene(scene_id: string) {
		const project = this.project;
		if (!project) {
			throw new Error('No project loaded');
		}

		// Find the scene and set the chapter/scene accordingly
		for (const chapter of project.chapters) {
			const scene = chapter.scenes.find((s) => s.id === scene_id);
			if (scene) {
				this.active_chapter_id = chapter.id;
				this.active_scene_id = scene_id;
				projects_service.update_last_opened_scene(scene_id);
				this.autoExpandActiveChapter();
				this.trigger_update();
				return;
			}
		}
		throw new Error(`Scene ${scene_id} not found in project`);
	}

	// Chapter expansion state
	toggleChapterExpansion(chapter_id: string) {
		if (this.expanded_chapters.includes(chapter_id)) {
			this.expanded_chapters = this.expanded_chapters.filter((id) => id !== chapter_id);
		} else {
			this.expanded_chapters = [...this.expanded_chapters, chapter_id];
		}
	}

	isChapterExpanded(chapter_id: string): boolean {
		return this.expanded_chapters.includes(chapter_id);
	}

	expandChapter(chapter_id: string) {
		if (!this.expanded_chapters.includes(chapter_id)) {
			this.expanded_chapters = [...this.expanded_chapters, chapter_id];
		}
	}

	autoExpandActiveChapter() {
		// Auto-expand chapter with active scene
		if (this.active_chapter_id && !this.expanded_chapters.includes(this.active_chapter_id)) {
			this.expanded_chapters = [...this.expanded_chapters, this.active_chapter_id];
		}
	}

	// Note methods
	createNote(title: string = 'Untitled Note', description: string = ''): string {
		const note_id = projects_service.create_note(title, description);
		if (!note_id) {
			throw new Error('Failed to create note');
		}
		this.trigger_update();
		return note_id;
	}

	updateNote(note_id: string, updates: Partial<Omit<Note, 'id' | 'createdAt'>>) {
		const success = projects_service.update_note(note_id, updates);
		if (!success) {
			throw new Error(`Failed to update note ${note_id}`);
		}
		this.trigger_update();
	}

	deleteNote(note_id: string) {
		const success = projects_service.delete_note(note_id);
		if (!success) {
			throw new Error(`Failed to delete note ${note_id}`);
		}
		this.trigger_update();
	}

	get notes(): Note[] {
		// Trigger reactivity
		void this.trigger;
		return projects_service.get_notes();
	}

	get recentNotes(): Note[] {
		// Trigger reactivity
		void this.trigger;
		return projects_service.get_recent_notes();
	}

	// Get project statistics
	getProjectStats() {
		return projects_service.get_project_stats();
	}

	// Get project URLs
	getProjectUrls() {
		const urls = projects_service.get_project_urls();
		if (!urls) {
			throw new Error('Failed to get URLs for project');
		}
		return urls;
	}

	// Progress tracking integration methods
	updateProgressTracking() {
		const project = this.project;
		if (!project) return;

		// Calculate current total word count from all scenes
		let totalWords = 0;
		for (const chapter of project.chapters) {
			for (const scene of chapter.scenes) {
				totalWords += scene.wordCount;
			}
		}

		// Get today's date
		const today = new Date().toISOString().split('T')[0];

		// Initialize snapshots object if it doesn't exist
		if (!project.dailyWordSnapshots) {
			project.dailyWordSnapshots = {};
		}

		// If we don't have a snapshot for today, set the current total as the starting point
		if (!(today in project.dailyWordSnapshots)) {
			project.dailyWordSnapshots[today] = totalWords;
		}

		// Calculate words written today as the delta from the starting snapshot
		const startingWords = project.dailyWordSnapshots[today];
		const wordsWrittenToday = Math.max(0, totalWords - startingWords);

		// Update daily progress with words written today (not total)
		progress_service.updateDailyProgress(project, today, wordsWrittenToday);

		// Trigger reactivity update
		this.trigger_update();
	}

	// Progress goal management
	setDailyProgressGoal(target: number): boolean {
		const project = this.project;
		if (!project) return false;

		const success = progress_service.setDailyGoal(project, target);
		if (success) {
			this.trigger_update();
		}
		return success;
	}

	setProjectProgressGoal(target: number): boolean {
		const project = this.project;
		if (!project) return false;

		const success = progress_service.setProjectGoal(project, target);
		if (success) {
			this.trigger_update();
		}
		return success;
	}

	// Progress data getters
	get progressGoals() {
		const project = this.project;
		return project?.progressGoals || null;
	}

	get dailyProgress() {
		const project = this.project;
		return project?.dailyProgress || [];
	}

	get progressStats() {
		const project = this.project;
		return project?.progressStats || null;
	}

	get todaysProgress() {
		const project = this.project;
		if (!project) return null;
		return progress_service.getTodaysProgress(project);
	}

	// Initialize progress tracking for new projects
	initializeProgressTracking(dailyGoal: number = 500, projectGoal?: number) {
		const project = this.project;
		if (!project) return false;

		// Set up initial goals
		const success = progress_service.setDailyGoal(project, dailyGoal);
		if (!success) return false;

		if (projectGoal) {
			const projectSuccess = progress_service.setProjectGoal(project, projectGoal);
			if (!projectSuccess) return false;
		}

		// Initialize empty progress arrays if they don't exist
		if (!project.dailyProgress) {
			project.dailyProgress = [];
		}

		// Calculate initial stats
		project.progressStats = progress_service.calculateProgressStats(project);

		this.trigger_update();
		return true;
	}

	// Increment session count (called when user starts writing)
	incrementWritingSession() {
		const project = this.project;
		if (!project) return false;

		const success = progress_service.incrementSessionCount(project);
		if (success) {
			this.trigger_update();
		}
		return success;
	}
}

export const projects = new Projects();

// Set up bidirectional references between projects and progress tracker
// This is done after both instances are created to avoid circular dependency issues
import { progress_tracker } from './progress.svelte.js';

// Set up the bidirectional references
projects.setProgressTrackerReference(progress_tracker);
progress_tracker.setProjectsReference(projects);
