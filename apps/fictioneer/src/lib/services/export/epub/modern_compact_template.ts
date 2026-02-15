import type { EpubTemplateContext, EpubFile } from './types.js';
import { GenericNovelTemplate } from './generic_novel_template.js';

import stylesheetCss from './templates/modern_compact/stylesheet.css?raw';

export class ModernCompactTemplate extends GenericNovelTemplate {
	readonly name = 'Modern Compact';
	readonly description = 'Clean modern typography with compact spacing for fast reading';

	get_css(): string {
		return stylesheetCss;
	}

	async generate_files(context: EpubTemplateContext): Promise<EpubFile[]> {
		return super.generate_files(context);
	}
}
