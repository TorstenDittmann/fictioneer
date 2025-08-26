export interface TemplateContext {
	[key: string]: unknown;
}

export interface NavItem {
	title: string;
	href: string;
	children?: NavItem[];
}

export class TemplateEngine {
	/**
	 * Process a template string with the given context
	 */
	static process(template: string, context: TemplateContext): string {
		let result = template;

		// Handle conditional blocks {{#key}}...{{/key}}
		result = this.process_conditionals(result, context);

		// Handle simple variable substitutions {{variable}}
		result = this.process_variables(result, context);

		return result;
	}

	/**
	 * Process conditional blocks in the template
	 */
	private static process_conditionals(template: string, context: TemplateContext): string {
		// Match {{#key}}...{{/key}} blocks
		const conditional_regex = /\{\{#(\w+)\}\}([\s\S]*?)\{\{\/\1\}\}/g;

		return template.replace(conditional_regex, (match, key, content) => {
			const value = this.get_nested_value(context, key);

			// If value is truthy (and not empty string), include the content
			if (value && value !== '') {
				return this.process_variables(content, context);
			}

			return '';
		});
	}

	/**
	 * Process variable substitutions in the template
	 */
	private static process_variables(template: string, context: TemplateContext): string {
		// Match {{variable}} patterns
		const variable_regex = /\{\{(\w+)\}\}/g;

		return template.replace(variable_regex, (match, key) => {
			const value = this.get_nested_value(context, key);

			// Return the value or empty string if not found
			return value !== undefined && value !== null ? String(value) : '';
		});
	}

	/**
	 * Get nested value from context using dot notation
	 */
	private static get_nested_value(context: TemplateContext, key: string): unknown {
		const keys = key.split('.');
		let value: unknown = context;

		for (const k of keys) {
			if (value && typeof value === 'object' && value !== null && k in value) {
				value = (value as Record<string, unknown>)[k];
			} else {
				return undefined;
			}
		}

		return value;
	}

	/**
	 * Escape HTML content for safe insertion
	 */
	static escape_html(text: string): string {
		return text
			.replace(/&/g, '&amp;')
			.replace(/</g, '&lt;')
			.replace(/>/g, '&gt;')
			.replace(/"/g, '&quot;')
			.replace(/'/g, '&#x27;');
	}

	/**
	 * Process template with HTML escaping for variables
	 */
	static process_with_escaping(template: string, context: TemplateContext): string {
		// First process conditionals
		let result = this.process_conditionals(template, context);

		// Then process variables with HTML escaping
		const variable_regex = /\{\{(\w+)\}\}/g;

		result = result.replace(variable_regex, (match, key) => {
			const value = this.get_nested_value(context, key);

			if (value !== undefined && value !== null) {
				// Don't escape if it's already HTML content (contains tags)
				const str_value = String(value);
				if (str_value.includes('<') && str_value.includes('>')) {
					return str_value;
				}
				return this.escape_html(str_value);
			}

			return '';
		});

		return result;
	}

	/**
	 * Generate navigation list HTML recursively
	 */
	static generate_nav_list(items: NavItem[], indent: string = '\t\t\t'): string {
		let result = '';

		for (const item of items) {
			result += `${indent}<li><a href="${this.escape_html(item.href)}">${this.escape_html(item.title)}</a>`;

			if (item.children && item.children.length > 0) {
				result += '\n' + indent + '\t<ol>\n';
				result += this.generate_nav_list(item.children, indent + '\t\t');
				result += indent + '\t</ol>\n' + indent;
			}

			result += '</li>\n';
		}

		return result;
	}
}
