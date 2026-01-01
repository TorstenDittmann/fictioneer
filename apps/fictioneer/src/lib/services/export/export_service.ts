import type { Project } from '../projects.svelte.js';
import type { ExportOptions, ExportHandler } from './types.js';
import { RtfExportHandler } from './rtf_export_handler.js';
import { TextExportHandler } from './text_export_handler.js';
import { EpubExportHandler } from './epub_export_handler.js';

class ExportService {
	private handlers: Map<string, ExportHandler> = new Map();

	constructor() {
		this.register_handler('rtf', new RtfExportHandler());
		this.register_handler('txt', new TextExportHandler());
		this.register_handler('epub', new EpubExportHandler());
	}

	/**
	 * Register a new export handler
	 */
	register_handler(format: string, handler: ExportHandler): void {
		this.handlers.set(format, handler);
	}

	/**
	 * Get available export formats
	 */
	get_available_formats(): string[] {
		return Array.from(this.handlers.keys());
	}

	/**
	 * Export project with given options
	 */
	async export_project(project: Project, options: ExportOptions): Promise<void> {
		if (!project) {
			throw new Error('No project provided for export');
		}

		const handler = this.handlers.get(options.format);
		if (!handler) {
			throw new Error(`Unsupported export format: ${options.format}`);
		}

		await handler.export_and_download(project, options);
	}

	/**
	 * Export project and return content without downloading
	 */
	async export_content(project: Project, options: ExportOptions): Promise<string> {
		if (!project) {
			throw new Error('No project provided for export');
		}

		const handler = this.handlers.get(options.format);
		if (!handler) {
			throw new Error(`Unsupported export format: ${options.format}`);
		}

		return await handler.export(project, options);
	}

	/**
	 * Get handler for specific format
	 */
	get_handler(format: string): ExportHandler | undefined {
		return this.handlers.get(format);
	}
}

export const export_service = new ExportService();
