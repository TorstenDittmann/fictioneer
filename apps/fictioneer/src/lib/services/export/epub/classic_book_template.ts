import type { EpubTemplateContext, EpubFile } from './types.js';
import { GenericNovelTemplate } from './generic_novel_template.js';

import stylesheetCss from './templates/classic_book/stylesheet.css?raw';

export class ClassicBookTemplate extends GenericNovelTemplate {
	readonly name = 'Classic Book';
	readonly description =
		'Traditional print-inspired layout with generous margins and elegant rhythm';

	get_css(): string {
		return stylesheetCss;
	}

	async generate_files(context: EpubTemplateContext): Promise<EpubFile[]> {
		return super.generate_files(context);
	}
}
