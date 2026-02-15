import type { Project, Chapter, Scene } from '../../projects.svelte.js';
import type { ExportOptions } from '../types.js';

export interface EpubFile {
	path: string;
	content: string;
	media_type?: string;
}

export interface EpubManifestItem {
	id: string;
	href: string;
	media_type: string;
	properties?: string;
}

export interface EpubSpineItem {
	idref: string;
	linear?: boolean;
}

export interface EpubTocEntry {
	id: string;
	title: string;
	href: string;
	level: number;
	children?: EpubTocEntry[];
}

export interface EpubMetadata {
	title: string;
	author: string;
	language: string;
	identifier: string;
	description?: string;
	publisher?: string;
	date?: string;
	subject?: string[];
	rights?: string;
}

export interface EpubTemplateContext {
	project: Project;
	options: ExportOptions;
	metadata: EpubMetadata;
	manifest_items: EpubManifestItem[];
	spine_items: EpubSpineItem[];
	toc_entries: EpubTocEntry[];
	files: EpubFile[];
}

export interface EpubTemplate {
	readonly name: string;
	readonly description: string;

	generate_metadata(project: Project): EpubMetadata;
	generate_files(context: EpubTemplateContext): Promise<EpubFile[]>;
	get_css(): string;
}

export interface EpubTemplateDefinition {
	key: string;
	name: string;
	description: string;
}

export interface ChapterData {
	chapter: Chapter;
	scenes: Scene[];
	chapter_number: number;
	total_chapters: number;
}

export interface SceneData {
	scene: Scene;
	scene_number: number;
	total_scenes: number;
	chapter_number: number;
}
