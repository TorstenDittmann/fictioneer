import { file_service } from './file.svelte.js';

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
}

class ProjectsService {
	private current_project = $state<Project | null>(null);

	/**
	 * Create a new project
	 */
	async new_project(
		title: string = 'Untitled Project',
		description: string = '',
		file_path?: string
	): Promise<Project | null> {
		const project = await file_service.new_project(title, description, file_path);
		if (project) {
			this.current_project = project;
		}
		return project;
	}

	/**
	 * Open an existing project file
	 */
	async open_project(): Promise<Project | null> {
		const project = await file_service.open_project();
		if (project) {
			this.current_project = project;
		}
		return project;
	}

	/**
	 * Save the current project
	 */
	async save_project(): Promise<boolean> {
		if (!this.current_project) return false;
		return await file_service.save_project(this.current_project);
	}

	/**
	 * Save the current project to a new location
	 */
	async save_project_as(): Promise<boolean> {
		if (!this.current_project) return false;
		return await file_service.save_project_as(this.current_project);
	}

	/**
	 * Close the current project
	 */
	async close_project(): Promise<boolean> {
		const can_close = await file_service.close_project();
		if (can_close) {
			this.current_project = null;
		}
		return can_close;
	}

	/**
	 * Get the current project
	 */
	get_current_project(): Project | null {
		return this.current_project;
	}

	/**
	 * Get a specific chapter by ID
	 */
	get_chapter(chapter_id: string): Chapter | null {
		if (!this.current_project) return null;
		return this.current_project.chapters.find((chapter) => chapter.id === chapter_id) || null;
	}

	/**
	 * Get a specific scene by chapter and scene ID
	 */
	get_scene(chapter_id: string, scene_id: string): Scene | null {
		const chapter = this.get_chapter(chapter_id);
		if (!chapter) return null;
		return chapter.scenes.find((scene) => scene.id === scene_id) || null;
	}

	/**
	 * Update the current project and mark as modified
	 */
	private update_current_project(updater: (project: Project) => void): boolean {
		if (!this.current_project) return false;

		updater(this.current_project);
		this.current_project.updatedAt = new Date();
		file_service.mark_as_modified();

		// Trigger auto-save
		this.trigger_auto_save();

		return true;
	}

	/**
	 * Update project metadata
	 */
	update_project(updates: Partial<Omit<Project, 'id' | 'createdAt' | 'chapters'>>): boolean {
		return this.update_current_project((project) => {
			Object.assign(project, updates);
		});
	}

	/**
	 * Create a new chapter
	 */
	create_chapter(title: string = 'Untitled Chapter'): string | null {
		if (!this.current_project) return null;

		const chapter_id = this.generate_id('chapter');
		const now = new Date();

		const new_chapter: Chapter = {
			id: chapter_id,
			title,
			createdAt: now,
			updatedAt: now,
			scenes: [],
			order: this.current_project.chapters.length
		};

		this.update_current_project((project) => {
			project.chapters.push(new_chapter);
		});

		return chapter_id;
	}

	/**
	 * Update a chapter
	 */
	update_chapter(
		chapter_id: string,
		updates: Partial<Omit<Chapter, 'id' | 'createdAt' | 'scenes'>>
	): boolean {
		return this.update_current_project((project) => {
			const chapter_index = project.chapters.findIndex((chapter) => chapter.id === chapter_id);
			if (chapter_index === -1) return;

			const updated_chapter = {
				...project.chapters[chapter_index],
				...updates,
				updatedAt: new Date()
			};

			project.chapters[chapter_index] = updated_chapter;
		});
	}

	/**
	 * Delete a chapter
	 */
	delete_chapter(chapter_id: string): boolean {
		if (!this.current_project || this.current_project.chapters.length <= 1) {
			return false; // Don't delete the last chapter
		}

		return this.update_current_project((project) => {
			const chapter_index = project.chapters.findIndex((chapter) => chapter.id === chapter_id);
			if (chapter_index === -1) return;

			project.chapters.splice(chapter_index, 1);
		});
	}

