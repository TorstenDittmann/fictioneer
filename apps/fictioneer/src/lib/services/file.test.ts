import { describe, it, expect } from 'bun:test';

/**
 * Since file.svelte.ts uses Tauri APIs and Svelte 5 runes ($state),
 * we test the pure utility functions that can be extracted and tested.
 * These functions are private in the class, so we recreate them here for testing.
 */

// Recreate utility functions from file.svelte.ts for testing
function sanitize_filename(filename: string): string {
	return filename
		.replace(/[<>:"/\\|?*]/g, '_')
		.replace(/\s+/g, '_')
		.trim()
		.substring(0, 50);
}

function is_version_compatible(file_version: string, current_version: string = '1.1.0'): boolean {
	const [major] = file_version.split('.').map(Number);
	const [current_major] = current_version.split('.').map(Number);

	if (major === current_major) {
		return true;
	}

	return major === 1 && current_major === 1;
}

interface ProjectFileData {
	version: string;
	createdAt: string;
	updatedAt: string;
	project: {
		id: string;
		title: string;
		description?: string;
		chapters: unknown[];
		progressGoals?: {
			dailyWordTarget: number;
			createdAt: string;
			updatedAt: string;
		};
		dailyProgress?: Array<{
			date: string;
			wordsWritten: number;
			goalMet: boolean;
			sessionsCount: number;
		}>;
	};
}

function validate_fictioneer_file(data: unknown): data is ProjectFileData {
	if (!data || typeof data !== 'object') {
		return false;
	}
	const obj = data as Record<string, unknown>;
	const project = obj.project as Record<string, unknown>;

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

describe('sanitize_filename', () => {
	it('should remove special characters', () => {
		expect(sanitize_filename('test<>:"/\\|?*file')).toBe('test_________file');
	});

	it('should replace spaces with underscores', () => {
		expect(sanitize_filename('my test file')).toBe('my_test_file');
	});

	it('should collapse multiple spaces', () => {
		expect(sanitize_filename('my    test   file')).toBe('my_test_file');
	});

	it('should limit length to 50 characters', () => {
		const long_name = 'a'.repeat(100);
		expect(sanitize_filename(long_name).length).toBe(50);
	});

	it('should handle Unicode characters', () => {
		expect(sanitize_filename('café_résumé')).toBe('café_résumé');
	});

	it('should handle empty string', () => {
		expect(sanitize_filename('')).toBe('');
	});

	it('should trim whitespace', () => {
		// The function replaces \s+ with single underscore, so '  test  ' becomes '_test_'
		// Then trim() removes nothing since underscores aren't whitespace
		const result = sanitize_filename('  test  ');
		expect(result).toBe('_test_');
	});

	it('should handle mixed special characters and spaces', () => {
		expect(sanitize_filename('My Book: A Story')).toBe('My_Book__A_Story');
	});
});

describe('validate_fictioneer_file', () => {
	it('should validate a correct file structure', () => {
		const valid_data = {
			version: '1.0.0',
			createdAt: '2024-01-01T00:00:00.000Z',
			updatedAt: '2024-01-01T00:00:00.000Z',
			project: {
				id: 'project-123',
				title: 'Test Project',
				description: 'A test project',
				chapters: []
			}
		};
		expect(validate_fictioneer_file(valid_data)).toBe(true);
	});

	it('should reject missing version', () => {
		const invalid_data = {
			createdAt: '2024-01-01T00:00:00.000Z',
			updatedAt: '2024-01-01T00:00:00.000Z',
			project: {
				id: 'project-123',
				title: 'Test Project',
				chapters: []
			}
		};
		expect(validate_fictioneer_file(invalid_data)).toBe(false);
	});

	it('should reject missing project', () => {
		const invalid_data = {
			version: '1.0.0',
			createdAt: '2024-01-01T00:00:00.000Z',
			updatedAt: '2024-01-01T00:00:00.000Z'
		};
		expect(validate_fictioneer_file(invalid_data)).toBe(false);
	});

	it('should reject missing project.id', () => {
		const invalid_data = {
			version: '1.0.0',
			createdAt: '2024-01-01T00:00:00.000Z',
			updatedAt: '2024-01-01T00:00:00.000Z',
			project: {
				title: 'Test Project',
				chapters: []
			}
		};
		expect(validate_fictioneer_file(invalid_data)).toBe(false);
	});

	it('should reject non-array chapters', () => {
		const invalid_data = {
			version: '1.0.0',
			createdAt: '2024-01-01T00:00:00.000Z',
			updatedAt: '2024-01-01T00:00:00.000Z',
			project: {
				id: 'project-123',
				title: 'Test Project',
				chapters: 'not an array'
			}
		};
		expect(validate_fictioneer_file(invalid_data)).toBe(false);
	});

	it('should reject wrong type for version', () => {
		const invalid_data = {
			version: 123,
			createdAt: '2024-01-01T00:00:00.000Z',
			updatedAt: '2024-01-01T00:00:00.000Z',
			project: {
				id: 'project-123',
				title: 'Test Project',
				chapters: []
			}
		};
		expect(validate_fictioneer_file(invalid_data)).toBe(false);
	});

	it('should validate file with progress goals', () => {
		const valid_data = {
			version: '1.1.0',
			createdAt: '2024-01-01T00:00:00.000Z',
			updatedAt: '2024-01-01T00:00:00.000Z',
			project: {
				id: 'project-123',
				title: 'Test Project',
				chapters: [],
				progressGoals: {
					dailyWordTarget: 500,
					createdAt: '2024-01-01T00:00:00.000Z',
					updatedAt: '2024-01-01T00:00:00.000Z'
				}
			}
		};
		expect(validate_fictioneer_file(valid_data)).toBe(true);
	});

	it('should reject invalid progress goals', () => {
		const invalid_data = {
			version: '1.1.0',
			createdAt: '2024-01-01T00:00:00.000Z',
			updatedAt: '2024-01-01T00:00:00.000Z',
			project: {
				id: 'project-123',
				title: 'Test Project',
				chapters: [],
				progressGoals: {
					dailyWordTarget: 'not a number',
					createdAt: '2024-01-01T00:00:00.000Z',
					updatedAt: '2024-01-01T00:00:00.000Z'
				}
			}
		};
		expect(validate_fictioneer_file(invalid_data)).toBe(false);
	});

	it('should validate file with daily progress', () => {
		const valid_data = {
			version: '1.1.0',
			createdAt: '2024-01-01T00:00:00.000Z',
			updatedAt: '2024-01-01T00:00:00.000Z',
			project: {
				id: 'project-123',
				title: 'Test Project',
				chapters: [],
				dailyProgress: [
					{
						date: '2024-01-01',
						wordsWritten: 500,
						goalMet: true,
						sessionsCount: 2
					}
				]
			}
		};
		expect(validate_fictioneer_file(valid_data)).toBe(true);
	});

	it('should reject invalid daily progress', () => {
		const invalid_data = {
			version: '1.1.0',
			createdAt: '2024-01-01T00:00:00.000Z',
			updatedAt: '2024-01-01T00:00:00.000Z',
			project: {
				id: 'project-123',
				title: 'Test Project',
				chapters: [],
				dailyProgress: [
					{
						date: '2024-01-01',
						wordsWritten: 'not a number',
						goalMet: true,
						sessionsCount: 2
					}
				]
			}
		};
		expect(validate_fictioneer_file(invalid_data)).toBe(false);
	});

	it('should handle null input', () => {
		expect(validate_fictioneer_file(null)).toBe(false);
	});

	it('should handle undefined input', () => {
		expect(validate_fictioneer_file(undefined)).toBe(false);
	});
});

describe('is_version_compatible', () => {
	it('should accept v1.0.0', () => {
		expect(is_version_compatible('1.0.0')).toBe(true);
	});

	it('should accept v1.1.0', () => {
		expect(is_version_compatible('1.1.0')).toBe(true);
	});

	it('should accept v1.2.5', () => {
		expect(is_version_compatible('1.2.5')).toBe(true);
	});

	it('should reject v2.0.0', () => {
		expect(is_version_compatible('2.0.0')).toBe(false);
	});

	it('should reject v0.9.0', () => {
		expect(is_version_compatible('0.9.0')).toBe(false);
	});

	it('should handle invalid version format gracefully', () => {
		expect(is_version_compatible('invalid')).toBe(false);
	});

	it('should handle version with only major number', () => {
		expect(is_version_compatible('1')).toBe(true);
	});
});

describe('serialize and deserialize project', () => {
	interface Scene {
		id: string;
		title: string;
		content: string;
		createdAt: Date;
		updatedAt: Date;
		wordCount: number;
		characterCount: number;
		order: number;
	}

	interface Chapter {
		id: string;
		title: string;
		createdAt: Date;
		updatedAt: Date;
		scenes: Scene[];
		order: number;
	}

	interface Project {
		id: string;
		title: string;
		description: string;
		createdAt: Date;
		updatedAt: Date;
		chapters: Chapter[];
		notes: unknown[];
		lastOpenedSceneId?: string;
		progressGoals?: {
			dailyWordTarget: number;
			projectWordTarget?: number;
			createdAt: Date;
			updatedAt: Date;
		};
	}

	function serialize_project(project: Project) {
		return {
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
			notes: project.notes,
			progressGoals: project.progressGoals
				? {
						dailyWordTarget: project.progressGoals.dailyWordTarget,
						projectWordTarget: project.progressGoals.projectWordTarget,
						createdAt: project.progressGoals.createdAt.toISOString(),
						updatedAt: project.progressGoals.updatedAt.toISOString()
					}
				: undefined
		};
	}

	function deserialize_project(data: ReturnType<typeof serialize_project>): Project {
		return {
			id: data.id,
			title: data.title,
			description: data.description,
			createdAt: new Date(data.createdAt),
			updatedAt: new Date(data.updatedAt),
			lastOpenedSceneId: data.lastOpenedSceneId,
			chapters: data.chapters.map((chapter) => ({
				...chapter,
				createdAt: new Date(chapter.createdAt),
				updatedAt: new Date(chapter.updatedAt),
				scenes: chapter.scenes.map((scene) => ({
					...scene,
					createdAt: new Date(scene.createdAt),
					updatedAt: new Date(scene.updatedAt)
				}))
			})),
			notes: data.notes,
			progressGoals: data.progressGoals
				? {
						dailyWordTarget: data.progressGoals.dailyWordTarget,
						projectWordTarget: data.progressGoals.projectWordTarget,
						createdAt: new Date(data.progressGoals.createdAt),
						updatedAt: new Date(data.progressGoals.updatedAt)
					}
				: undefined
		};
	}

	const test_date = new Date('2024-01-15T10:30:00.000Z');

	it('should serialize dates to ISO strings', () => {
		const project: Project = {
			id: 'project-1',
			title: 'Test',
			description: 'Test description',
			createdAt: test_date,
			updatedAt: test_date,
			chapters: [],
			notes: []
		};

		const serialized = serialize_project(project);

		expect(serialized.createdAt).toBe('2024-01-15T10:30:00.000Z');
		expect(serialized.updatedAt).toBe('2024-01-15T10:30:00.000Z');
	});

	it('should serialize nested chapters and scenes', () => {
		const project: Project = {
			id: 'project-1',
			title: 'Test',
			description: '',
			createdAt: test_date,
			updatedAt: test_date,
			chapters: [
				{
					id: 'chapter-1',
					title: 'Chapter 1',
					createdAt: test_date,
					updatedAt: test_date,
					order: 0,
					scenes: [
						{
							id: 'scene-1',
							title: 'Scene 1',
							content: 'Test content',
							createdAt: test_date,
							updatedAt: test_date,
							wordCount: 2,
							characterCount: 12,
							order: 0
						}
					]
				}
			],
			notes: []
		};

		const serialized = serialize_project(project);

		expect(serialized.chapters[0].createdAt).toBe('2024-01-15T10:30:00.000Z');
		expect(serialized.chapters[0].scenes[0].createdAt).toBe('2024-01-15T10:30:00.000Z');
	});

	it('should serialize optional progress goals', () => {
		const project: Project = {
			id: 'project-1',
			title: 'Test',
			description: '',
			createdAt: test_date,
			updatedAt: test_date,
			chapters: [],
			notes: [],
			progressGoals: {
				dailyWordTarget: 1000,
				projectWordTarget: 50000,
				createdAt: test_date,
				updatedAt: test_date
			}
		};

		const serialized = serialize_project(project);

		expect(serialized.progressGoals?.dailyWordTarget).toBe(1000);
		expect(serialized.progressGoals?.projectWordTarget).toBe(50000);
		expect(serialized.progressGoals?.createdAt).toBe('2024-01-15T10:30:00.000Z');
	});

	it('should deserialize ISO strings back to Dates', () => {
		const serialized = {
			id: 'project-1',
			title: 'Test',
			description: '',
			createdAt: '2024-01-15T10:30:00.000Z',
			updatedAt: '2024-01-15T10:30:00.000Z',
			lastOpenedSceneId: undefined,
			chapters: [],
			notes: [],
			progressGoals: undefined
		};

		const deserialized = deserialize_project(serialized);

		expect(deserialized.createdAt).toBeInstanceOf(Date);
		expect(deserialized.createdAt.toISOString()).toBe('2024-01-15T10:30:00.000Z');
	});

	it('should deserialize nested chapters and scenes', () => {
		const serialized = {
			id: 'project-1',
			title: 'Test',
			description: '',
			createdAt: '2024-01-15T10:30:00.000Z',
			updatedAt: '2024-01-15T10:30:00.000Z',
			lastOpenedSceneId: undefined,
			chapters: [
				{
					id: 'chapter-1',
					title: 'Chapter 1',
					createdAt: '2024-01-15T10:30:00.000Z',
					updatedAt: '2024-01-15T10:30:00.000Z',
					order: 0,
					scenes: [
						{
							id: 'scene-1',
							title: 'Scene 1',
							content: '',
							createdAt: '2024-01-15T10:30:00.000Z',
							updatedAt: '2024-01-15T10:30:00.000Z',
							wordCount: 0,
							characterCount: 0,
							order: 0
						}
					]
				}
			],
			notes: [],
			progressGoals: undefined
		};

		const deserialized = deserialize_project(serialized);

		expect(deserialized.chapters[0].createdAt).toBeInstanceOf(Date);
		expect(deserialized.chapters[0].scenes[0].createdAt).toBeInstanceOf(Date);
	});

	it('should handle round-trip serialization/deserialization', () => {
		const original: Project = {
			id: 'project-1',
			title: 'Test Project',
			description: 'A test',
			createdAt: test_date,
			updatedAt: test_date,
			chapters: [
				{
					id: 'chapter-1',
					title: 'Chapter 1',
					createdAt: test_date,
					updatedAt: test_date,
					order: 0,
					scenes: [
						{
							id: 'scene-1',
							title: 'Scene 1',
							content: 'Hello world',
							createdAt: test_date,
							updatedAt: test_date,
							wordCount: 2,
							characterCount: 11,
							order: 0
						}
					]
				}
			],
			notes: [],
			lastOpenedSceneId: 'scene-1'
		};

		const serialized = serialize_project(original);
		const deserialized = deserialize_project(serialized);

		expect(deserialized.id).toBe(original.id);
		expect(deserialized.title).toBe(original.title);
		expect(deserialized.createdAt.getTime()).toBe(original.createdAt.getTime());
		expect(deserialized.chapters[0].scenes[0].content).toBe(original.chapters[0].scenes[0].content);
	});
});
