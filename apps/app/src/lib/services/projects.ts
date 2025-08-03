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

class ProjectsService {
	private storage_key = 'omnia_projects';

	// Get all projects from storage
	get_projects(): Project[] {
		if (typeof localStorage === 'undefined') return [];

		try {
			const stored = localStorage.getItem(this.storage_key);
			if (!stored) return this.initialize_default_projects();

			const projects = JSON.parse(stored);
			// Convert date strings back to Date objects
			return projects.map((project: Project) => ({
				...project,
				createdAt: new Date(project.createdAt),
				updatedAt: new Date(project.updatedAt),
				chapters: project.chapters.map((chapter: Chapter) => ({
					...chapter,
					createdAt: new Date(chapter.createdAt),
					updatedAt: new Date(chapter.updatedAt),
					scenes: chapter.scenes.map((scene: Scene) => ({
						...scene,
						createdAt: new Date(scene.createdAt),
						updatedAt: new Date(scene.updatedAt)
					}))
				}))
			}));
		} catch {
			return this.initialize_default_projects();
		}
	}

	// Get a specific project by ID
	get_project(id: string): Project | null {
		const projects = this.get_projects();
		return projects.find((project) => project.id === id) || null;
	}

	// Get a specific chapter by project and chapter ID
	get_chapter(project_id: string, chapter_id: string): Chapter | null {
		const project = this.get_project(project_id);
		if (!project) return null;
		return project.chapters.find((chapter) => chapter.id === chapter_id) || null;
	}

	// Get a specific scene by project, chapter, and scene ID
	get_scene(project_id: string, chapter_id: string, scene_id: string): Scene | null {
		const chapter = this.get_chapter(project_id, chapter_id);
		if (!chapter) return null;
		return chapter.scenes.find((scene) => scene.id === scene_id) || null;
	}

	// Save projects to storage
	private save_projects(projects: Project[]): void {
		if (typeof localStorage === 'undefined') return;
		localStorage.setItem(this.storage_key, JSON.stringify(projects));
	}

	// Initialize with a default project if none exist
	private initialize_default_projects(): Project[] {
		const project_id = this.generate_id('project');
		const chapter_id = this.generate_id('chapter');
		const scene_id = this.generate_id('scene');
		const now = new Date();

		const default_projects: Project[] = [
			{
				id: project_id,
				title: 'My First Novel',
				description: 'A story waiting to be told',
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
								content:
									'The most merciful thing in the world, I think, is the inability of the human mind to correlate all its contents. We live on a placid island of ignorance in the midst of black seas of infinity, and it was not meant that we should voyage far. The sciences, each straining in its own direction, have hitherto harmed us little; but some day the piecing together of dissociated knowledge will open up such terrifying vistas of reality, and of our frightful position therein, that we shall either go mad from the revelation or flee from the deadly light into the peace and safety of a new dark age.',
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
			}
		];

		this.save_projects(default_projects);
		return default_projects;
	}

