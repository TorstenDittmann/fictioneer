import { generate_id } from '../utils.js';
import type { Project } from './projects.svelte.js';

/**
 * Create an example project with original content
 */
export async function create_example_project(): Promise<Project> {
	const {
		EXAMPLE_PROJECT_TITLE,
		EXAMPLE_PROJECT_DESCRIPTION,
		CHAPTER_1_SCENES,
		CHAPTER_2_SCENES,
		CHAPTER_3_SCENES,
		CHARACTER_NOTES,
		get_scene_word_count,
		get_scene_character_count
	} = await import('../data/example_project.js');

	const now = new Date();
	const project_id = generate_id('project');

	// Create chapters and scenes
	const chapters = [
		{
			id: generate_id('chapter'),
			title: 'I. The Visitor',
			createdAt: now,
			updatedAt: now,
			order: 0,
			scenes: CHAPTER_1_SCENES.map((scene, index) => ({
				id: generate_id('scene'),
				title: scene.title,
				content: scene.content,
				createdAt: now,
				updatedAt: now,
				wordCount: get_scene_word_count(scene.content),
				characterCount: get_scene_character_count(scene.content),
				order: index
			}))
		},
		{
			id: generate_id('chapter'),
			title: 'II. The Investigation',
			createdAt: now,
			updatedAt: now,
			order: 1,
			scenes: CHAPTER_2_SCENES.map((scene, index) => ({
				id: generate_id('scene'),
				title: scene.title,
				content: scene.content,
				createdAt: now,
				updatedAt: now,
				wordCount: get_scene_word_count(scene.content),
				characterCount: get_scene_character_count(scene.content),
				order: index
			}))
		},
		{
			id: generate_id('chapter'),
			title: 'III. The Resolution',
			createdAt: now,
			updatedAt: now,
			order: 2,
			scenes: CHAPTER_3_SCENES.map((scene, index) => ({
				id: generate_id('scene'),
				title: scene.title,
				content: scene.content,
				createdAt: now,
				updatedAt: now,
				wordCount: get_scene_word_count(scene.content),
				characterCount: get_scene_character_count(scene.content),
				order: index
			}))
		}
	];

	// Create character notes
	const notes = CHARACTER_NOTES.map((note, index) => ({
		id: generate_id('note'),
		title: note.title,
		description: note.description,
		createdAt: now,
		updatedAt: now,
		order: index,
		tags: note.tags
	}));

	const project: Project = {
		id: project_id,
		title: EXAMPLE_PROJECT_TITLE,
		description: EXAMPLE_PROJECT_DESCRIPTION,
		createdAt: now,
		updatedAt: now,
		chapters,
		notes,
		lastOpenedSceneId: chapters[0].scenes[0].id
	};

	return project;
}
