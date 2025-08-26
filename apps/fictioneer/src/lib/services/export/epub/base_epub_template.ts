import type { Project, Chapter } from '../../projects.svelte.js';
import type {
	EpubTemplate,
	EpubMetadata,
	EpubFile,
	EpubTocEntry,
	EpubTemplateContext,
	ChapterData,
	SceneData
} from './types.js';

export abstract class BaseEpubTemplate implements EpubTemplate {
	abstract readonly name: string;
	abstract readonly description: string;
	abstract get_css(): string;

	/**
	 * Generate default metadata for the project
	 */
	generate_metadata(project: Project): EpubMetadata {
		return {
			title: project.title,
			author: 'Unknown Author',
			language: 'en',
			identifier: `urn:uuid:${this.generate_uuid()}`,
			description: project.description || undefined,
			publisher: 'Fictioneer',
			date: new Date().toISOString().split('T')[0],
			subject: undefined,
			rights: 'All rights reserved'
		};
	}

	/**
	 * Generate EPUB files - must be implemented by subclasses
	 */
	abstract generate_files(context: EpubTemplateContext): Promise<EpubFile[]>;

	/**
	 * Generate container.xml file
	 */
	protected generate_container_xml(): string {
		return `<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
	<rootfiles>
		<rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
	</rootfiles>
</container>`;
	}

	/**
	 * Generate content.opf package file
	 */
	protected generate_content_opf(context: EpubTemplateContext): string {
		const { metadata, manifest_items, spine_items } = context;

		const manifest_xml = manifest_items
			.map(
				(item) =>
					`		<item id="${item.id}" href="${item.href}" media-type="${item.media_type}"${item.properties ? ` properties="${item.properties}"` : ''}/>`
			)
			.join('\n');

		const spine_xml = spine_items
			.map(
				(item) => `		<itemref idref="${item.idref}"${item.linear === false ? ' linear="no"' : ''}/>`
			)
			.join('\n');

		return `<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" unique-identifier="BookId" version="3.0">
	<metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
		<dc:identifier id="BookId">${metadata.identifier}</dc:identifier>
		<dc:title>${this.escape_xml(metadata.title)}</dc:title>
		<dc:creator>${this.escape_xml(metadata.author)}</dc:creator>
		<dc:language>${metadata.language}</dc:language>
		${metadata.description ? `<dc:description>${this.escape_xml(metadata.description)}</dc:description>` : ''}
		${metadata.publisher ? `<dc:publisher>${this.escape_xml(metadata.publisher)}</dc:publisher>` : ''}
		${metadata.date ? `<dc:date>${metadata.date}</dc:date>` : ''}
		${metadata.subject ? metadata.subject.map((s) => `<dc:subject>${this.escape_xml(s)}</dc:subject>`).join('\n\t\t') : ''}
		${metadata.rights ? `<dc:rights>${this.escape_xml(metadata.rights)}</dc:rights>` : ''}
		<meta property="dcterms:modified">${new Date().toISOString().replace(/\.\d{3}Z$/, 'Z')}</meta>
	</metadata>
	<manifest>
${manifest_xml}
	</manifest>
	<spine>
${spine_xml}
	</spine>
</package>`;
	}

	/**
	 * Generate toc.ncx navigation file
	 */
	protected generate_toc_ncx(context: EpubTemplateContext): string {
		const { metadata, toc_entries } = context;

		const nav_points = this.generate_nav_points(toc_entries, 1);

		return `<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
	<head>
		<meta name="dtb:uid" content="${metadata.identifier}"/>
		<meta name="dtb:depth" content="2"/>
		<meta name="dtb:totalPageCount" content="0"/>
		<meta name="dtb:maxPageNumber" content="0"/>
	</head>
	<docTitle>
		<text>${this.escape_xml(metadata.title)}</text>
	</docTitle>
	<navMap>
${nav_points}
	</navMap>
</ncx>`;
	}

	/**
	 * Generate navigation points for toc.ncx
	 */
	private generate_nav_points(entries: EpubTocEntry[], play_order: number): string {
		let result = '';
		let current_order = play_order;

		for (const entry of entries) {
			result += `		<navPoint id="${entry.id}" playOrder="${current_order}">
			<navLabel>
				<text>${this.escape_xml(entry.title)}</text>
			</navLabel>
			<content src="${entry.href}"/>
`;
			current_order++;

			if (entry.children && entry.children.length > 0) {
				const child_points = this.generate_nav_points(entry.children, current_order);
				result += child_points;
				current_order += entry.children.length;
			}

			result += '		</navPoint>\n';
		}

		return result;
	}