	// Create a new project
	create_project(title: string = 'Untitled Project', description: string = ''): string {
		const projects = this.get_projects();
		const project_id = this.generate_id('project');
		const chapter_id = this.generate_id('chapter');
		const scene_id = this.generate_id('scene');
		const now = new Date();

		const new_project: Project = {
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

		projects.push(new_project);
		this.save_projects(projects);
		return project_id;
	}

	// Update a project
	update_project(
		id: string,
		updates: Partial<Omit<Project, 'id' | 'createdAt' | 'chapters'>>
	): Project | null {
		const projects = this.get_projects();
		const project_index = projects.findIndex((project) => project.id === id);

		if (project_index === -1) return null;

		const updated_project = {
			...projects[project_index],
			...updates,
			updatedAt: new Date()
		};

		projects[project_index] = updated_project;
		this.save_projects(projects);
		return updated_project;
	}

	// Delete a project
	delete_project(id: string): boolean {
		const projects = this.get_projects();
		if (projects.length <= 1) return false; // Don't delete the last project

		const project_index = projects.findIndex((project) => project.id === id);
		if (project_index === -1) return false;

		projects.splice(project_index, 1);
		this.save_projects(projects);
		return true;
	}

	// Create a new chapter
	create_chapter(project_id: string, title: string = 'Untitled Chapter'): string | null {
		const projects = this.get_projects();
		const project = projects.find((p) => p.id === project_id);
		if (!project) return null;

		const chapter_id = this.generate_id('chapter');
		const now = new Date();

		const new_chapter: Chapter = {
			id: chapter_id,
			title,
			createdAt: now,
			updatedAt: now,
			scenes: [],
			order: project.chapters.length
		};

		project.chapters.push(new_chapter);
		project.updatedAt = now;
		this.save_projects(projects);
		return chapter_id;
	}

	// Update a chapter
	update_chapter(
		project_id: string,
		chapter_id: string,
		updates: Partial<Omit<Chapter, 'id' | 'createdAt' | 'scenes'>>
	): Chapter | null {
		const projects = this.get_projects();
		const project = projects.find((p) => p.id === project_id);
		if (!project) return null;

		const chapter_index = project.chapters.findIndex((chapter) => chapter.id === chapter_id);
		if (chapter_index === -1) return null;

		const updated_chapter = {
			...project.chapters[chapter_index],
			...updates,
			updatedAt: new Date()
		};

		project.chapters[chapter_index] = updated_chapter;
		project.updatedAt = new Date();
		this.save_projects(projects);
		return updated_chapter;
	}

	// Delete a chapter
	delete_chapter(project_id: string, chapter_id: string): boolean {
		const projects = this.get_projects();
		const project = projects.find((p) => p.id === project_id);
		if (!project || project.chapters.length <= 1) return false; // Don't delete the last chapter

		const chapter_index = project.chapters.findIndex((chapter) => chapter.id === chapter_id);
		if (chapter_index === -1) return false;

		project.chapters.splice(chapter_index, 1);
		project.updatedAt = new Date();
		this.save_projects(projects);
		return true;
	}

	// Create a new scene
	create_scene(
		project_id: string,
		chapter_id: string,
		title: string = 'Untitled Scene'
	): string | null {
		const projects = this.get_projects();
		const project = projects.find((p) => p.id === project_id);
		if (!project) return null;

		const chapter = project.chapters.find((c) => c.id === chapter_id);
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

		chapter.scenes.push(new_scene);
		chapter.updatedAt = now;
		project.updatedAt = now;
		this.save_projects(projects);
		return scene_id;
	}

	// Update a scene
	update_scene(
		project_id: string,
		chapter_id: string,
		scene_id: string,
		updates: Partial<Omit<Scene, 'id' | 'createdAt'>>
	): Scene | null {
		const projects = this.get_projects();
		const project = projects.find((p) => p.id === project_id);
		if (!project) return null;

		const chapter = project.chapters.find((c) => c.id === chapter_id);
		if (!chapter) return null;

		const scene_index = chapter.scenes.findIndex((scene) => scene.id === scene_id);
		if (scene_index === -1) return null;

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
		project.updatedAt = new Date();
		project.lastOpenedSceneId = scene_id;
		this.save_projects(projects);
		return updated_scene;
	}

	// Delete a scene
	delete_scene(project_id: string, chapter_id: string, scene_id: string): boolean {
		const projects = this.get_projects();
		const project = projects.find((p) => p.id === project_id);
		if (!project) return false;

		const chapter = project.chapters.find((c) => c.id === chapter_id);
		if (!chapter || chapter.scenes.length <= 1) return false; // Don't delete the last scene

		const scene_index = chapter.scenes.findIndex((scene) => scene.id === scene_id);
		if (scene_index === -1) return false;

		chapter.scenes.splice(scene_index, 1);
		chapter.updatedAt = new Date();
		project.updatedAt = new Date();
		this.save_projects(projects);
		return true;
	}

	// Update last opened scene
	update_last_opened_scene(project_id: string, scene_id: string): void {
		const projects = this.get_projects();
		const project = projects.find((p) => p.id === project_id);
		if (!project) return;

		project.lastOpenedSceneId = scene_id;
		project.updatedAt = new Date();
		this.save_projects(projects);
	}

	// Get project statistics
	get_project_stats(project_id: string) {
		const project = this.get_project(project_id);
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
	get_total_stats() {
		const projects = this.get_projects();
		return projects.reduce(
			(acc, project) => {
				const project_stats = this.get_project_stats(project.id);
				return {
					totalWords: acc.totalWords + project_stats.totalWords,
					totalCharacters: acc.totalCharacters + project_stats.totalCharacters,
					totalScenes: acc.totalScenes + project_stats.totalScenes,
					totalChapters: acc.totalChapters + project_stats.totalChapters,
					totalProjects: acc.totalProjects + 1
				};
			},
			{ totalWords: 0, totalCharacters: 0, totalScenes: 0, totalChapters: 0, totalProjects: 0 }
		);
	}

	// Find the navigation URLs for a project
	get_project_urls(project_id: string) {
		const project = this.get_project(project_id);
		if (!project) return null;

		// Find the scene to navigate to (last opened or first available)
		let target_scene_id = project.lastOpenedSceneId;
		let target_chapter_id: string | null = null;

		if (target_scene_id) {
			// Find the chapter containing the last opened scene
			for (const chapter of project.chapters) {
				if (chapter.scenes.find((scene) => scene.id === target_scene_id)) {
					target_chapter_id = chapter.id;
					break;
				}
			}
		}

		// If no last opened scene or scene not found, use first available
		if (!target_chapter_id || !target_scene_id) {
			const first_chapter = project.chapters[0];
			if (first_chapter && first_chapter.scenes.length > 0) {
				target_chapter_id = first_chapter.id;
				target_scene_id = first_chapter.scenes[0].id;
			}
		}

		const base_url = `/${project_id}`;
		const scene_url =
			target_chapter_id && target_scene_id
				? `/${project_id}/${target_chapter_id}/${target_scene_id}`
				: base_url;

		return {
			project_url: base_url,
			scene_url
		};
	}

	// Utility methods
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
}

// Export a singleton instance
export const projects_service = new ProjectsService();
