// Re-export everything from the new modular export system
export type { ExportOptions, ExportHandler, ExportResult } from './export/types.js';
export { BaseExportHandler } from './export/base_export_handler.js';
export { RtfExportHandler } from './export/rtf_export_handler.js';
export { TextExportHandler } from './export/text_export_handler.js';
export { EpubExportHandler } from './export/epub_export_handler.js';
export { export_service } from './export/export_service.js';

// EPUB template system
export type {
	EpubTemplate,
	EpubFile,
	EpubMetadata,
	EpubTemplateContext
} from './export/epub/types.js';
export { BaseEpubTemplate } from './export/epub/base_epub_template.js';
export { GenericNovelTemplate } from './export/epub/generic_novel_template.js';
export { TemplateEngine } from './export/epub/template_engine.js';
