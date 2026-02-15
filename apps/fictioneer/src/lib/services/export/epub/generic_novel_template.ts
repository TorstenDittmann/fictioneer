import type { ExportOptions } from '../types.js';
import type {
	EpubFile,
	EpubManifestItem,
	EpubSpineItem,
	EpubTocEntry,
	EpubTemplateContext,
	ChapterData,
	SceneData
} from './types.js';
import { BaseEpubTemplate } from './base_epub_template.js';
import { TemplateEngine } from './template_engine.js';

// Import template files as raw text
import stylesheetCss from './templates/generic_novel/stylesheet.css?raw';
import titlePageTemplate from './templates/generic_novel/title_page.xhtml?raw';
import chapterTemplate from './templates/generic_novel/chapter.xhtml?raw';
import sceneTemplate from './templates/generic_novel/scene.xhtml?raw';
import navTemplate from './templates/generic_novel/nav.xhtml?raw';

export class GenericNovelTemplate extends BaseEpubTemplate {
	readonly name: string = 'Generic Novel';
	readonly description: string = 'A standard novel template with title page, chapters, and scenes';

	/**
	 * Get CSS styles for the novel
	 */
	get_css(): string {
		return stylesheetCss;
	}

	/**
	 * Generate all EPUB files for the novel
	 */
	async generate_files(context: EpubTemplateContext): Promise<EpubFile[]> {
		const files: EpubFile[] = [];
		const { project, options, metadata } = context;

		// Generate manifest items, spine items, and TOC entries
		const manifest_items: EpubManifestItem[] = [];
		const spine_items: EpubSpineItem[] = [];
		const toc_entries: EpubTocEntry[] = [];

		// Required files
		manifest_items.push(
			{ id: 'ncx', href: 'toc.ncx', media_type: 'application/x-dtbncx+xml' },
			{ id: 'nav', href: 'nav.xhtml', media_type: 'application/xhtml+xml', properties: 'nav' },
			{ id: 'css', href: 'stylesheet.css', media_type: 'text/css' }
		);

		// Title page
		if (options.include_title) {
			manifest_items.push({
				id: 'title',
				href: 'title.xhtml',
				media_type: 'application/xhtml+xml'
			});
			spine_items.push({ idref: 'title' });
			toc_entries.push({ id: 'title', title: metadata.title, href: 'title.xhtml', level: 1 });
		}

		// Generate chapter data
		const chapter_data = this.get_chapter_data(project);
		let file_counter = 1;

		// Process chapters
		for (const chapter_info of chapter_data) {
			const { chapter, chapter_number } = chapter_info;

			if (options.include_chapter_titles) {
				// Create chapter file
				const chapter_filename = `chapter_${chapter_number.toString().padStart(2, '0')}.xhtml`;
				const chapter_id = `chapter_${chapter_number}`;

				manifest_items.push({
					id: chapter_id,
					href: chapter_filename,
					media_type: 'application/xhtml+xml'
				});
				spine_items.push({ idref: chapter_id });
				toc_entries.push({
					id: chapter_id,
					title: chapter.title,
					href: chapter_filename,
					level: 1,
					children: []
				});

				// Generate chapter content
				const chapter_content = await this.generate_chapter_file(chapter_info, options);
				files.push({
					path: `OEBPS/${chapter_filename}`,
					content: chapter_content
				});
			} else {
				// Process scenes individually when chapter titles are not included
				const scene_data = this.get_scene_data(chapter, chapter_number);

				for (const scene_info of scene_data) {
					const { scene } = scene_info;

					if (options.include_scene_titles || scene.content.trim()) {
						const scene_filename = `scene_${file_counter.toString().padStart(3, '0')}.xhtml`;
						const scene_id = `scene_${file_counter}`;

						manifest_items.push({
							id: scene_id,
							href: scene_filename,
							media_type: 'application/xhtml+xml'
						});
						spine_items.push({ idref: scene_id });

						if (options.include_scene_titles) {
							toc_entries.push({
								id: scene_id,
								title: scene.title,
								href: scene_filename,
								level: 1
							});
						}

						const scene_content = await this.generate_scene_file(scene_info, options);
						files.push({
							path: `OEBPS/${scene_filename}`,
							content: scene_content
						});

						file_counter++;
					}
				}
			}
		}

		// Update context with generated items
		context.manifest_items = manifest_items;
		context.spine_items = spine_items;
		context.toc_entries = toc_entries;

		// Generate required EPUB files
		files.push(
			{
				path: 'META-INF/container.xml',
				content: this.generate_container_xml()
			},
			{
				path: 'OEBPS/content.opf',
				content: this.generate_content_opf(context)
			},
			{
				path: 'OEBPS/toc.ncx',
				content: this.generate_toc_ncx(context)
			},
			{
				path: 'OEBPS/nav.xhtml',
				content: this.generate_nav_xhtml(context)
			},
			{
				path: 'OEBPS/stylesheet.css',
				content: this.get_css()
			}
		);

		// Generate title page if requested
		if (options.include_title) {
			files.push({
				path: 'OEBPS/title.xhtml',
				content: this.generate_title_page(context)
			});
		}

		return files;
	}

	/**
	 * Generate title page content using template
	 */
	private generate_title_page(context: EpubTemplateContext): string {
		const { metadata } = context;

		return TemplateEngine.process_with_escaping(titlePageTemplate, {
			title: metadata.title,
			author: metadata.author,
			description: metadata.description
		});
	}

	/**
	 * Generate chapter file content using template
	 */
	private async generate_chapter_file(
		chapter_data: ChapterData,
		options: ExportOptions
	): Promise<string> {
		const { chapter, chapter_number } = chapter_data;
		let content = '';

		// Add scenes content
		const scene_data = this.get_scene_data(chapter, chapter_number);
		for (let i = 0; i < scene_data.length; i++) {
			const scene_info = scene_data[i];
			const { scene } = scene_info;

			if (options.include_scene_titles) {
				content += `<h3 class="scene-title">${this.escape_html(scene.title)}</h3>\n`;
			}

			if (scene.content.trim()) {
				content += this.html_to_xhtml(scene.content);
			}

			if (options.include_word_count) {
				content += `<p class="word-count">Words: ${scene.wordCount}</p>\n`;
			}

			// Add scene break if not the last scene
			if (i < scene_data.length - 1) {
				content += '<div class="scene-break">* * *</div>\n';
			}
		}

		return TemplateEngine.process(chapterTemplate, {
			chapter_title: chapter.title,
			content: content
		});
	}

	/**
	 * Generate individual scene file content using template
	 */
	private async generate_scene_file(
		scene_data: SceneData,
		options: ExportOptions
	): Promise<string> {
		const { scene } = scene_data;

		return TemplateEngine.process(sceneTemplate, {
			scene_title: scene.title,
			content: scene.content.trim() ? this.html_to_xhtml(scene.content) : '',
			include_scene_titles: options.include_scene_titles,
			include_word_count: options.include_word_count,
			word_count: scene.wordCount
		});
	}

	/**
	 * Generate nav.xhtml using template
	 */
	protected generate_nav_xhtml(context: EpubTemplateContext): string {
		const { toc_entries } = context;

		const nav_items = TemplateEngine.generate_nav_list(toc_entries);

		return TemplateEngine.process(navTemplate, {
			nav_items: nav_items
		});
	}
}
