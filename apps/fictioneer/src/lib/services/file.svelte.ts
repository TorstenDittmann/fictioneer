import { save, open } from '@tauri-apps/plugin-dialog';
import { invoke } from '@tauri-apps/api/core';
import type { Project } from './projects.svelte.js';
import { generate_id } from '../utils.js';

interface SerializedScene {
	id: string;
	title: string;
	content: string;
	createdAt: string;
	updatedAt: string;
	wordCount: number;
	characterCount: number;
	order: number;
}

interface SerializedNote {
	id: string;
	title: string;
	description: string;
	createdAt: string;
	updatedAt: string;
	order: number;
	tags?: string[];
}

interface SerializedChapter {
	id: string;
	title: string;
	scenes: SerializedScene[];
	createdAt: string;
	updatedAt: string;
	order: number;
}

interface SerializedProgressGoals {
	dailyWordTarget: number;
	projectWordTarget?: number;
	createdAt: string;
	updatedAt: string;
}

interface SerializedDailyProgress {
	date: string;
	wordsWritten: number;
	goalMet: boolean;
	sessionsCount: number;
	createdAt: string;
	updatedAt: string;
}

interface SerializedProgressStats {
	currentStreak: number;
	longestStreak: number;
	totalDaysActive: number;
	averageDailyWords: number;
	estimatedCompletionDate?: string;
}

interface SerializedProject {
	id: string;
	title: string;
	description: string;
	chapters: SerializedChapter[];
	notes?: SerializedNote[];
	createdAt: string;
	updatedAt: string;
	lastOpenedSceneId?: string;
	// Progress tracking fields
	progressGoals?: SerializedProgressGoals;
	dailyProgress?: SerializedDailyProgress[];
	progressStats?: SerializedProgressStats;
	dailyWordSnapshots?: Record<string, number>;
}

export interface FictioneerFileData {
	version: string;
	createdAt: string;
	updatedAt: string;
	project: SerializedProject;
}

export interface RecentProject {
	path: string;
	title: string;
	lastOpened: string;
}

interface ProjectFileData {
	version: string;
	createdAt: string;
	updatedAt: string;
	project: SerializedProject;
}

class FileService {
	private readonly version = '1.1.0'; // Updated to support progress tracking
	private readonly file_extension = '.fictioneer';
	private current_file_path = $state<string | null>(null);
	private recent_projects = $state<RecentProject[]>([]);
	private readonly max_recent_projects = 10;
	private auto_save_timeout: ReturnType<typeof setTimeout> | null = null;
	private readonly auto_save_delay = 3000; // 3 seconds
	private last_save_time = 0;
	private readonly save_throttle_interval = 5000; // 5 seconds
	private pending_save_timeout: ReturnType<typeof setTimeout> | null = null;
	private current_project_ref: Project | null = null;

	constructor() {
		this.load_recent_projects();
	}

	/**
	 * Create a new project file
	 */
	async new_project(
		title: string = 'Untitled Project',
		description: string = '',
		file_path?: string
	): Promise<Project | null> {
		try {
			const now = new Date();
			const project_id = generate_id('project');
			const chapter_id = generate_id('chapter');
			const scene_id = generate_id('scene');

			const project: Project = {
				id: project_id,
				title,
				description,
				createdAt: now,
				updatedAt: now,
				chapters: [
					{
						id: chapter_id,
						title: 'Chapter 1',
						createdAt: now,
						updatedAt: now,
						order: 0,
						scenes: [
							{
								id: scene_id,
								title: 'Scene 1',
								content: '',
								createdAt: now,
								updatedAt: now,
								wordCount: 0,
								characterCount: 0,
								order: 0
							}
						]
					}
				],
				notes: [],
				lastOpenedSceneId: scene_id
			};

			// Set file path if provided and save immediately
			if (file_path) {
				this.current_file_path = file_path;
				await this.write_project_to_path(project, file_path);
				this.add_to_recent_projects(file_path, title);
			} else {
				this.current_file_path = null;
			}

			return project;
		} catch (error) {
			console.error('Failed to create new project:', error);
			return null;
		}
	}

