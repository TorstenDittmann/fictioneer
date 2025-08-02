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

class Projects {
	private _projects = $state<Project[]>([]);
	private _activeProjectId = $state<string | null>(null);
	private _activeChapterId = $state<string | null>(null);
	private _activeSceneId = $state<string | null>(null);
	private _isDistractionFree = $state(false);

	constructor() {
		// Create a default project with sample structure
		this.createProject('My First Novel', 'A story waiting to be told');
	}

	// Getters
	get projects(): Project[] {
		return this._projects;
	}

	get activeProject(): Project | null {
		if (!this._activeProjectId) return null;
		return this._projects.find((project) => project.id === this._activeProjectId) || null;
	}

	get activeChapter(): Chapter | null {
		const project = this.activeProject;
		if (!project || !this._activeChapterId) return null;
		return project.chapters.find((chapter) => chapter.id === this._activeChapterId) || null;
	}

	get activeScene(): Scene | null {
		const chapter = this.activeChapter;
		if (!chapter || !this._activeSceneId) return null;
		return chapter.scenes.find((scene) => scene.id === this._activeSceneId) || null;
	}

	get activeProjectId(): string | null {
		return this._activeProjectId;
	}

	get activeChapterId(): string | null {
		return this._activeChapterId;
	}

	get activeSceneId(): string | null {
		return this._activeSceneId;
	}

	get isDistractionFree(): boolean {
		return this._isDistractionFree;
	}

	// Project methods
	createProject(title: string = 'Untitled Project', description: string = ''): string {
		const projectId = `project-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
		const now = new Date();

		const newProject: Project = {
			id: projectId,
			title,
			description,
			createdAt: now,
			updatedAt: now,
			chapters: []
		};

		this._projects.push(newProject);
		this._activeProjectId = projectId;

		// Create a default chapter and scene
		const chapterId = this.createChapter(projectId, 'Chapter 1');
		this.createScene(projectId, chapterId, 'Scene 1');

		return projectId;
	}

	updateProject(id: string, updates: Partial<Omit<Project, 'id' | 'createdAt' | 'chapters'>>) {
		const projectIndex = this._projects.findIndex((project) => project.id === id);
		if (projectIndex === -1) return;

		this._projects[projectIndex] = {
			...this._projects[projectIndex],
			...updates,
			updatedAt: new Date()
		};
	}

	deleteProject(id: string) {
		if (this._projects.length <= 1) return; // Don't delete the last project

		const projectIndex = this._projects.findIndex((project) => project.id === id);
		if (projectIndex === -1) return;

		this._projects.splice(projectIndex, 1);

		// If we deleted the active project, switch to the first available one
		if (this._activeProjectId === id) {
			const firstProject = this._projects[0];
			if (firstProject) {
				this.setActiveProject(firstProject.id);
			} else {
				this._activeProjectId = null;
				this._activeChapterId = null;
				this._activeSceneId = null;
			}
		}
	}

	setActiveProject(id: string) {
		const project = this._projects.find((project) => project.id === id);
		if (!project) return;

		this._activeProjectId = id;

		// Set active chapter and scene to the last opened or first available
		if (project.lastOpenedSceneId) {
			// Find the scene and set the chapter/scene accordingly
			for (const chapter of project.chapters) {
				const scene = chapter.scenes.find((s) => s.id === project.lastOpenedSceneId);
				if (scene) {
					this._activeChapterId = chapter.id;
					this._activeSceneId = scene.id;
					return;
				}
			}
		}

		// Default to first chapter and scene
		const firstChapter = project.chapters[0];
		if (firstChapter) {
			this._activeChapterId = firstChapter.id;
			const firstScene = firstChapter.scenes[0];
			if (firstScene) {
				this._activeSceneId = firstScene.id;
			}
		}
	}

	// Chapter methods
	createChapter(projectId: string, title: string = 'Untitled Chapter'): string {
		const project = this._projects.find((p) => p.id === projectId);
		if (!project) return '';

		const chapterId = `chapter-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
		const now = new Date();

		const newChapter: Chapter = {
			id: chapterId,
			title,
			createdAt: now,
			updatedAt: now,
			scenes: [],
			order: project.chapters.length
		};

		project.chapters.push(newChapter);
		project.updatedAt = now;
		this._activeChapterId = chapterId;

		return chapterId;
	}

	updateChapter(
		projectId: string,
		chapterId: string,
		updates: Partial<Omit<Chapter, 'id' | 'createdAt' | 'scenes'>>
	) {
		const project = this._projects.find((p) => p.id === projectId);
		if (!project) return;

		const chapterIndex = project.chapters.findIndex((chapter) => chapter.id === chapterId);
		if (chapterIndex === -1) return;

		project.chapters[chapterIndex] = {
			...project.chapters[chapterIndex],
			...updates,
			updatedAt: new Date()
		};
		project.updatedAt = new Date();
	}

	deleteChapter(projectId: string, chapterId: string) {
		const project = this._projects.find((p) => p.id === projectId);
		if (!project || project.chapters.length <= 1) return; // Don't delete the last chapter

		const chapterIndex = project.chapters.findIndex((chapter) => chapter.id === chapterId);
		if (chapterIndex === -1) return;

		project.chapters.splice(chapterIndex, 1);
		project.updatedAt = new Date();

		// If we deleted the active chapter, switch to the first available one
		if (this._activeChapterId === chapterId) {
			const firstChapter = project.chapters[0];
			if (firstChapter) {
				this._activeChapterId = firstChapter.id;
				const firstScene = firstChapter.scenes[0];
				if (firstScene) {
					this._activeSceneId = firstScene.id;
				}
			}
		}
	}

