import Database from '@tauri-apps/plugin-sql';

interface PersistedScene {
	id: string;
	title: string;
	content: string;
	createdAt: string;
	updatedAt: string;
	wordCount: number;
	characterCount: number;
	order: number;
}

interface PersistedNote {
	id: string;
	title: string;
	description: string;
	createdAt: string;
	updatedAt: string;
	order: number;
	tags?: string[];
}

interface PersistedChapter {
	id: string;
	title: string;
	scenes: PersistedScene[];
	createdAt: string;
	updatedAt: string;
	order: number;
}

interface PersistedProgressGoals {
	dailyWordTarget: number;
	projectWordTarget?: number;
	createdAt: string;
	updatedAt: string;
}

interface PersistedDailyProgress {
	date: string;
	wordsWritten: number;
	goalMet: boolean;
	sessionsCount: number;
	createdAt: string;
	updatedAt: string;
}

interface PersistedProgressStats {
	currentStreak: number;
	longestStreak: number;
	totalDaysActive: number;
	averageDailyWords: number;
	estimatedCompletionDate?: string;
}

export interface ProjectSnapshot {
	id: string;
	title: string;
	description: string;
	chapters: PersistedChapter[];
	notes?: PersistedNote[];
	createdAt: string;
	updatedAt: string;
	lastOpenedSceneId?: string;
	progressGoals?: PersistedProgressGoals;
	dailyProgress?: PersistedDailyProgress[];
	progressStats?: PersistedProgressStats;
	dailyWordSnapshots?: Record<string, number>;
}

export interface StoredProjectFile {
	version: string;
	createdAt: string;
	updatedAt: string;
	project: ProjectSnapshot;
}

type SqlDatabase = Awaited<ReturnType<typeof Database.load>>;

interface StoredDocumentRow {
	id: string;
	data: string;
}

interface ProjectMetaDocument {
	id: string;
	title: string;
	description: string;
	createdAt: string;
	updatedAt: string;
	lastOpenedSceneId?: string;
}

interface SceneDocument extends PersistedScene {
	chapterId: string;
}

class ProjectStore {
	private db_by_path = new Map<string, SqlDatabase>();

	async load_project(path: string): Promise<StoredProjectFile | null> {
		const db = await this.get_db(path);
		await this.initialize_schema(db);

		const format_version = await this.get_meta_value(db, 'format_version');
		const created_at = await this.get_meta_value(db, 'created_at');
		const updated_at = await this.get_meta_value(db, 'updated_at');

		const project_meta_doc = await this.get_single_document<ProjectMetaDocument>(
			db,
			'project_meta'
		);
		if (!project_meta_doc || !format_version || !created_at || !updated_at) {
			return null;
		}

		const chapter_docs = await this.get_documents<PersistedChapter>(db, 'chapter');
		const scene_docs = await this.get_documents<SceneDocument>(db, 'scene');
		const note_docs = await this.get_documents<PersistedNote>(db, 'note');

		const scenes_by_chapter = new Map<string, PersistedScene[]>();
		for (const scene of scene_docs) {
			const chapter_scenes = scenes_by_chapter.get(scene.chapterId) || [];
			chapter_scenes.push({
				id: scene.id,
				title: scene.title,
				content: scene.content,
				createdAt: scene.createdAt,
				updatedAt: scene.updatedAt,
				wordCount: scene.wordCount,
				characterCount: scene.characterCount,
				order: scene.order
			});
			scenes_by_chapter.set(scene.chapterId, chapter_scenes);
		}

		const chapters = chapter_docs
			.map((chapter) => ({
				...chapter,
				scenes: (scenes_by_chapter.get(chapter.id) || []).sort((a, b) => a.order - b.order)
			}))
			.sort((a, b) => a.order - b.order);

		const notes = note_docs.sort((a, b) => a.order - b.order);

		const progress_goals = await this.get_single_document<PersistedProgressGoals>(
			db,
			'progress_goals'
		);
		const daily_progress = await this.get_single_document<PersistedDailyProgress[]>(
			db,
			'daily_progress'
		);
		const progress_stats = await this.get_single_document<PersistedProgressStats>(
			db,
			'progress_stats'
		);
		const daily_word_snapshots = await this.get_single_document<Record<string, number>>(
			db,
			'daily_word_snapshots'
		);

		return {
			version: format_version,
			createdAt: created_at,
			updatedAt: updated_at,
			project: {
				id: project_meta_doc.id,
				title: project_meta_doc.title,
				description: project_meta_doc.description,
				createdAt: project_meta_doc.createdAt,
				updatedAt: project_meta_doc.updatedAt,
				lastOpenedSceneId: project_meta_doc.lastOpenedSceneId,
				chapters,
				notes,
				progressGoals: progress_goals || undefined,
				dailyProgress: daily_progress || undefined,
				progressStats: progress_stats || undefined,
				dailyWordSnapshots: daily_word_snapshots || undefined
			}
		};
	}

