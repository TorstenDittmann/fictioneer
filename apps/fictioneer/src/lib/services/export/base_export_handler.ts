import type { Project } from '../projects.svelte.js';
import type { ExportOptions, ExportHandler } from './types.js';
import { save } from '@tauri-apps/plugin-dialog';
import { invoke } from '@tauri-apps/api/core';

export abstract class BaseExportHandler implements ExportHandler {
	abstract export(project: Project, options: ExportOptions): Promise<string>;
	abstract get_file_extension(): string;
	abstract get_mime_type(): string;
	abstract get_filter_name(): string;

	/**
	 * Generate filename for export
	 */
	protected generate_filename(project: Project): string {
		const sanitized_title = project.title.replace(/[^a-z0-9]/gi, '_').toLowerCase();
		return `${sanitized_title}.${this.get_file_extension()}`;
	}

	/**
	 * Download content as a file using Tauri command
	 */
	async download_file(content: string, filename: string): Promise<void> {
		console.log('Starting file download with Tauri command');
		console.log('Filename:', filename);
		console.log('MIME type:', this.get_mime_type());
		console.log('Content length:', content.length);

		try {
			// Use Tauri's save dialog to let user choose save location
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
				console.log('User cancelled save dialog');
				return;
			}

			console.log('File path selected:', file_path);

			// Use the Tauri command to save the file
			await invoke('save_export_file', {
				path: file_path,
				contents: content
			});

			console.log('File saved successfully');
		} catch (error) {
			console.error('Error saving file:', error);
			throw new Error(
				`Failed to save file: ${error instanceof Error ? error.message : 'Unknown error'}`
			);
		}
	}

	/**
	 * Export project and download the file
	 */
	async export_and_download(project: Project, options: ExportOptions): Promise<void> {
		console.log('Starting project export');
		console.log('Project:', project.title);
		console.log('Options:', options);

		if (!project) {
			throw new Error('No project provided for export');
		}

		try {
			const content = await this.export(project, options);
			const filename = this.generate_filename(project);

			console.log('Content generated, starting download');
			console.log('Final filename:', filename);
			console.log('Final MIME type:', this.get_mime_type());

			await this.download_file(content, filename);
			console.log('Project export completed successfully');
		} catch (error) {
			console.error('Project export failed:', error);
			throw error;
		}
	}
}
