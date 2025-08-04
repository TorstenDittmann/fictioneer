import { writeTextFile, readTextFile } from '@tauri-apps/plugin-fs';
import { save, open } from '@tauri-apps/plugin-dialog';
import type { Project } from './projects.svelte.js';

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

interface SerializedChapter {
	id: string;
	title: string;
	scenes: SerializedScene[];
	createdAt: string;
	updatedAt: string;
	order: number;
}

interface SerializedProject {
	id: string;
	title: string;
	description: string;
	chapters: SerializedChapter[];
	createdAt: string;
	updatedAt: string;
}

export interface OmniaFileData {
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

class FileService {
	private readonly version = '1.0.0';
	private readonly file_extension = '.omnia';
	private current_file_path = $state<string | null>(null);
	private recent_projects = $state<RecentProject[]>([]);
	private readonly max_recent_projects = 10;
	private auto_save_timeout: ReturnType<typeof setTimeout> | null = null;
	private readonly auto_save_delay = 3000; // 3 seconds

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
			const project_id = this.generate_id('project');
			const chapter_id = this.generate_id('chapter');
			const scene_id = this.generate_id('scene');

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
	 * Open an existing .omnia file
	 */
	async open_project(): Promise<Project | null> {
		try {
			const file_path = await open({
				multiple: false,
				filters: [
					{
						name: 'Omnia Project Files',
						extensions: ['omnia']
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
			const file_content = await readTextFile(file_path);
			const file_data: OmniaFileData = JSON.parse(file_content);

			// Validate file format
			if (!this.validate_omnia_file(file_data)) {
				throw new Error('Invalid .omnia file format');
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
						name: 'Omnia Project Files',
						extensions: ['omnia']
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
	 * Write project data to a specific file path
	 */
	private async write_project_to_path(project: Project, file_path: string): Promise<void> {
		const file_data: OmniaFileData = {
			version: this.version,
			createdAt: project.createdAt.toISOString(),
			updatedAt: new Date().toISOString(),
			project: this.serialize_project(project)
		};

		const file_content = JSON.stringify(file_data, null, 2);
		await writeTextFile(file_path, file_content);
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
		this.clear_auto_save();
		this.current_file_path = null;
		return true;
	}

	/**
	 * Serialize a project for storage
	 */
	private serialize_project(project: Project): SerializedProject {
		return {
			...project,
			createdAt: project.createdAt.toISOString(),
			updatedAt: project.updatedAt.toISOString(),
			chapters: project.chapters.map((chapter) => ({
				...chapter,
				createdAt: chapter.createdAt.toISOString(),
				updatedAt: chapter.updatedAt.toISOString(),
				scenes: chapter.scenes.map((scene) => ({
					...scene,
					createdAt: scene.createdAt.toISOString(),
					updatedAt: scene.updatedAt.toISOString()
				}))
			}))
		};
	}

	/**
	 * Deserialize a project from storage
	 */
	private deserialize_project(project: SerializedProject): Project {
		return {
			...project,
			createdAt: new Date(project.createdAt),
			updatedAt: new Date(project.updatedAt),
			chapters: project.chapters.map((chapter: SerializedChapter) => ({
				...chapter,
				createdAt: new Date(chapter.createdAt),
				updatedAt: new Date(chapter.updatedAt),
				scenes: chapter.scenes.map((scene: SerializedScene) => ({
					...scene,
					createdAt: new Date(scene.createdAt),
					updatedAt: new Date(scene.updatedAt)
				}))
			}))
		};
	}

	/**
	 * Validate the structure of a .omnia file
	 */
	private validate_omnia_file(data: unknown): data is OmniaFileData {
		const obj = data as Record<string, unknown>;
		return (
			!!obj &&
			typeof obj.version === 'string' &&
			typeof obj.createdAt === 'string' &&
			typeof obj.updatedAt === 'string' &&
			!!obj.project &&
			typeof (obj.project as Record<string, unknown>).id === 'string' &&
			typeof (obj.project as Record<string, unknown>).title === 'string' &&
			Array.isArray((obj.project as Record<string, unknown>).chapters)
		);
	}

	/**
	 * Check if the file version is compatible
	 */
	private is_version_compatible(file_version: string): boolean {
		const major_version = file_version.split('.')[0];
		const current_major = this.version.split('.')[0];
		return major_version === current_major;
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
	 * Generate unique ID
	 */
	private generate_id(prefix: string): string {
		return `${prefix}-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
	}

	/**
	 * Load recent projects from localStorage
	 */
	private load_recent_projects(): void {
		if (typeof localStorage === 'undefined') return;

		try {
			const stored = localStorage.getItem('omnia_recent_projects');
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
			localStorage.setItem('omnia_recent_projects', JSON.stringify(this.recent_projects));
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
	 * Helper method to read project data from a file path
	 */
	private async read_project_data_from_path(file_path: string): Promise<string> {
		return await readTextFile(file_path);
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
