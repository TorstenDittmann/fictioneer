import type { Project } from './projects.svelte.js';
import { save } from '@tauri-apps/plugin-dialog';
import { invoke } from '@tauri-apps/api/core';

/**
 * Convert HTML content to RTF format
 */
function html_to_rtf(html: string): string {
	// First, escape special characters in the text content
	let text = html
		.replace(/&nbsp;/gi, ' ')
		.replace(/&amp;/gi, '&')
		.replace(/&lt;/gi, '<')
		.replace(/&gt;/gi, '>')
		.replace(/&quot;/gi, '"')
		.replace(/&apos;/gi, "'");

	// Escape RTF special characters in text content only
	text = text
		.replace(/\\/g, '\\\\')
		.replace(/{/g, '\\{')
		.replace(/}/g, '\\}')
		.replace(/—/g, '\\u8212?')
		.replace(/–/g, '\\u8211?')
		.replace(/"/g, '\\u8220?')
		.replace(/"/g, '\\u8221?')
		.replace(/'/g, '\\u8216?')
		.replace(/'/g, '\\u8217?')
		.replace(/…/g, '\\u8230?');

	// Now convert HTML tags to RTF codes
	text = text
		.replace(/<p[^>]*>/gi, '\\pard\\plain\\f0\\fs24 ')
		.replace(/<\/p>/gi, '\\par ')
		.replace(/<br\s*\/?>/gi, '\\par ')
		.replace(/<h1[^>]*>/gi, '\\pard\\plain\\f0\\fs36\\b\\qc ')
		.replace(/<\/h1>/gi, '\\par\\pard\\plain\\f0\\fs24\\par ')
		.replace(/<h2[^>]*>/gi, '\\pard\\plain\\f0\\fs32\\b ')
		.replace(/<\/h2>/gi, '\\par\\pard\\plain\\f0\\fs24\\par ')
		.replace(/<h3[^>]*>/gi, '\\pard\\plain\\f0\\fs28\\b ')
		.replace(/<\/h3>/gi, '\\par\\pard\\plain\\f0\\fs24\\par ')
		.replace(/<strong[^>]*>/gi, '\\b ')
		.replace(/<\/strong>/gi, '\\b0 ')
		.replace(/<b[^>]*>/gi, '\\b ')
		.replace(/<\/b>/gi, '\\b0 ')
		.replace(/<em[^>]*>/gi, '\\i ')
		.replace(/<\/em>/gi, '\\i0 ')
		.replace(/<i[^>]*>/gi, '\\i ')
		.replace(/<\/i>/gi, '\\i0 ')
		.replace(/<u[^>]*>/gi, '\\ul ')
		.replace(/<\/u>/gi, '\\ul0 ')
		.replace(/<ul[^>]*>/gi, '\\pard\\plain\\f0\\fs24 ')
		.replace(/<\/ul>/gi, '\\par\\pard\\plain\\f0\\fs24 ')
		.replace(/<ol[^>]*>/gi, '\\pard\\plain\\f0\\fs24 ')
		.replace(/<\/ol>/gi, '\\par\\pard\\plain\\f0\\fs24 ')
		.replace(/<li[^>]*>/gi, '\\tab ')
		.replace(/<\/li>/gi, '\\par ')
		.replace(/<blockquote[^>]*>/gi, '\\pard\\plain\\f0\\fs24\\li720\\fi-720\\qj ')
		.replace(/<\/blockquote>/gi, '\\par\\pard\\plain\\f0\\fs24 ')
		.replace(/<div[^>]*>/gi, '')
		.replace(/<\/div>/gi, '\\par ')
		.replace(/<span[^>]*>/gi, '')
		.replace(/<\/span>/gi, '')
		.replace(/\s+/g, ' ')
		.trim();

	return text;
}

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

export interface ExportOptions {
	include_title: boolean;
	include_chapter_titles: boolean;
	include_scene_titles: boolean;
	include_word_count: boolean;
	format: 'rtf' | 'txt';
}

class ExportService {
	/**
	 * Export project to RTF format
	 */
	async export_to_rtf(project: Project, options: ExportOptions): Promise<string> {
		console.log('Starting RTF export for project:', project.title);
		console.log('Export options:', options);

		// Build RTF content step by step
		const rtf_parts: string[] = [];

		// Add RTF header
		rtf_parts.push('{\\rtf1\\ansi\\ansicpg1252\\uc1\\deff0\\deflang1033');
		rtf_parts.push('{\\fonttbl{\\f0\\fnil\\fcharset0 Times New Roman;}}');
		rtf_parts.push('{\\colortbl;\\red0\\green0\\blue0;}');
		rtf_parts.push('\\f0\\fs24');

		// Add title if requested
		if (options.include_title) {
			rtf_parts.push('\\pard\\plain\\f0\\fs36\\b\\qc ');
			rtf_parts.push(this.create_rtf_text(project.title));
			rtf_parts.push('\\par\\pard\\plain\\f0\\fs24\\par');
		}

		// Add description if exists
		if (project.description) {
			rtf_parts.push(this.create_rtf_text(project.description));
			rtf_parts.push('\\par\\par');
		}

		// Add chapters and scenes
		for (const chapter of project.chapters) {
			if (options.include_chapter_titles) {
				rtf_parts.push('\\pard\\plain\\f0\\fs32\\b ');
				rtf_parts.push(this.create_rtf_text(chapter.title));
				rtf_parts.push('\\par\\pard\\plain\\f0\\fs24\\par');
			}

			for (const scene of chapter.scenes) {
				if (options.include_scene_titles) {
					rtf_parts.push('\\pard\\plain\\f0\\fs28\\b ');
					rtf_parts.push(this.create_rtf_text(scene.title));
					rtf_parts.push('\\par\\pard\\plain\\f0\\fs24\\par');
				}

				if (scene.content.trim()) {
					// Convert HTML content to RTF
					const rtf_content = html_to_rtf(scene.content);
					rtf_parts.push('\\pard\\plain\\f0\\fs24 ');
					rtf_parts.push(rtf_content);
					rtf_parts.push('\\par\\par');
				}

				if (options.include_word_count) {
					rtf_parts.push('{\\i Words: ');
					rtf_parts.push(scene.wordCount.toString());
					rtf_parts.push('}');
					rtf_parts.push('\\par');
				}

				rtf_parts.push('\\par');
			}
		}

		// Close RTF document
		rtf_parts.push('}');

		const rtf_content = rtf_parts.join('');
		console.log('RTF export completed. Content length:', rtf_content.length);
		console.log('RTF content preview:', rtf_content.substring(0, 200));
		return rtf_content;
	}

	/**
	 * Export project to plain text format
	 */
	async export_to_txt(project: Project, options: ExportOptions): Promise<string> {
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

		return txt_content;
	}

	/**
	 * Download content as a file using Tauri command
	 */
	async download_file(content: string, filename: string, mime_type: string): Promise<void> {
		console.log('Starting file download with Tauri command');
		console.log('Filename:', filename);
		console.log('MIME type:', mime_type);
		console.log('Content length:', content.length);

		try {
			// Use Tauri's save dialog to let user choose save location
			const filePath = await save({
				defaultPath: filename,
				filters: [
					{
						name: mime_type === 'text/rtf' ? 'RTF Files' : 'Text Files',
						extensions: mime_type === 'text/rtf' ? ['rtf'] : ['txt']
					}
				]
			});

			if (!filePath) {
				console.log('User cancelled save dialog');
				return;
			}

			console.log('File path selected:', filePath);

			// Use the Tauri command to save the file
			await invoke('save_export_file', {
				path: filePath,
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
	 * Export project with given options
	 */
	async export_project(project: Project, options: ExportOptions): Promise<void> {
		console.log('Starting project export');
		console.log('Project:', project.title);
		console.log('Options:', options);

		if (!project) {
			throw new Error('No project provided for export');
		}

		let content: string;
		let filename: string;
		let mime_type: string;

		try {
			if (options.format === 'rtf') {
				console.log('Exporting to RTF format');
				content = await this.export_to_rtf(project, options);
				filename = `${project.title.replace(/[^a-z0-9]/gi, '_').toLowerCase()}.rtf`;
				mime_type = 'text/rtf';
			} else {
				console.log('Exporting to TXT format');
				content = await this.export_to_txt(project, options);
				filename = `${project.title.replace(/[^a-z0-9]/gi, '_').toLowerCase()}.txt`;
				mime_type = 'text/plain';
			}

			console.log('Content generated, starting download');
			console.log('Final filename:', filename);
			console.log('Final MIME type:', mime_type);

			await this.download_file(content, filename, mime_type);
			console.log('Project export completed successfully');
		} catch (error) {
			console.error('Project export failed:', error);
			throw error;
		}
	}

	// RTF helper methods
	private create_rtf_header(): string {
		return '{\\rtf1\\ansi\\ansicpg1252\\uc1\\deff0\\deflang1033{\\fonttbl{\\f0\\fnil\\fcharset0 Times New Roman;}}{\\colortbl;\\red0\\green0\\blue0;}\\f0\\fs24';
	}

	private create_rtf_footer(): string {
		return '}';
	}

	private create_rtf_paragraph(): string {
		return '\\par\\pard\\plain\\f0\\fs24 ';
	}

	private create_rtf_text(text: string, italic: boolean = false): string {
		// Text should already be escaped by html_to_rtf function
		let escaped_text = text;

		// Only handle line breaks and tabs if they exist
		escaped_text = escaped_text.replace(/\n/g, '\\par ').replace(/\t/g, '\\tab ');

		if (italic) {
			return `{\\i ${escaped_text}}`;
		}
		return escaped_text;
	}

	private create_rtf_title(text: string): string {
		return `\\pard\\plain\\f0\\fs36\\b\\qc ${this.create_rtf_text(text)}\\par\\pard\\plain\\f0\\fs24\\par `;
	}

	private create_rtf_heading(text: string, level: number): string {
		const font_size = level === 1 ? '\\fs32' : '\\fs28';
		return `\\pard\\plain\\f0${font_size}\\b ${this.create_rtf_text(text)}\\par\\pard\\plain\\f0\\fs24\\par `;
	}
}

export const export_service = new ExportService();
