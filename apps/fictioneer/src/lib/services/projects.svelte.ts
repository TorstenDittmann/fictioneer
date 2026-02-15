import { file_service } from './file.svelte.js';
import { progress_service } from './progress.svelte.js';
import type { ProgressGoals, DailyProgress, ProgressStats } from '../types/progress.js';
import { SvelteDate } from 'svelte/reactivity';
import { generate_id } from '../utils.js';

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
	tags: string[];
}

export interface ProjectEpubMetadata {
	author: string;
	publisher: string;
	language: string;
	rights: string;
	subjects: string[];
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
	lastSessionTime?: number;
	epub_metadata?: ProjectEpubMetadata;
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
			// Initialize progress tracking with default goals
			this.initialize_progress_tracking(project);
		}
		return project;
	}

	/**
	 * Create an example project with public domain content
	 */
	async create_example_project(file_path: string): Promise<Project | null> {
		const project = await file_service.create_example_project(file_path);
		if (project) {
			this.current_project = project;
			// Initialize progress tracking with default goals
			this.initialize_progress_tracking(project);
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
			// Ensure progress tracking is initialized for existing projects
			this.ensure_progress_tracking_initialized(project);
		}
		return project;
	}

	/**
	 * Save the current project (manual save - bypasses throttling)
	 */
	async save_project(): Promise<boolean> {
		if (!this.current_project) return false;
		return await file_service.force_save_project(this.current_project);
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
		// Flush any pending saves before closing
		await file_service.flush_pending_saves();

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

		const chapter_id = generate_id('chapter');
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

		const scene_id = generate_id('scene');
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
		const success = this.update_current_project((project) => {
			const chapter = project.chapters.find((c) => c.id === chapter_id);
			if (!chapter) return;

			const scene_index = chapter.scenes.findIndex((scene) => scene.id === scene_id);
			if (scene_index === -1) return;

			const previous_word_count = chapter.scenes[scene_index].wordCount;

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

			// Handle progress tracking for content updates
			if (updates.content !== undefined) {
				// Initialize daily snapshot if this is the first edit of the day
				this.initialize_daily_snapshot_if_needed(project);

				// If word count changed, update progress
				if (updated_scene.wordCount !== previous_word_count) {
					this.update_daily_progress(project);
				}

				// Track writing session if this is a meaningful content change
				if (
					this.is_meaningful_content_change(updates.content, chapter.scenes[scene_index].content)
				) {
					this.track_writing_session(project);
				}
			}
		});

		return success;
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

		const note_id = generate_id('note');
		const now = new Date();

		const new_note: Note = {
			id: note_id,
			title,
			description,
			createdAt: now,
			updatedAt: now,
			order: this.current_project.notes?.length || 0,
			tags: []
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
	 * Add a tag to a note
	 */
	add_note_tag(note_id: string, tag: string): boolean {
		return this.update_current_project((project) => {
			if (!project.notes) return;

			const note = project.notes.find((n) => n.id === note_id);
			if (!note) return;

			const normalized_tag = tag.trim().toLowerCase();
			if (!normalized_tag || note.tags.includes(normalized_tag)) return;

			note.tags.push(normalized_tag);
			note.updatedAt = new Date();
		});
	}

	/**
	 * Remove a tag from a note
	 */
	remove_note_tag(note_id: string, tag: string): boolean {
		return this.update_current_project((project) => {
			if (!project.notes) return;

			const note = project.notes.find((n) => n.id === note_id);
			if (!note) return;

			const normalized_tag = tag.trim().toLowerCase();
			note.tags = note.tags.filter((t) => t !== normalized_tag);
			note.updatedAt = new Date();
		});
	}

	/**
	 * Get all unique tags across all notes
	 */
	get_all_tags(): string[] {
		if (!this.current_project || !this.current_project.notes) return [];

		// eslint-disable-next-line svelte/prefer-svelte-reactivity -- Not reactive state, just local computation
		const tags_set = new Set<string>();
		for (const note of this.current_project.notes) {
			for (const tag of note.tags) {
				tags_set.add(tag);
			}
		}
		return Array.from(tags_set).sort();
	}

	/**
	 * Get notes by tag
	 */
	get_notes_by_tag(tag: string): Note[] {
		if (!this.current_project || !this.current_project.notes) return [];

		const normalized_tag = tag.trim().toLowerCase();
		return this.current_project.notes.filter((note) => note.tags.includes(normalized_tag));
	}

	/**
	 * Find notes whose tags appear in the given content
	 * This automatically matches notes based on their tags appearing in scene content
	 */
	find_notes_by_content(content: string): Note[] {
		if (!this.current_project || !this.current_project.notes) return [];

		// Strip HTML and normalize content for matching
		const text_content = this.strip_html(content).toLowerCase();

		// Find all notes that have at least one tag appearing in the content
		const matched_notes: Note[] = [];

		for (const note of this.current_project.notes) {
			if (!note.tags || note.tags.length === 0) continue;

			// Check if any of the note's tags appear in the content
			const has_matching_tag = note.tags.some((tag) => {
				// Use word boundary matching to avoid partial matches
				const tag_regex = new RegExp(`\\b${this.escape_regex(tag)}\\b`, 'i');
				return tag_regex.test(text_content);
			});

			if (has_matching_tag) {
				matched_notes.push(note);
			}
		}

		return matched_notes;
	}

	/**
	 * Escape special regex characters in a string
	 */
	private escape_regex(str: string): string {
		return str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
	}

	/**
	 * Get a note by ID
	 */
	get_note(note_id: string): Note | null {
		if (!this.current_project || !this.current_project.notes) return null;
		return this.current_project.notes.find((note) => note.id === note_id) || null;
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
				: 'Fictioneer'
		};
	}

	/**
	 * Check if a project is currently loaded
	 */
	has_project(): boolean {
		return this.current_project !== null;
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
	 * Trigger auto-save (throttled)
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
			// Ensure progress tracking is initialized for existing projects
			this.ensure_progress_tracking_initialized(project);
		}
		return project;
	}

	// Progress tracking methods

	/**
	 * Set daily word count goal for the current project
	 */
	set_daily_goal(word_target: number): boolean {
		if (!this.current_project) return false;

		const success = progress_service.setDailyGoal(this.current_project, word_target);
		if (success) {
			this.current_project.updatedAt = new Date();
			file_service.mark_as_modified();
			this.trigger_auto_save();
		}
		return success;
	}

	/**
	 * Set project-level word count goal for the current project
	 */
	set_project_goal(word_target: number): boolean {
		if (!this.current_project) return false;

		const success = progress_service.setProjectGoal(this.current_project, word_target);
		if (success) {
			this.current_project.updatedAt = new Date();
			file_service.mark_as_modified();
			this.trigger_auto_save();
		}
		return success;
	}

	/**
	 * Get today's progress for the current project
	 */
	get_todays_progress(): DailyProgress | null {
		if (!this.current_project) return null;
		return progress_service.getTodaysProgress(this.current_project);
	}

	/**
	 * Get daily progress for the last N days
	 */
	get_daily_progress(days: number = 30): DailyProgress[] {
		if (!this.current_project) return [];
		return progress_service.getDailyProgress(this.current_project, days);
	}

	/**
	 * Get progress statistics for the current project
	 */
	get_progress_stats(): ProgressStats | null {
		if (!this.current_project) return null;
		return this.current_project.progressStats || null;
	}

	/**
	 * Get progress goals for the current project
	 */
	get_progress_goals(): ProgressGoals | null {
		if (!this.current_project) return null;
		return this.current_project.progressGoals || null;
	}

	/**
	 * Get chart data for progress visualization
	 */
	get_chart_data(days: number = 30) {
		if (!this.current_project) return [];
		return progress_service.getChartData(this.current_project, days);
	}

	/**
	 * Force update of daily progress (useful for real-time updates)
	 */
	refresh_daily_progress(): boolean {
		if (!this.current_project) return false;

		this.update_daily_progress(this.current_project);
		this.current_project.updatedAt = new Date();
		file_service.mark_as_modified();
		this.trigger_auto_save();

		return true;
	}

	/**
	 * Get real-time progress data for today
	 */
	get_realtime_progress() {
		if (!this.current_project) return null;

		const today = new Date().toISOString().split('T')[0];
		const current_total = this.calculate_total_project_words(this.current_project);
		const starting_count = this.get_starting_word_count_for_today(this.current_project);
		const words_today = Math.max(0, current_total - starting_count);
		const daily_goal = this.current_project.progressGoals?.dailyWordTarget || 500;

		return {
			date: today,
			wordsWritten: words_today,
			goalTarget: daily_goal,
			goalMet: words_today >= daily_goal,
			percentage: Math.min(100, Math.round((words_today / daily_goal) * 100)),
			totalProjectWords: current_total
		};
	}

	/**
	 * Update daily progress based on current project word count
	 */
	private update_daily_progress(project: Project): void {
		const today = new Date().toISOString().split('T')[0];
		const current_total_words = this.calculate_total_project_words(project);

		// Get today's starting word count (total at start of day)
		const today_starting_count = this.get_starting_word_count_for_today(project);

		// Calculate words written today
		const words_written_today = Math.max(0, current_total_words - today_starting_count);

		// Update daily progress
		progress_service.updateDailyProgress(project, today, words_written_today);

		// Store current total for future reference
		this.store_daily_word_count_snapshot(project, today, current_total_words);
	}

	/**
	 * Calculate total word count for the project
	 */
	private calculate_total_project_words(project: Project): number {
		let total = 0;
		for (const chapter of project.chapters) {
			for (const scene of chapter.scenes) {
				total += scene.wordCount;
			}
		}
		return total;
	}

	/**
	 * Get the starting word count for today (total words at start of day)
	 */
	private get_starting_word_count_for_today(project: Project): number {
		const today = new Date().toISOString().split('T')[0];

		// Check if we have a stored snapshot for today
		const today_snapshot = this.get_daily_word_count_snapshot(project, today);
		if (today_snapshot !== null) {
			return today_snapshot;
		}

		// If no snapshot for today, calculate from yesterday's ending total
		const yesterday = new SvelteDate();
		yesterday.setDate(yesterday.getDate() - 1);
		const yesterday_date = yesterday.toISOString().split('T')[0];

		const yesterday_snapshot = this.get_daily_word_count_snapshot(project, yesterday_date);
		return yesterday_snapshot !== null ? yesterday_snapshot : 0;
	}

	/**
	 * Store a daily word count snapshot for tracking daily differences
	 */
	private store_daily_word_count_snapshot(
		project: Project,
		date: string,
		total_words: number
	): void {
		// Store in a special property for tracking daily snapshots
		if (!project.dailyWordSnapshots) {
			project.dailyWordSnapshots = {};
		}
		project.dailyWordSnapshots[date] = total_words;
	}

	/**
	 * Get stored daily word count snapshot
	 */
	private get_daily_word_count_snapshot(project: Project, date: string): number | null {
		const snapshots = project.dailyWordSnapshots;
		if (!snapshots || !(date in snapshots)) {
			return null;
		}
		return snapshots[date];
	}

	/**
	 * Initialize daily word count snapshot for today if not exists
	 */
	private initialize_daily_snapshot_if_needed(project: Project): void {
		const today = new Date().toISOString().split('T')[0];
		const current_total = this.calculate_total_project_words(project);

		// Only initialize if we don't have a snapshot for today yet
		if (this.get_daily_word_count_snapshot(project, today) === null) {
			this.store_daily_word_count_snapshot(project, today, current_total);
		}
	}

	/**
	 * Check if a content change is meaningful enough to count as a writing session
	 */
	private is_meaningful_content_change(new_content: string, old_content: string): boolean {
		// Strip HTML and get text content
		const new_text = this.strip_html(new_content).trim();
		const old_text = this.strip_html(old_content).trim();

		// Calculate word difference
		const new_word_count = this.count_words(new_text);
		const old_word_count = this.count_words(old_text);
		const word_difference = Math.abs(new_word_count - old_word_count);

		// Consider it meaningful if:
		// 1. At least 5 words were added/removed, OR
		// 2. At least 25 characters were added/removed
		const char_difference = Math.abs(new_text.length - old_text.length);

		return word_difference >= 5 || char_difference >= 25;
	}

	/**
	 * Track a writing session (increment session count for today)
	 */
	private track_writing_session(project: Project): void {
		// Use a simple throttling mechanism to avoid counting rapid successive edits as multiple sessions
		const now = Date.now();
		const last_session_time = project.lastSessionTime || 0;
		const session_threshold = 5 * 60 * 1000; // 5 minutes

		if (now - last_session_time > session_threshold) {
			progress_service.incrementSessionCount(project);
			project.lastSessionTime = now;
		}
	}

	/**
	 * Increment session count for today (called when user starts writing)
	 */
	increment_session_count(): boolean {
		if (!this.current_project) return false;

		const success = progress_service.incrementSessionCount(this.current_project);
		if (success) {
			this.current_project.updatedAt = new Date();
			file_service.mark_as_modified();
			this.trigger_auto_save();
		}
		return success;
	}

	/**
	 * Initialize progress tracking for a new project
	 */
	private initialize_progress_tracking(project: Project): void {
		const now = new Date();

		// Set default daily goal if not already set
		if (!project.progressGoals) {
			project.progressGoals = {
				dailyWordTarget: 500, // Default daily goal
				createdAt: now,
				updatedAt: now
			};
		}

		// Initialize empty progress arrays if not present
		if (!project.dailyProgress) {
			project.dailyProgress = [];
		}

		// Initialize daily word count snapshots
		if (!project.dailyWordSnapshots) {
			project.dailyWordSnapshots = {};
		}

		// Set up initial snapshot for today
		this.initialize_daily_snapshot_if_needed(project);

		// Calculate initial stats
		project.progressStats = progress_service.calculateProgressStats(project);
	}

	/**
	 * Ensure progress tracking is initialized for existing projects (backward compatibility)
	 */
	private ensure_progress_tracking_initialized(project: Project): void {
		let needs_save = false;

		// Initialize progress goals if missing
		if (!project.progressGoals) {
			const now = new Date();
			project.progressGoals = {
				dailyWordTarget: 500,
				createdAt: now,
				updatedAt: now
			};
			needs_save = true;
		}

		// Initialize progress arrays if missing
		if (!project.dailyProgress) {
			project.dailyProgress = [];
			needs_save = true;
		}

		// Initialize daily word count snapshots if missing
		if (!project.dailyWordSnapshots) {
			project.dailyWordSnapshots = {};
			needs_save = true;
		}

		// Set up initial snapshot for today if needed
		this.initialize_daily_snapshot_if_needed(project);

		// Recalculate stats to ensure they're up to date
		project.progressStats = progress_service.calculateProgressStats(project);

		if (needs_save) {
			project.updatedAt = new Date();
			file_service.mark_as_modified();
			this.trigger_auto_save();
		}
	}
}

// Export a singleton instance
export const projects_service = new ProjectsService();
