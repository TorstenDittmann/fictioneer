import type { Project } from '../projects.svelte.js';

export interface ExportOptions {
	include_title: boolean;
	include_chapter_titles: boolean;
	include_scene_titles: boolean;
	include_word_count: boolean;
	format: 'rtf' | 'txt' | 'epub';
	epub?: EpubExportOptions;
}

export interface EpubMetadataOptions {
	author?: string;
	publisher?: string;
	language?: string;
	rights?: string;
	subjects?: string[];
}

export interface EpubExportOptions {
	template_name?: string;
	metadata?: EpubMetadataOptions;
}

export interface ExportHandler {
	export(project: Project, options: ExportOptions): Promise<string>;
	export_and_download(project: Project, options: ExportOptions): Promise<void>;
	get_file_extension(): string;
	get_mime_type(): string;
	get_filter_name(): string;
}

export interface ExportResult {
	content: string;
	filename: string;
	mime_type: string;
}