	/**
	 * Create a new scene
	 */
	create_scene(chapter_id: string, title: string = 'Untitled Scene'): string | null {
		if (!this.current_project) return null;

		const chapter = this.get_chapter(chapter_id);
		if (!chapter) return null;

		const scene_id = this.generate_id('scene');
		const now = new Date();

		const new_scene: Scene = {
			id: scene_id,
			title,
			content: '',
			createdAt: now,
			updatedAt: now,
			wordCount: 0,
			characterCount: 0,
			order: chapter.scenes.length
		};

		this.update_current_project((project) => {
			const chapter_index = project.chapters.findIndex((c) => c.id === chapter_id);
			if (chapter_index === -1) return;

			project.chapters[chapter_index].scenes.push(new_scene);
			project.chapters[chapter_index].updatedAt = now;
		});

		return scene_id;
	}

	/**
	 * Update a scene
	 */
	update_scene(
		chapter_id: string,
		scene_id: string,
		updates: Partial<Omit<Scene, 'id' | 'createdAt'>>
	): boolean {
		return this.update_current_project((project) => {
			const chapter = project.chapters.find((c) => c.id === chapter_id);
			if (!chapter) return;

			const scene_index = chapter.scenes.findIndex((scene) => scene.id === scene_id);
			if (scene_index === -1) return;

			const updated_scene = {
				...chapter.scenes[scene_index],
				...updates,
				updatedAt: new Date()
			};

			// Calculate word and character count if content is updated
			if (updates.content !== undefined) {
				const text_content = this.strip_html(updates.content);
				updated_scene.wordCount = this.count_words(text_content);
				updated_scene.characterCount = text_content.length;
			}

			chapter.scenes[scene_index] = updated_scene;
			chapter.updatedAt = new Date();
			project.lastOpenedSceneId = scene_id;
		});
	}

	/**
	 * Delete a scene
	 */
	delete_scene(chapter_id: string, scene_id: string): boolean {
		if (!this.current_project) return false;

		const chapter = this.get_chapter(chapter_id);
		if (!chapter) {
			return false;
		}

		return this.update_current_project((project) => {
			const chapter_index = project.chapters.findIndex((c) => c.id === chapter_id);
			if (chapter_index === -1) return;

			const scene_index = project.chapters[chapter_index].scenes.findIndex(
				(scene) => scene.id === scene_id
			);
			if (scene_index === -1) return;

			project.chapters[chapter_index].scenes.splice(scene_index, 1);
			project.chapters[chapter_index].updatedAt = new Date();
		});
	}

	/**
	 * Create a new note
	 */
	create_note(title: string = 'Untitled Note', description: string = ''): string | null {
		if (!this.current_project) return null;

		const note_id = this.generate_id('note');
		const now = new Date();

		const new_note: Note = {
			id: note_id,
			title,
			description,
			createdAt: now,
			updatedAt: now,
			order: this.current_project.notes?.length || 0
		};

		this.update_current_project((project) => {
			if (!project.notes) {
				project.notes = [];
			}
			project.notes.push(new_note);
		});

		return note_id;
	}

	/**
	 * Update a note
	 */
	update_note(note_id: string, updates: Partial<Omit<Note, 'id' | 'createdAt'>>): boolean {
		return this.update_current_project((project) => {
			if (!project.notes) return;

			const note_index = project.notes.findIndex((note) => note.id === note_id);
			if (note_index === -1) return;

			const updated_note = {
				...project.notes[note_index],
				...updates,
				updatedAt: new Date()
			};

			project.notes[note_index] = updated_note;
		});
	}

	/**
	 * Delete a note
	 */
	delete_note(note_id: string): boolean {
		return this.update_current_project((project) => {
			if (!project.notes) return;

			const note_index = project.notes.findIndex((note) => note.id === note_id);
			if (note_index === -1) return;

			project.notes.splice(note_index, 1);
		});
	}

	/**
	 * Get all notes for the current project
	 */
	get_notes(): Note[] {
		if (!this.current_project || !this.current_project.notes) return [];
		return [...this.current_project.notes].sort((a, b) => a.order - b.order);
	}

	/**
	 * Get recently updated notes
	 */
	get_recent_notes(limit: number = 3): Note[] {
		if (!this.current_project || !this.current_project.notes) return [];

		return [...this.current_project.notes]
			.sort((a, b) => new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime())
			.slice(0, limit);
	}

