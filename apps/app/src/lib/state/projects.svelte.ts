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

export interface Project {
	id: string;
	title: string;
	description: string;
	createdAt: Date;
	updatedAt: Date;
	chapters: Chapter[];
	lastOpenedSceneId?: string;
}

import { projects_service } from '$lib/services/projects.js';

class Projects {
	private projects_data = $state<Project[]>([]);
	private trigger = $state(0);
	private active_project_id = $state<string | null>(null);
	private active_chapter_id = $state<string | null>(null);
	private active_scene_id = $state<string | null>(null);
	private is_distraction_free = $state(false);
	private expanded_chapters = $state<string[]>([]);

	constructor() {
		// Load projects from service
		this.refresh();
		this.initializeExpandedChapters();
	}

	private initializeExpandedChapters() {
		// Auto-expand first chapter of each project if no chapters are expanded
		this.projects_data.forEach((project) => {
			if (project.chapters.length > 0 && this.expanded_chapters.length === 0) {
				this.expanded_chapters = [project.chapters[0].id];
			}
		});
	}

	// Trigger reactivity by updating a counter
	private trigger_update() {
		this.trigger = Date.now();
	}

	// Refresh projects from service
	refresh() {
		this.projects_data = projects_service.get_projects();
		this.trigger_update();
	}

	// Getters
	get projects(): Project[] {
		return this.projects_data;
	}

	get activeProject(): Project | null {
		if (!this.active_project_id) return null;
		return this.projects_data.find((project) => project.id === this.active_project_id) || null;
	}

	get activeChapter(): Chapter | null {
		const project = this.activeProject;
		if (!project || !this.active_chapter_id) return null;
		return project.chapters.find((chapter) => chapter.id === this.active_chapter_id) || null;
	}

	get activeScene(): Scene | null {
		const chapter = this.activeChapter;
		if (!chapter || !this.active_scene_id) return null;
		return chapter.scenes.find((scene) => scene.id === this.active_scene_id) || null;
	}

	get activeProjectId(): string | null {
		return this.active_project_id;
	}

	get activeChapterId(): string | null {
		return this.active_chapter_id;
	}

	get activeSceneId(): string | null {
		return this.active_scene_id;
	}

	get isDistractionFree(): boolean {
		return this.is_distraction_free;
	}

	get expandedChapters(): string[] {
		return this.expanded_chapters;
	}

	// Project methods
	createProject(title: string = 'Untitled Project', description: string = ''): string {
		const project_id = projects_service.create_project(title, description);
		if (!project_id) {
			throw new Error('Failed to create project');
		}
		this.refresh();
		this.active_project_id = project_id;
		return project_id;
	}

	updateProject(id: string, updates: Partial<Omit<Project, 'id' | 'createdAt' | 'chapters'>>) {
		const result = projects_service.update_project(id, updates);
		if (!result) {
			throw new Error(`Failed to update project with id: ${id}`);
		}
		this.refresh();
	}

	deleteProject(id: string) {
		const success = projects_service.delete_project(id);
		if (!success) {
			throw new Error(`Failed to delete project with id: ${id}`);
		}
		this.refresh();
		// If we deleted the active project, switch to the first available one
		if (this.active_project_id === id) {
			const first_project = this.projects_data[0];
			if (first_project) {
				this.setActiveProject(first_project.id);
			} else {
				this.active_project_id = null;
				this.active_chapter_id = null;
				this.active_scene_id = null;
			}
		}
	}

