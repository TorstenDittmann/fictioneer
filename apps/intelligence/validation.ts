export type ValidationResult<T = unknown> = ({ valid: true } & T) | { valid: false; error: string };

export function validate_required_strings<T extends string>(
	body: Record<string, unknown>,
	fields: readonly T[]
): ValidationResult {
	for (const field of fields) {
		if (!body[field] || typeof body[field] !== 'string') {
			return { valid: false, error: `${field} is required and must be a string` };
		}
	}
	return { valid: true };
}

export function validate_count(
	value: unknown,
	min: number = 3,
	max: number = 12,
	defaultValue: number = 6
): ValidationResult<{ count: number }> {
	const count = Number(value ?? defaultValue);
	if (Number.isNaN(count) || count < min || count > max) {
		return { valid: false, error: `count must be between ${min} and ${max}` };
	}
	return { valid: true, count };
}

export function validate_range(
	value: unknown,
	field: string,
	min: number,
	max: number
): ValidationResult<{ value: number }> {
	const num = Number(value);
	if (Number.isNaN(num) || num < min || num > max) {
		return { valid: false, error: `${field} must be between ${min} and ${max}` };
	}
	return { valid: true, value: num };
}

export interface StoryInput {
	genre: string;
	theme: string;
	setting: string;
	tone: string;
	word_count?: number;
	context?: string;
}

export interface CharacterNameInput {
	genre: string;
	origin: string;
	gender: string;
	style: string;
	traits?: string;
	count?: number;
}

export interface PlotInput {
	genre: string;
	structure: string;
	conflict: string;
	twist: string;
	protagonist: string;
	setting: string;
}

export interface BookTitleInput {
	genre: string;
	style: string;
	keywords: string;
	count?: number;
}

export interface PenNameInput {
	genre: string;
	style: string;
	pronouns: string;
	keywords: string;
	include_initials?: boolean;
}

export interface TownNameInput {
	world_type: string;
	region: string;
	size: string;
	vibe: string;
	features: string;
	count?: number;
}

export interface FanFictionInput {
	fandom: string;
	ship_type: string;
	tone: string;
	canon_alignment: number;
	prompt_details: string;
}

export interface AdultStoryInput {
	genre: string;
	tone: string;
	steam_level: number;
	tropes?: string[];
	custom_prompt: string;
}

export function validate_story_input(body: Record<string, unknown>): ValidationResult {
	const required_fields = ['genre', 'theme', 'setting', 'tone'] as const;
	const string_validation = validate_required_strings(body, required_fields);
	if (!string_validation.valid) return string_validation;

	const word_count = body.word_count;
	if (word_count !== undefined) {
		if (typeof word_count !== 'number' || word_count < 50 || word_count > 1000) {
			return { valid: false, error: 'word_count must be a number between 50 and 1000' };
		}
	}

	const context = body.context;
	if (context !== undefined && typeof context !== 'string') {
		return { valid: false, error: 'context must be a string' };
	}

	return { valid: true };
}

export function validate_character_name_input(
	body: Record<string, unknown>
): ValidationResult<{ count: number }> {
	const required_fields = ['genre', 'origin', 'gender', 'style'] as const;
	const string_validation = validate_required_strings(body, required_fields);
	if (!string_validation.valid) return string_validation;

	const count_validation = validate_count(body.count);
	if (!count_validation.valid) return count_validation;

	if (body.traits !== undefined && typeof body.traits !== 'string') {
		return { valid: false, error: 'traits must be a string of comma-separated values' };
	}

	return { valid: true, count: count_validation.count };
}

export function validate_plot_input(body: Record<string, unknown>): ValidationResult {
	const required_fields = [
		'genre',
		'structure',
		'conflict',
		'twist',
		'protagonist',
		'setting'
	] as const;
	return validate_required_strings(body, required_fields);
}

export function validate_book_title_input(
	body: Record<string, unknown>
): ValidationResult<{ count: number }> {
	const required_fields = ['genre', 'style', 'keywords'] as const;
	const string_validation = validate_required_strings(body, required_fields);
	if (!string_validation.valid) return string_validation;

	const count_validation = validate_count(body.count);
	if (!count_validation.valid) return count_validation;

	return { valid: true, count: count_validation.count };
}

export function validate_pen_name_input(body: Record<string, unknown>): ValidationResult {
	const required_fields = ['genre', 'style', 'pronouns', 'keywords'] as const;
	const string_validation = validate_required_strings(body, required_fields);
	if (!string_validation.valid) return string_validation;

	if (body.include_initials !== undefined && typeof body.include_initials !== 'boolean') {
		return { valid: false, error: 'include_initials must be boolean' };
	}

	return { valid: true };
}

export function validate_town_name_input(
	body: Record<string, unknown>
): ValidationResult<{ count: number }> {
	const required_fields = ['world_type', 'region', 'size', 'vibe', 'features'] as const;
	const string_validation = validate_required_strings(body, required_fields);
	if (!string_validation.valid) return string_validation;

	const count_validation = validate_count(body.count);
	if (!count_validation.valid) return count_validation;

	return { valid: true, count: count_validation.count };
}

export function validate_fan_fiction_input(
	body: Record<string, unknown>
): ValidationResult<{ canon_alignment: number }> {
	const required_string_fields = ['fandom', 'ship_type', 'tone', 'prompt_details'] as const;
	const string_validation = validate_required_strings(body, required_string_fields);
	if (!string_validation.valid) return string_validation;

	if (body.canon_alignment === undefined || body.canon_alignment === null) {
		return { valid: false, error: 'canon_alignment is required' };
	}

	const range_validation = validate_range(body.canon_alignment, 'canon_alignment', 0, 100);
	if (!range_validation.valid) return range_validation;

	return { valid: true, canon_alignment: range_validation.value };
}

export function validate_adult_story_input(
	body: Record<string, unknown>
): ValidationResult<{ steam_level: number }> {
	const required_string_fields = ['genre', 'tone', 'custom_prompt'] as const;
	const string_validation = validate_required_strings(body, required_string_fields);
	if (!string_validation.valid) return string_validation;

	if (body.steam_level === undefined || body.steam_level === null) {
		return { valid: false, error: 'steam_level is required' };
	}

	const range_validation = validate_range(body.steam_level, 'steam_level', 0, 100);
	if (!range_validation.valid) return range_validation;

	if (body.tropes !== undefined && !Array.isArray(body.tropes)) {
		return { valid: false, error: 'tropes must be an array of strings' };
	}

	return { valid: true, steam_level: range_validation.value };
}