	/**
	 * Open an existing .fictioneer file
	 */
	async open_project(): Promise<Project | null> {
		try {
			const file_path = await open({
				multiple: false,
				filters: [
					{
						name: 'Fictioneer Project Files',
						extensions: ['fictioneer']
					}
				]
			});

			if (!file_path || Array.isArray(file_path)) {
				return null; // User cancelled
			}

			return await this.load_project_from_path(file_path);
		} catch (error) {
			console.error('Failed to open project:', error);
			return null;
		}
	}

	/**
	 * Load project from a specific file path
	 */
	async load_project_from_path(file_path: string): Promise<Project | null> {
		try {
			const file_content = await invoke<string>('load_project_file', { path: file_path });
			const file_data: FictioneerFileData = JSON.parse(file_content);

			// Validate file format
			if (!this.validate_fictioneer_file(file_data)) {
				throw new Error('Invalid .fictioneer file format');
			}

			// Check version compatibility
			if (!this.is_version_compatible(file_data.version)) {
				throw new Error(`Unsupported file version: ${file_data.version}`);
			}

			// Set current file
			this.current_file_path = file_path;

			// Add to recent projects
			this.add_to_recent_projects(file_path, file_data.project.title);

			return this.deserialize_project(file_data.project);
		} catch (error) {
			console.error('Failed to load project from path:', error);
			return null;
		}
	}

	/**
	 * Automatically save the current project
	 */
	async save_project(project: Project): Promise<boolean> {
		if (!this.current_file_path) {
			// No current file path, cannot auto-save
			console.warn('No file path set for auto-save');
			return false;
		}

		// Keep reference to current project for potential force save on close
		this.current_project_ref = project;

		try {
			await this.write_project_to_path(project, this.current_file_path);
			return true;
		} catch (error) {
			console.error('Failed to save project:', error);
			return false;
		}
	}

	/**
	 * Save the project to a new location (Save As)
	 */
	async save_project_as(project: Project): Promise<boolean> {
		try {
			const suggested_filename = this.sanitize_filename(project.title) + this.file_extension;

			const file_path = await save({
				defaultPath: suggested_filename,
				filters: [
					{
						name: 'Fictioneer Project Files',
						extensions: ['fictioneer']
					}
				]
			});

			if (!file_path) {
				return false; // User cancelled
			}

			await this.write_project_to_path(project, file_path);

			// Update current file path
			this.current_file_path = file_path;
			this.add_to_recent_projects(file_path, project.title);

			return true;
		} catch (error) {
			console.error('Failed to save project as:', error);
			return false;
		}
	}

	/**
	 * Write project data to a specific file path with throttling
	 */
	private async write_project_to_path(project: Project, file_path: string): Promise<void> {
		const now = Date.now();
		const time_since_last_save = now - this.last_save_time;

		if (time_since_last_save >= this.save_throttle_interval) {
			// Enough time has passed, save immediately
			await this.perform_save(project, file_path);
			this.last_save_time = now;
		} else {
			// Need to throttle, schedule save for later
			const delay = this.save_throttle_interval - time_since_last_save;

			// Clear any existing pending save
			if (this.pending_save_timeout) {
				clearTimeout(this.pending_save_timeout);
			}

			this.pending_save_timeout = setTimeout(async () => {
				await this.perform_save(project, file_path);
				this.last_save_time = Date.now();
				this.pending_save_timeout = null;
			}, delay);
		}
	}

	/**
	 * Perform the actual save operation
	 */
	private async perform_save(project: Project, file_path: string): Promise<void> {
		const file_data: FictioneerFileData = {
			version: this.version,
			createdAt: project.createdAt.toISOString(),
			updatedAt: new Date().toISOString(),
			project: this.serialize_project(project)
		};

		const file_content = JSON.stringify(file_data, null, 2);
		await invoke<void>('save_project_file', { path: file_path, contents: file_content });
	}

	/**
	 * Mark the project as modified and schedule auto-save
	 */
	mark_as_modified(): void {
		this.schedule_auto_save();
	}