	/**
	 * Generate nav.xhtml navigation file (EPUB 3)
	 */
	protected generate_nav_xhtml(context: EpubTemplateContext): string {
		const { toc_entries } = context;

		const nav_list = this.generate_nav_list(toc_entries);

		return `<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
<head>
	<title>Navigation</title>
	<meta charset="utf-8"/>
	<link rel="stylesheet" type="text/css" href="stylesheet.css"/>
</head>
<body>
	<nav epub:type="toc" id="toc">
		<h2>Table of Contents</h2>
		<ol>
${nav_list}
		</ol>
	</nav>
</body>
</html>`;
	}

	/**
	 * Generate navigation list for nav.xhtml
	 */
	private generate_nav_list(entries: EpubTocEntry[], indent: string = '\t\t\t'): string {
		let result = '';

		for (const entry of entries) {
			result += `${indent}<li><a href="${entry.href}">${this.escape_html(entry.title)}</a>`;

			if (entry.children && entry.children.length > 0) {
				result += '\n' + indent + '\t<ol>\n';
				result += this.generate_nav_list(entry.children, indent + '\t\t');
				result += indent + '\t</ol>\n' + indent;
			}

			result += '</li>\n';
		}

		return result;
	}

	/**
	 * Convert HTML content to EPUB-compatible XHTML
	 */
	protected html_to_xhtml(html: string): string {
		return html
			.replace(/<br\s*\/?>/gi, '<br/>')
			.replace(/<img([^>]*?)(?:\s*\/)?>/gi, '<img$1/>')
			.replace(/<hr\s*\/?>/gi, '<hr/>')
			.replace(/<meta([^>]*?)(?:\s*\/)?>/gi, '<meta$1/>')
			.replace(/<link([^>]*?)(?:\s*\/)?>/gi, '<link$1/>')
			.replace(/&(?!amp;|lt;|gt;|quot;|apos;|#)/g, '&amp;');
	}

	/**
	 * Escape XML content
	 */
	protected escape_xml(text: string): string {
		return text
			.replace(/&/g, '&amp;')
			.replace(/</g, '&lt;')
			.replace(/>/g, '&gt;')
			.replace(/"/g, '&quot;')
			.replace(/'/g, '&apos;');
	}

	/**
	 * Escape HTML content
	 */
	protected escape_html(text: string): string {
		return text
			.replace(/&/g, '&amp;')
			.replace(/</g, '&lt;')
			.replace(/>/g, '&gt;')
			.replace(/"/g, '&quot;');
	}

	/**
	 * Generate a simple UUID v4
	 */
	protected generate_uuid(): string {
		return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
			const r = (Math.random() * 16) | 0;
			const v = c == 'x' ? r : (r & 0x3) | 0x8;
			return v.toString(16);
		});
	}

	/**
	 * Sanitize filename for EPUB
	 */
	protected sanitize_filename(filename: string): string {
		return filename
			.replace(/[^a-zA-Z0-9\-_.]/g, '_')
			.replace(/_+/g, '_')
			.replace(/^_|_$/g, '');
	}

	/**
	 * Get chapter data with numbering
	 */
	protected get_chapter_data(project: Project): ChapterData[] {
		return project.chapters.map((chapter, index) => ({
			chapter,
			scenes: chapter.scenes,
			chapter_number: index + 1,
			total_chapters: project.chapters.length
		}));
	}

	/**
	 * Get scene data with numbering
	 */
	protected get_scene_data(chapter: Chapter, chapter_number: number): SceneData[] {
		return chapter.scenes.map((scene, index) => ({
			scene,
			scene_number: index + 1,
			total_scenes: chapter.scenes.length,
			chapter_number
		}));
	}

	/**
	 * Calculate word count for content
	 */
	protected count_words(html: string): number {
		const text = html
			.replace(/<[^>]*>/g, ' ')
			.replace(/\s+/g, ' ')
			.trim();
		return text ? text.split(' ').length : 0;
	}
}