	async save_project(
		path: string,
		file_data: StoredProjectFile,
		previous_snapshot: ProjectSnapshot | null
	): Promise<void> {
		const db = await this.get_db(path);
		await this.initialize_schema(db);

		await db.execute('BEGIN IMMEDIATE');

		try {
			await this.set_meta_value(db, 'format_version', file_data.version);
			await this.set_meta_value(db, 'created_at', file_data.createdAt);
			await this.set_meta_value(db, 'updated_at', file_data.updatedAt);

			const current_snapshot = file_data.project;

			await this.upsert_document(db, 'project_meta', 'project_meta', {
				id: current_snapshot.id,
				title: current_snapshot.title,
				description: current_snapshot.description,
				createdAt: current_snapshot.createdAt,
				updatedAt: current_snapshot.updatedAt,
				lastOpenedSceneId: current_snapshot.lastOpenedSceneId
			});

			await this.sync_chapters(db, current_snapshot, previous_snapshot);
			await this.sync_scenes(db, current_snapshot, previous_snapshot);
			await this.sync_notes(db, current_snapshot, previous_snapshot);
			await this.sync_singleton_doc(
				db,
				'progress_goals',
				current_snapshot.progressGoals,
				previous_snapshot?.progressGoals
			);
			await this.sync_singleton_doc(
				db,
				'daily_progress',
				current_snapshot.dailyProgress,
				previous_snapshot?.dailyProgress
			);
			await this.sync_singleton_doc(
				db,
				'progress_stats',
				current_snapshot.progressStats,
				previous_snapshot?.progressStats
			);
			await this.sync_singleton_doc(
				db,
				'daily_word_snapshots',
				current_snapshot.dailyWordSnapshots,
				previous_snapshot?.dailyWordSnapshots
			);

			await db.execute('COMMIT');
		} catch (error) {
			await db.execute('ROLLBACK');
			throw error;
		}
	}

	private async sync_chapters(
		db: SqlDatabase,
		current_snapshot: ProjectSnapshot,
		previous_snapshot: ProjectSnapshot | null
	): Promise<void> {
		const previous_map = this.map_by_id(previous_snapshot?.chapters || []);
		const current_map = this.map_by_id(current_snapshot.chapters);

		for (const chapter of current_snapshot.chapters) {
			const previous_chapter = previous_map.get(chapter.id);
			if (!previous_chapter || !this.is_equal(chapter, previous_chapter)) {
				await this.upsert_document(
					db,
					`chapter:${chapter.id}`,
					'chapter',
					chapter,
					chapter.updatedAt
				);
			}
		}

		for (const chapter_id of previous_map.keys()) {
			if (!current_map.has(chapter_id)) {
				await this.delete_document(db, `chapter:${chapter_id}`);
			}
		}
	}

	private async sync_scenes(
		db: SqlDatabase,
		current_snapshot: ProjectSnapshot,
		previous_snapshot: ProjectSnapshot | null
	): Promise<void> {
		const previous_scenes = this.flatten_scenes(previous_snapshot?.chapters || []);
		const current_scenes = this.flatten_scenes(current_snapshot.chapters);

		for (const scene of current_scenes.values()) {
			const previous_scene = previous_scenes.get(scene.id);
			if (!previous_scene || !this.is_equal(scene, previous_scene)) {
				await this.upsert_document(db, `scene:${scene.id}`, 'scene', scene, scene.updatedAt);
			}
		}

		for (const scene_id of previous_scenes.keys()) {
			if (!current_scenes.has(scene_id)) {
				await this.delete_document(db, `scene:${scene_id}`);
			}
		}
	}

	private async sync_notes(
		db: SqlDatabase,
		current_snapshot: ProjectSnapshot,
		previous_snapshot: ProjectSnapshot | null
	): Promise<void> {
		const previous_map = this.map_by_id(previous_snapshot?.notes || []);
		const current_notes = current_snapshot.notes || [];
		const current_map = this.map_by_id(current_notes);

		for (const note of current_notes) {
			const previous_note = previous_map.get(note.id);
			if (!previous_note || !this.is_equal(note, previous_note)) {
				await this.upsert_document(db, `note:${note.id}`, 'note', note, note.updatedAt);
			}
		}

		for (const note_id of previous_map.keys()) {
			if (!current_map.has(note_id)) {
				await this.delete_document(db, `note:${note_id}`);
			}
		}
	}

	private async sync_singleton_doc<T>(
		db: SqlDatabase,
		kind: string,
		current_value: T | undefined,
		previous_value: T | undefined
	): Promise<void> {
		const doc_id = `singleton:${kind}`;

		if (current_value === undefined) {
			if (previous_value !== undefined) {
				await this.delete_document(db, doc_id);
			}
			return;
		}

		if (previous_value === undefined || !this.is_equal(current_value, previous_value)) {
			await this.upsert_document(db, doc_id, kind, current_value);
		}
	}