	/**
	 * Schedule auto-save
	 */
	private schedule_auto_save(): void {
		if (this.auto_save_timeout) {
			clearTimeout(this.auto_save_timeout);
		}

		this.auto_save_timeout = setTimeout(() => {
			if (this.current_file_path) {
				// Auto-save will be triggered by the projects service
				this.auto_save_timeout = null;
			}
		}, this.auto_save_delay);
	}

	/**
	 * Get auto-save timeout (for external triggering)
	 */
	get needs_auto_save(): boolean {
		return this.auto_save_timeout !== null;
	}

	/**
	 * Clear auto-save timeout
	 */
	clear_auto_save(): void {
		if (this.auto_save_timeout) {
			clearTimeout(this.auto_save_timeout);
			this.auto_save_timeout = null;
		}
		if (this.pending_save_timeout) {
			clearTimeout(this.pending_save_timeout);
			this.pending_save_timeout = null;
		}
	}

	/**
	 * Get the current file path
	 */
	get current_file(): string | null {
		return this.current_file_path;
	}

	/**
	 * Get the current file name
	 */
	get current_file_name(): string | null {
		if (!this.current_file_path) return null;
		return this.current_file_path.split('/').pop() || null;
	}

	/**
	 * Check if there are unsaved changes
	 */
	get has_changes(): boolean {
		return this.auto_save_timeout !== null;
	}

	/**
	 * Get display title for the application (includes file status)
	 */
	get_display_title(project_title: string): string {
		const file_name = this.current_file_name || 'Untitled';
		return `${file_name} - ${project_title}`;
	}

	/**
	 * Trigger auto-save if needed
	 */
	async trigger_auto_save_if_needed(project: Project): Promise<void> {
		// Keep reference to current project for potential force save on close
		this.current_project_ref = project;

		if (this.needs_auto_save && this.current_file_path) {
			try {
				await this.write_project_to_path(project, this.current_file_path);
				this.clear_auto_save();
			} catch (error) {
				console.error('Auto-save failed:', error);
			}
		}
	}

	/**
	 * Close the current project (check for unsaved changes)
	 */
	async close_project(): Promise<boolean> {
		// Force save any pending changes before closing
		if (this.current_project_ref && this.current_file_path) {
			try {
				await this.perform_save(this.current_project_ref, this.current_file_path);
			} catch {
				// Ignore save errors on close
			}
		}

		this.clear_auto_save();
		this.current_file_path = null;
		this.current_project_ref = null;
		return true;
	}

	/**
	 * Force immediate save, bypassing throttle (for manual saves)
	 */
	async force_save_project(project: Project): Promise<boolean> {
		if (!this.current_file_path) {
			return false;
		}

		try {
			// Clear any pending throttled saves
			if (this.pending_save_timeout) {
				clearTimeout(this.pending_save_timeout);
				this.pending_save_timeout = null;
			}

			await this.perform_save(project, this.current_file_path);
			this.last_save_time = Date.now();
			return true;
		} catch {
			return false;
		}
	}

	/**
	 * Flush any pending throttled saves immediately
	 */
	async flush_pending_saves(): Promise<void> {
		if (this.pending_save_timeout && this.current_project_ref && this.current_file_path) {
			clearTimeout(this.pending_save_timeout);
			this.pending_save_timeout = null;

			try {
				await this.perform_save(this.current_project_ref, this.current_file_path);
				this.last_save_time = Date.now();
			} catch {
				// Ignore flush errors
			}
		}
	}