	setActiveProject(id: string) {
		const project = this.projects_data.find((project) => project.id === id);
		if (!project) {
			throw new Error(`Project with id ${id} not found`);
		}

		this.active_project_id = id;

		// Set active chapter and scene to the last opened or first available
		if (project.lastOpenedSceneId) {
			// Find the scene and set the chapter/scene accordingly
			for (const chapter of project.chapters) {
				const scene = chapter.scenes.find((s) => s.id === project.lastOpenedSceneId);
				if (scene) {
					this.active_chapter_id = chapter.id;
					this.active_scene_id = scene.id;
					return;
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

		// Auto-expand the active chapter
		this.autoExpandActiveChapter();
	}

	// Chapter methods
	createChapter(project_id: string, title: string = 'Untitled Chapter'): string {
		const chapter_id = projects_service.create_chapter(project_id, title);
		if (!chapter_id) {
			throw new Error(`Failed to create chapter in project ${project_id}`);
		}
		this.refresh();
		this.active_chapter_id = chapter_id;
		return chapter_id;
	}

	updateChapter(
		project_id: string,
		chapter_id: string,
		updates: Partial<Omit<Chapter, 'id' | 'createdAt' | 'scenes'>>
	) {
		const result = projects_service.update_chapter(project_id, chapter_id, updates);
		if (!result) {
			throw new Error(`Failed to update chapter ${chapter_id} in project ${project_id}`);
		}
		this.refresh();
	}

	deleteChapter(project_id: string, chapter_id: string) {
		const success = projects_service.delete_chapter(project_id, chapter_id);
		if (!success) {
			throw new Error(`Failed to delete chapter ${chapter_id} in project ${project_id}`);
		}
		this.refresh();
		// If we deleted the active chapter, switch to the first available one
		if (this.active_chapter_id === chapter_id) {
			const project = this.projects_data.find((p) => p.id === project_id);
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
		const project = this.activeProject;
		if (!project) {
			throw new Error('No active project found');
		}

		const chapter = project.chapters.find((c) => c.id === chapter_id);
		if (!chapter) {
			throw new Error(`Chapter ${chapter_id} not found in active project`);
		}
		this.active_chapter_id = chapter_id;
		// Set to first scene in chapter
		const first_scene = chapter.scenes[0];
		if (first_scene) {
			this.active_scene_id = first_scene.id;
		}
	}

	// Scene methods
	createScene(project_id: string, chapter_id: string, title: string = 'Untitled Scene'): string {
		const scene_id = projects_service.create_scene(project_id, chapter_id, title);
		if (!scene_id) {
			throw new Error(`Failed to create scene in chapter ${chapter_id} of project ${project_id}`);
		}
		this.refresh();
		this.active_scene_id = scene_id;
		return scene_id;
	}

	updateScene(
		project_id: string,
		chapter_id: string,
		scene_id: string,
		updates: Partial<Omit<Scene, 'id' | 'createdAt'>>
	) {
		const result = projects_service.update_scene(project_id, chapter_id, scene_id, updates);
		if (!result) {
			throw new Error(
				`Failed to update scene ${scene_id} in chapter ${chapter_id} of project ${project_id}`
			);
		}
		this.refresh();
	}

	deleteScene(project_id: string, chapter_id: string, scene_id: string) {
		const success = projects_service.delete_scene(project_id, chapter_id, scene_id);
		if (!success) {
			throw new Error(
				`Failed to delete scene ${scene_id} in chapter ${chapter_id} of project ${project_id}`
			);
		}
		this.refresh();
		// If we deleted the active scene, switch to the first available one
		if (this.active_scene_id === scene_id) {
			const project = this.projects_data.find((p) => p.id === project_id);
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
		const project = this.activeProject;
		if (!project) {
			throw new Error('No active project found');
		}

		// Find the scene and set the chapter/scene accordingly
		for (const chapter of project.chapters) {
			const scene = chapter.scenes.find((s) => s.id === scene_id);
			if (scene) {
				this.active_chapter_id = chapter.id;
				this.active_scene_id = scene_id;
				projects_service.update_last_opened_scene(project.id, scene_id);
				this.autoExpandActiveChapter();
				this.refresh();
				return;
			}
		}
		throw new Error(`Scene ${scene_id} not found in active project`);
	}

	// Focus mode
	toggleDistractionFree() {
		this.is_distraction_free = !this.is_distraction_free;
	}

	setDistractionFree(value: boolean) {
		this.is_distraction_free = value;
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

	// Utility methods
	private stripHtml(html: string): string {
		// Simple HTML tag removal for SSR compatibility
		return html.replace(/<[^>]*>/g, '');
	}

	private countWords(text: string): number {
		return text
			.trim()
			.split(/\s+/)
			.filter((word) => word.length > 0).length;
	}

	// Get project statistics
	getProjectStats(project_id: string) {
		return projects_service.get_project_stats(project_id);
	}

	// Get total statistics across all projects
	getTotalStats() {
		return projects_service.get_total_stats();
	}

	// Get project URLs
	getProjectUrls(project_id: string) {
		const urls = projects_service.get_project_urls(project_id);
		if (!urls) {
			throw new Error(`Failed to get URLs for project ${project_id}`);
		}
		return urls;
	}
}

export const projects = new Projects();
