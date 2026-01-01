import type { Project } from '../projects.svelte.js';
import type { ExportOptions } from './types.js';
import type { EpubTemplate, EpubFile, EpubTemplateContext } from './epub/types.js';
import { BaseExportHandler } from './base_export_handler.js';
import { GenericNovelTemplate } from './epub/generic_novel_template.js';
import { invoke } from '@tauri-apps/api/core';
import JSZip from 'jszip';

export class EpubExportHandler extends BaseExportHandler {
	private templates: Map<string, EpubTemplate> = new Map();
	private default_template_name = 'generic_novel';

	constructor() {
		super();
		this.register_template('generic_novel', new GenericNovelTemplate());
	}

	get_file_extension(): string {
		return 'epub';
	}

	get_mime_type(): string {
		return 'application/epub+zip';
	}

	get_filter_name(): string {
		return 'EPUB Files';
	}

	/**
	 * Register a new EPUB template
	 */
	register_template(name: string, template: EpubTemplate): void {
		this.templates.set(name, template);
	}

	/**
	 * Get available template names
	 */
	get_available_templates(): string[] {
		return Array.from(this.templates.keys());
	}

	/**
	 * Get template by name
	 */
	get_template(name: string): EpubTemplate | undefined {
		return this.templates.get(name);
	}

	/**
	 * Set default template
	 */
	set_default_template(name: string): void {
		if (this.templates.has(name)) {
			this.default_template_name = name;
		} else {
			throw new Error(`Template '${name}' not found`);
		}
	}

	/**
	 * Export project to EPUB format
	 */
	async export(project: Project, options: ExportOptions): Promise<string> {
		const template = this.templates.get(this.default_template_name);
		if (!template) {
			throw new Error(`Default template '${this.default_template_name}' not found`);
		}

		// Generate metadata
		const metadata = template.generate_metadata(project);

		// Create initial context
		const context: EpubTemplateContext = {
			project,
			options,
			metadata,
			manifest_items: [],
			spine_items: [],
			toc_entries: [],
			files: []
		};

		// Generate all EPUB files
		const files = await template.generate_files(context);

		// Create EPUB zip archive
		return await this.create_epub_archive(files);
	}

	/**
	 * Create EPUB zip archive from files using JSZip
	 */
	private async create_epub_archive(files: EpubFile[]): Promise<string> {
		const zip = new JSZip();

		// Add mimetype file first (must be uncompressed)
		zip.file('mimetype', 'application/epub+zip', { compression: 'STORE' });

		// Add all other files
		for (const file of files) {
			zip.file(file.path, file.content);
		}

		// Generate the zip as base64
		return await zip.generateAsync({
			type: 'base64',
			compression: 'DEFLATE',
			compressionOptions: {
				level: 9
			}
		});
	}

	/**
	 * Export with specific template
	 */
	async export_with_template(
		project: Project,
		options: ExportOptions,
		template_name: string
	): Promise<string> {
		const template = this.templates.get(template_name);
		if (!template) {
			throw new Error(`Template '${template_name}' not found`);
		}

		// Generate metadata
		const metadata = template.generate_metadata(project);

		// Create context
		const context: EpubTemplateContext = {
			project,
			options,
			metadata,
			manifest_items: [],
			spine_items: [],
			toc_entries: [],
			files: []
		};

		// Generate files
		const files = await template.generate_files(context);

		// Create archive
		return await this.create_epub_archive(files);
	}

	/**
	 * Override download_file to handle binary EPUB data
	 */
	async download_file(content: string, filename: string): Promise<void> {
		// Use Tauri's save dialog to let user choose save location
		const { save } = await import('@tauri-apps/plugin-dialog');

		const file_path = await save({
			defaultPath: filename,
			filters: [
				{
					name: this.get_filter_name(),
					extensions: [this.get_file_extension()]
				}
			]
		});

		if (!file_path) {
			return;
		}

		// Convert base64 to binary and save using existing command
		await invoke('save_export_file_base64', {
			path: file_path,
			content: content
		});
	}
}