	/**
	 * Serialize a project for storage
	 */
	private serialize_project(project: Project): SerializedProject {
		const serialized: SerializedProject = {
			id: project.id,
			title: project.title,
			description: project.description,
			createdAt: project.createdAt.toISOString(),
			updatedAt: project.updatedAt.toISOString(),
			lastOpenedSceneId: project.lastOpenedSceneId,
			chapters: project.chapters.map((chapter) => ({
				...chapter,
				createdAt: chapter.createdAt.toISOString(),
				updatedAt: chapter.updatedAt.toISOString(),
				scenes: chapter.scenes.map((scene) => ({
					...scene,
					createdAt: scene.createdAt.toISOString(),
					updatedAt: scene.updatedAt.toISOString()
				}))
			})),
			notes: (project.notes || []).map((note) => ({
				...note,
				createdAt: note.createdAt.toISOString(),
				updatedAt: note.updatedAt.toISOString()
			}))
		};

		// Serialize progress tracking data
		if (project.progressGoals) {
			serialized.progressGoals = {
				dailyWordTarget: project.progressGoals.dailyWordTarget,
				projectWordTarget: project.progressGoals.projectWordTarget,
				createdAt: project.progressGoals.createdAt.toISOString(),
				updatedAt: project.progressGoals.updatedAt.toISOString()
			};
		}

		if (project.dailyProgress) {
			serialized.dailyProgress = project.dailyProgress.map((progress) => ({
				date: progress.date,
				wordsWritten: progress.wordsWritten,
				goalMet: progress.goalMet,
				sessionsCount: progress.sessionsCount,
				createdAt: progress.createdAt.toISOString(),
				updatedAt: progress.updatedAt.toISOString()
			}));
		}

		if (project.progressStats) {
			serialized.progressStats = {
				currentStreak: project.progressStats.currentStreak,
				longestStreak: project.progressStats.longestStreak,
				totalDaysActive: project.progressStats.totalDaysActive,
				averageDailyWords: project.progressStats.averageDailyWords,
				estimatedCompletionDate: project.progressStats.estimatedCompletionDate?.toISOString()
			};
		}

		// Serialize daily word snapshots
		if (project.dailyWordSnapshots) {
			serialized.dailyWordSnapshots = { ...project.dailyWordSnapshots };
		}

		return serialized;
	}

	/**
	 * Deserialize a project from storage
	 */
	private deserialize_project(project: SerializedProject): Project {
		const deserialized: Project = {
			id: project.id,
			title: project.title,
			description: project.description,
			createdAt: new Date(project.createdAt),
			updatedAt: new Date(project.updatedAt),
			lastOpenedSceneId: project.lastOpenedSceneId,
			chapters: project.chapters.map((chapter: SerializedChapter) => ({
				...chapter,
				createdAt: new Date(chapter.createdAt),
				updatedAt: new Date(chapter.updatedAt),
				scenes: chapter.scenes.map((scene: SerializedScene) => ({
					...scene,
					createdAt: new Date(scene.createdAt),
					updatedAt: new Date(scene.updatedAt)
				}))
			})),
			notes:
				(project.notes || []).map((note: SerializedNote) => ({
					...note,
					createdAt: new Date(note.createdAt),
					updatedAt: new Date(note.updatedAt),
					tags: note.tags || []
				})) || []
		};

		// Deserialize progress tracking data
		if (project.progressGoals) {
			deserialized.progressGoals = {
				dailyWordTarget: project.progressGoals.dailyWordTarget,
				projectWordTarget: project.progressGoals.projectWordTarget,
				createdAt: new Date(project.progressGoals.createdAt),
				updatedAt: new Date(project.progressGoals.updatedAt)
			};
		}

		if (project.dailyProgress) {
			deserialized.dailyProgress = project.dailyProgress.map((progress) => ({
				date: progress.date,
				wordsWritten: progress.wordsWritten,
				goalMet: progress.goalMet,
				sessionsCount: progress.sessionsCount,
				createdAt: new Date(progress.createdAt),
				updatedAt: new Date(progress.updatedAt)
			}));
		}

		if (project.progressStats) {
			deserialized.progressStats = {
				currentStreak: project.progressStats.currentStreak,
				longestStreak: project.progressStats.longestStreak,
				totalDaysActive: project.progressStats.totalDaysActive,
				averageDailyWords: project.progressStats.averageDailyWords,
				estimatedCompletionDate: project.progressStats.estimatedCompletionDate
					? new Date(project.progressStats.estimatedCompletionDate)
					: undefined
			};
		}

		// Deserialize daily word snapshots
		if (project.dailyWordSnapshots) {
			deserialized.dailyWordSnapshots = { ...project.dailyWordSnapshots };
		}

		return deserialized;
	}

