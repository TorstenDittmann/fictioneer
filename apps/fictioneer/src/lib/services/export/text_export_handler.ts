import type { Project } from '../projects.svelte.js';
import type { ExportOptions } from './types.js';
import { BaseExportHandler } from './base_export_handler.js';

/**
 * Convert HTML content to plain text
 */
function html_to_text(html: string): string {
	return html
		.replace(/<p[^>]*>/gi, '')
		.replace(/<\/p>/gi, '\n\n')
		.replace(/<br\s*\/?>/gi, '\n')
		.replace(/<h1[^>]*>/gi, '\n\n=== ')
		.replace(/<\/h1>/gi, ' ===\n\n')
		.replace(/<h2[^>]*>/gi, '\n\n--- ')
		.replace(/<\/h2>/gi, ' ---\n\n')
		.replace(/<h3[^>]*>/gi, '\n\n• ')
		.replace(/<\/h3>/gi, '\n\n')
		.replace(/<strong[^>]*>/gi, '**')
		.replace(/<\/strong>/gi, '**')
		.replace(/<b[^>]*>/gi, '**')
		.replace(/<\/b>/gi, '**')
		.replace(/<em[^>]*>/gi, '*')
		.replace(/<\/em>/gi, '*')
		.replace(/<i[^>]*>/gi, '*')
		.replace(/<\/i>/gi, '*')
		.replace(/<u[^>]*>/gi, '_')
		.replace(/<\/u>/gi, '_')
		.replace(/<ul[^>]*>/gi, '\n')
		.replace(/<\/ul>/gi, '\n')
		.replace(/<ol[^>]*>/gi, '\n')
		.replace(/<\/ol>/gi, '\n')
		.replace(/<li[^>]*>/gi, '\n• ')
		.replace(/<\/li>/gi, '')
		.replace(/<blockquote[^>]*>/gi, '\n> ')
		.replace(/<\/blockquote>/gi, '\n')
		.replace(/<div[^>]*>/gi, '')
		.replace(/<\/div>/gi, '\n')
		.replace(/<span[^>]*>/gi, '')
		.replace(/<\/span>/gi, '')
		.replace(/&nbsp;/gi, ' ')
		.replace(/&amp;/gi, '&')
		.replace(/&lt;/gi, '<')
		.replace(/&gt;/gi, '>')
		.replace(/&quot;/gi, '"')
		.replace(/&apos;/gi, "'")
		.replace(/\s+/g, ' ')
		.trim();
}

export class TextExportHandler extends BaseExportHandler {
	get_file_extension(): string {
		return 'txt';
	}

	get_mime_type(): string {
		return 'text/plain';
	}

	get_filter_name(): string {
		return 'Text Files';
	}

	/**
	 * Export project to plain text format
	 */
	async export(project: Project, options: ExportOptions): Promise<string> {
		console.log('Starting text export for project:', project.title);
		console.log('Export options:', options);

		let txt_content = '';

		if (options.include_title) {
			txt_content += project.title + '\n\n';
		}

		if (project.description) {
			txt_content += project.description + '\n\n';
		}

		for (const chapter of project.chapters) {
			if (options.include_chapter_titles) {
				txt_content += chapter.title.toUpperCase() + '\n\n';
			}

			for (const scene of chapter.scenes) {
				if (options.include_scene_titles) {
					txt_content += scene.title + '\n\n';
				}

				if (scene.content.trim()) {
					// Convert HTML content to plain text
					const text_content = html_to_text(scene.content);
					txt_content += text_content + '\n\n';
				}

				if (options.include_word_count) {
					txt_content += `Words: ${scene.wordCount}\n\n`;
				}
			}
		}

		console.log('Text export completed. Content length:', txt_content.length);
		return txt_content;
	}
}
