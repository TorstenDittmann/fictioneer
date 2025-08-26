import type { Project } from '../projects.svelte.js';
import type { ExportOptions } from './types.js';
import { BaseExportHandler } from './base_export_handler.js';

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

export class RtfExportHandler extends BaseExportHandler {
	get_file_extension(): string {
		return 'rtf';
	}

	get_mime_type(): string {
		return 'text/rtf';
	}

	get_filter_name(): string {
		return 'RTF Files';
	}

	/**
	 * Export project to RTF format
	 */
	async export(project: Project, options: ExportOptions): Promise<string> {
		console.log('Starting RTF export for project:', project.title);
		console.log('Export options:', options);

		// Build RTF content step by step
		const rtf_parts: string[] = [];

		// Add RTF header
		rtf_parts.push(this.create_rtf_header());

		// Add title if requested
		if (options.include_title) {
			rtf_parts.push(this.create_rtf_title(project.title));
		}

		// Add description if exists
		if (project.description) {
			rtf_parts.push(this.create_rtf_text(project.description));
			rtf_parts.push('\\par\\par');
		}

		// Add chapters and scenes
		for (const chapter of project.chapters) {
			if (options.include_chapter_titles) {
				rtf_parts.push(this.create_rtf_heading(chapter.title, 1));
			}

			for (const scene of chapter.scenes) {
				if (options.include_scene_titles) {
					rtf_parts.push(this.create_rtf_heading(scene.title, 2));
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
		rtf_parts.push(this.create_rtf_footer());

		const rtf_content = rtf_parts.join('');
		console.log('RTF export completed. Content length:', rtf_content.length);
		console.log('RTF content preview:', rtf_content.substring(0, 200));
		return rtf_content;
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