	/**
	 * Validate the structure of a .fictioneer file
	 */
	private validate_fictioneer_file(data: unknown): data is ProjectFileData {
		const obj = data as Record<string, unknown>;
		const project = obj.project as Record<string, unknown>;

		// Basic structure validation
		const basic_valid =
			!!obj &&
			typeof obj.version === 'string' &&
			typeof obj.createdAt === 'string' &&
			typeof obj.updatedAt === 'string' &&
			!!obj.project &&
			typeof project.id === 'string' &&
			typeof project.title === 'string' &&
			Array.isArray(project.chapters);

		if (!basic_valid) {
			return false;
		}

		// Optional progress tracking validation (for backward compatibility)
		if (project.progressGoals) {
			const goals = project.progressGoals as Record<string, unknown>;
			if (
				typeof goals.dailyWordTarget !== 'number' ||
				typeof goals.createdAt !== 'string' ||
				typeof goals.updatedAt !== 'string'
			) {
				return false;
			}
		}

		if (project.dailyProgress) {
			if (!Array.isArray(project.dailyProgress)) {
				return false;
			}
			// Validate first few entries to ensure structure
			for (let i = 0; i < Math.min(3, project.dailyProgress.length); i++) {
				const progress = project.dailyProgress[i] as Record<string, unknown>;
				if (
					typeof progress.date !== 'string' ||
					typeof progress.wordsWritten !== 'number' ||
					typeof progress.goalMet !== 'boolean' ||
					typeof progress.sessionsCount !== 'number'
				) {
					return false;
				}
			}
		}

		return true;
	}

	/**
	 * Check if the file version is compatible
	 */
	private is_version_compatible(file_version: string): boolean {
		const [major] = file_version.split('.').map(Number);
		const [current_major] = this.version.split('.').map(Number);

		// Same major version is compatible
		if (major === current_major) {
			return true;
		}

		// For now, we only support version 1.x.x
		return major === 1 && current_major === 1;
	}

	/**
	 * Sanitize filename for cross-platform compatibility
	 */
	private sanitize_filename(filename: string): string {
		return filename
			.replace(/[<>:"/\\|?*]/g, '_')
			.replace(/\s+/g, '_')
			.trim()
			.substring(0, 50);
	}

	/**
	 * Load recent projects from localStorage
	 */
	private load_recent_projects(): void {
		if (typeof localStorage === 'undefined') return;

		try {
			const stored = localStorage.getItem('fictioneer_recent_projects');
			if (stored) {
				this.recent_projects = JSON.parse(stored);
			}
		} catch (error) {
			console.error('Failed to load recent projects:', error);
			this.recent_projects = [];
		}
	}

	/**
	 * Save recent projects to localStorage
	 */
	private save_recent_projects(): void {
		if (typeof localStorage === 'undefined') return;

		try {
			localStorage.setItem('fictioneer_recent_projects', JSON.stringify(this.recent_projects));
		} catch (error) {
			console.error('Failed to save recent projects:', error);
		}
	}

	/**
	 * Add a project to recent projects list
	 */
	private add_to_recent_projects(path: string, title: string): void {
		// Remove existing entry if it exists
		this.recent_projects = this.recent_projects.filter((p) => p.path !== path);

		// Add to beginning of list
		this.recent_projects.unshift({
			path,
			title,
			lastOpened: new Date().toISOString()
		});

		// Limit to max entries
		if (this.recent_projects.length > this.max_recent_projects) {
			this.recent_projects = this.recent_projects.slice(0, this.max_recent_projects);
		}

		this.save_recent_projects();
	}

	/**
	 * Get recent projects
	 */
	get_recent_projects(): RecentProject[] {
		return this.recent_projects;
	}

	/**
	 * Clear recent projects
	 */
	clear_recent_projects(): void {
		this.recent_projects = [];
		this.save_recent_projects();
	}

	/**
	 * Remove a project from recent list
	 */
	remove_from_recent_projects(path: string): void {
		this.recent_projects = this.recent_projects.filter((p) => p.path !== path);
		this.save_recent_projects();
	}

	/**
	 * Open a project from a specific file path
	 */
	async open_project_from_path(file_path: string): Promise<Project | null> {
		try {
			return await this.load_project_from_path(file_path);
		} catch (error) {
			console.error('Failed to open project from path:', error);
			return null;
		}
	}
}

export const file_service = new FileService();