	/**
	 * Update last opened scene
	 */
	update_last_opened_scene(scene_id: string): void {
		this.update_current_project((project) => {
			project.lastOpenedSceneId = scene_id;
		});
	}

	/**
	 * Get recently updated scenes across all chapters
	 */
	get_recent_scenes(
		limit: number = 10
	): Array<Scene & { chapter_id: string; chapter_title: string }> {
		if (!this.current_project) return [];

		const all_scenes: Array<Scene & { chapter_id: string; chapter_title: string }> = [];

		for (const chapter of this.current_project.chapters) {
			for (const scene of chapter.scenes) {
				all_scenes.push({
					...scene,
					chapter_id: chapter.id,
					chapter_title: chapter.title
				});
			}
		}

		// Sort by updatedAt in descending order (most recent first)
		all_scenes.sort((a, b) => new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime());

		return all_scenes.slice(0, limit);
	}

	/**
	 * Get project statistics
	 */
	get_project_stats() {
		if (!this.current_project) {
			return { total_words: 0, total_characters: 0, total_scenes: 0, total_chapters: 0 };
		}

		let total_words = 0;
		let total_characters = 0;
		let total_scenes = 0;

		for (const chapter of this.current_project.chapters) {
			for (const scene of chapter.scenes) {
				total_words += scene.wordCount;
				total_characters += scene.characterCount;
				total_scenes++;
			}
		}

		return {
			total_words,
			total_characters,
			total_scenes,
			total_chapters: this.current_project.chapters.length
		};
	}

	/**
	 * Find the navigation URLs for the current project
	 */
	get_project_urls() {
		if (!this.current_project) return null;

		// Find the scene to navigate to (last opened or first available)
		let target_scene_id = this.current_project.lastOpenedSceneId;
		let target_chapter_id: string | null = null;

		if (target_scene_id) {
			// Find the chapter containing the last opened scene
			for (const chapter of this.current_project.chapters) {
				if (chapter.scenes.find((scene) => scene.id === target_scene_id)) {
					target_chapter_id = chapter.id;
					break;
				}
			}
		}

		// If no last opened scene or scene not found, use first available
		if (!target_chapter_id || !target_scene_id) {
			const first_chapter = this.current_project.chapters[0];
			if (first_chapter && first_chapter.scenes.length > 0) {
				target_chapter_id = first_chapter.id;
				target_scene_id = first_chapter.scenes[0].id;
			}
		}

		const base_url = `/${this.current_project.id}`;
		const scene_url =
			target_chapter_id && target_scene_id
				? `/${this.current_project.id}/${target_chapter_id}/${target_scene_id}`
				: base_url;

		return {
			project_url: base_url,
			scene_url
		};
	}

	/**
	 * Get file status information
	 */
	get_file_status() {
		return {
			current_file: file_service.current_file,
			current_file_name: file_service.current_file_name,
			has_unsaved_changes: file_service.has_changes,
			display_title: this.current_project
				? file_service.get_display_title(this.current_project.title)
				: 'Omnia'
		};
	}

	/**
	 * Check if a project is currently loaded
	 */
	has_project(): boolean {
		return this.current_project !== null;
	}

	/**
	 * Utility methods
	 */
	private generate_id(prefix: string): string {
		return `${prefix}-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
	}

	private strip_html(html: string): string {
		// Simple HTML tag removal for SSR compatibility
		return html.replace(/<[^>]*>/g, '');
	}

	private count_words(text: string): number {
		return text
			.trim()
			.split(/\s+/)
			.filter((word) => word.length > 0).length;
	}

	/**
	 * Trigger auto-save
	 */
	private async trigger_auto_save(): Promise<void> {
		if (this.current_project) {
			await file_service.trigger_auto_save_if_needed(this.current_project);
		}
	}

	/**
	 * Get recent projects
	 */
	get_recent_projects() {
		return file_service.get_recent_projects();
	}

	/**
	 * Open project from path
	 */
	async open_project_from_path(file_path: string): Promise<Project | null> {
		const project = await file_service.open_project_from_path(file_path);
		if (project) {
			this.current_project = project;
		}
		return project;
	}
}

// Export a singleton instance
export const projects_service = new ProjectsService();