	private async initialize_schema(db: SqlDatabase): Promise<void> {
		await db.execute('PRAGMA journal_mode=DELETE');
		await db.execute('PRAGMA foreign_keys=ON');
		await db.execute('CREATE TABLE IF NOT EXISTS meta (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
		await db.execute(
			'CREATE TABLE IF NOT EXISTS documents (id TEXT PRIMARY KEY, kind TEXT NOT NULL, data TEXT NOT NULL, updated_at TEXT NOT NULL)'
		);
		await db.execute('CREATE INDEX IF NOT EXISTS idx_documents_kind ON documents (kind)');
		await db.execute(
			'CREATE INDEX IF NOT EXISTS idx_documents_kind_updated ON documents (kind, updated_at)'
		);
	}

	private async get_db(path: string): Promise<SqlDatabase> {
		const normalized_path = this.normalize_path(path);
		const existing_db = this.db_by_path.get(normalized_path);
		if (existing_db) {
			return existing_db;
		}

		const db = await this.open_database(path);
		this.db_by_path.set(normalized_path, db);
		return db;
	}

	private async open_database(path: string): Promise<SqlDatabase> {
		const attempted_urls = this.build_connection_urls(path);
		let last_error: unknown = null;

		for (const connection_url of attempted_urls) {
			try {
				return await Database.load(connection_url);
			} catch (error) {
				last_error = error;
			}
		}

		throw new Error(
			`Failed to open project database at path: ${path}. Last error: ${String(last_error)}`
		);
	}

	private build_connection_urls(path: string): string[] {
		const normalized_path = this.normalize_path(path);
		const encoded_path = encodeURI(normalized_path);
		const is_windows_absolute = /^[a-zA-Z]:\//.test(normalized_path);

		if (is_windows_absolute) {
			return [
				`sqlite:${normalized_path}`,
				`sqlite:${encoded_path}`,
				`sqlite://${normalized_path}`,
				`sqlite://${encoded_path}`
			];
		}

		return [`sqlite:${normalized_path}`, `sqlite:${encoded_path}`, `sqlite://${encoded_path}`];
	}

	private normalize_path(path: string): string {
		return path.replace(/\\/g, '/');
	}

	private async set_meta_value(db: SqlDatabase, key: string, value: string): Promise<void> {
		await db.execute(
			'INSERT INTO meta (key, value) VALUES ($1, $2) ON CONFLICT(key) DO UPDATE SET value = excluded.value',
			[key, value]
		);
	}

	private async get_meta_value(db: SqlDatabase, key: string): Promise<string | null> {
		const rows = await db.select<Array<{ value: string }>>(
			'SELECT value FROM meta WHERE key = $1',
			[key]
		);
		if (rows.length === 0) return null;
		return rows[0].value;
	}

	private async upsert_document(
		db: SqlDatabase,
		id: string,
		kind: string,
		data: unknown,
		updated_at: string = new Date().toISOString()
	): Promise<void> {
		await db.execute(
			'INSERT INTO documents (id, kind, data, updated_at) VALUES ($1, $2, $3, $4) ON CONFLICT(id) DO UPDATE SET kind = excluded.kind, data = excluded.data, updated_at = excluded.updated_at',
			[id, kind, JSON.stringify(data), updated_at]
		);
	}

	private async delete_document(db: SqlDatabase, id: string): Promise<void> {
		await db.execute('DELETE FROM documents WHERE id = $1', [id]);
	}

	private async get_documents<T>(db: SqlDatabase, kind: string): Promise<T[]> {
		const rows = await db.select<StoredDocumentRow[]>(
			'SELECT id, data FROM documents WHERE kind = $1',
			[kind]
		);
		return rows.map((row) => JSON.parse(row.data) as T);
	}

	private async get_single_document<T>(db: SqlDatabase, kind: string): Promise<T | null> {
		const rows = await db.select<StoredDocumentRow[]>(
			'SELECT id, data FROM documents WHERE kind = $1 LIMIT 1',
			[kind]
		);
		if (rows.length === 0) return null;
		return JSON.parse(rows[0].data) as T;
	}

	private map_by_id<T extends { id: string }>(items: T[]): Map<string, T> {
		const map = new Map<string, T>();
		for (const item of items) {
			map.set(item.id, item);
		}
		return map;
	}

	private flatten_scenes(chapters: PersistedChapter[]): Map<string, SceneDocument> {
		const map = new Map<string, SceneDocument>();
		for (const chapter of chapters) {
			for (const scene of chapter.scenes) {
				map.set(scene.id, {
					...scene,
					chapterId: chapter.id
				});
			}
		}
		return map;
	}

	private is_equal(a: unknown, b: unknown): boolean {
		return JSON.stringify(a) === JSON.stringify(b);
	}
}

export const project_store = new ProjectStore();