	setActiveChapter(chapterId: string) {
		const project = this.activeProject;
		if (!project) return;

		const chapter = project.chapters.find((c) => c.id === chapterId);
		if (chapter) {
			this._activeChapterId = chapterId;
			// Set to first scene in chapter
			const firstScene = chapter.scenes[0];
			if (firstScene) {
				this._activeSceneId = firstScene.id;
			}
		}
	}

	// Scene methods
	createScene(projectId: string, chapterId: string, title: string = 'Untitled Scene'): string {
		const project = this._projects.find((p) => p.id === projectId);
		if (!project) return '';

		const chapter = project.chapters.find((c) => c.id === chapterId);
		if (!chapter) return '';

		const sceneId = `scene-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
		const now = new Date();

		const newScene: Scene = {
			id: sceneId,
			title,
			content: '',
			createdAt: now,
			updatedAt: now,
			wordCount: 0,
			characterCount: 0,
			order: chapter.scenes.length
		};

		chapter.scenes.push(newScene);
		chapter.updatedAt = now;
		project.updatedAt = now;
		this._activeSceneId = sceneId;

		return sceneId;
	}

	updateScene(
		projectId: string,
		chapterId: string,
		sceneId: string,
		updates: Partial<Omit<Scene, 'id' | 'createdAt'>>
	) {
		const project = this._projects.find((p) => p.id === projectId);
		if (!project) return;

		const chapter = project.chapters.find((c) => c.id === chapterId);
		if (!chapter) return;

		const sceneIndex = chapter.scenes.findIndex((scene) => scene.id === sceneId);
		if (sceneIndex === -1) return;

		const updatedScene = {
			...chapter.scenes[sceneIndex],
			...updates,
			updatedAt: new Date()
		};

		// Calculate word and character count if content is updated
		if (updates.content !== undefined) {
			const textContent = this.stripHtml(updates.content);
			updatedScene.wordCount = this.countWords(textContent);
			updatedScene.characterCount = textContent.length;
		}

		chapter.scenes[sceneIndex] = updatedScene;
		chapter.updatedAt = new Date();
		project.updatedAt = new Date();
		project.lastOpenedSceneId = sceneId;
	}

	deleteScene(projectId: string, chapterId: string, sceneId: string) {
		const project = this._projects.find((p) => p.id === projectId);
		if (!project) return;

		const chapter = project.chapters.find((c) => c.id === chapterId);
		if (!chapter || chapter.scenes.length <= 1) return; // Don't delete the last scene

		const sceneIndex = chapter.scenes.findIndex((scene) => scene.id === sceneId);
		if (sceneIndex === -1) return;

		chapter.scenes.splice(sceneIndex, 1);
		chapter.updatedAt = new Date();
		project.updatedAt = new Date();

		// If we deleted the active scene, switch to the first available one
		if (this._activeSceneId === sceneId) {
			const firstScene = chapter.scenes[0];
			if (firstScene) {
				this._activeSceneId = firstScene.id;
			}
		}
	}

	setActiveScene(sceneId: string) {
		const project = this.activeProject;
		if (!project) return;

		// Find the scene and set the chapter/scene accordingly
		for (const chapter of project.chapters) {
			const scene = chapter.scenes.find((s) => s.id === sceneId);
			if (scene) {
				this._activeChapterId = chapter.id;
				this._activeSceneId = sceneId;
				project.lastOpenedSceneId = sceneId;
				project.updatedAt = new Date();
				return;
			}
		}
	}

	// Focus mode
	toggleDistractionFree() {
		this._isDistractionFree = !this._isDistractionFree;
	}

	setDistractionFree(value: boolean) {
		this._isDistractionFree = value;
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
	getProjectStats(projectId: string) {
		const project = this._projects.find((p) => p.id === projectId);
		if (!project) return { totalWords: 0, totalCharacters: 0, totalScenes: 0, totalChapters: 0 };

		let totalWords = 0;
		let totalCharacters = 0;
		let totalScenes = 0;

		for (const chapter of project.chapters) {
			for (const scene of chapter.scenes) {
				totalWords += scene.wordCount;
				totalCharacters += scene.characterCount;
				totalScenes++;
			}
		}

		return {
			totalWords,
			totalCharacters,
			totalScenes,
			totalChapters: project.chapters.length
		};
	}

	// Get total statistics across all projects
	getTotalStats() {
		return this._projects.reduce(
			(acc, project) => {
				const projectStats = this.getProjectStats(project.id);
				return {
					totalWords: acc.totalWords + projectStats.totalWords,
					totalCharacters: acc.totalCharacters + projectStats.totalCharacters,
					totalScenes: acc.totalScenes + projectStats.totalScenes,
					totalChapters: acc.totalChapters + projectStats.totalChapters,
					totalProjects: acc.totalProjects + 1
				};
			},
			{ totalWords: 0, totalCharacters: 0, totalScenes: 0, totalChapters: 0, totalProjects: 0 }
		);
	}
}

export const projects = new Projects();
