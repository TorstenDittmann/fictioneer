import { generateObject, generateText, streamText } from 'ai';
import dedent from 'dedent';
import { Hono } from 'hono';
import { cors } from 'hono/cors';
import type { Context } from 'hono';
import { aj } from './protection';
import { openrouter } from './ai';
import { AI_DEFAULTS, CORS_CONFIG } from './constants';
import {
	validate_story_input,
	validate_character_name_input,
	validate_plot_input,
	validate_book_title_input,
	validate_pen_name_input,
	validate_town_name_input,
	validate_fan_fiction_input,
	validate_adult_story_input
} from './validation';
import {
	character_names_schema,
	plot_schema,
	book_titles_schema,
	pen_names_schema,
	town_names_schema,
	fan_fiction_schema,
	adult_story_schema
} from './schemas';

const MARKETING_MODEL: Parameters<typeof openrouter>[0] = 'openai/gpt-oss-120b';

const MARKETING_CORS_CONFIG = {
	...CORS_CONFIG,
	allowMethods: ['GET', 'POST', 'OPTIONS']
};

async function apply_rate_limit(c: Context) {
	const decision = await aj.protect(c.req.raw, { requested: 3 });
	if (decision.isDenied() && decision.reason.isRateLimit()) {
		return c.json({ error: 'Too many requests' }, 429);
	}
	return null;
}

function build_story_prompt(
	genre: string,
	theme: string,
	setting: string,
	tone: string,
	word_count: number,
	context?: string
): string {
	const context_section = context ? `\n\nAdditional Context:\n${context}` : '';

	return dedent`
		You are a creative writing assistant specializing in generating engaging short stories.

		Story Requirements:
		• Genre: ${genre}
		• Theme: ${theme}
		• Setting: ${setting}
		• Tone: ${tone}
		• Target length: Approximately ${word_count} words${context_section}

		Writing Guidelines:
		• Create compelling characters with distinct voices
		• Use vivid, sensory descriptions to bring scenes to life
		• Show don't tell - demonstrate emotions and conflicts through actions
		• Include dialogue that reveals character and advances the plot
		• Build tension and maintain reader engagement throughout
		• End with a satisfying conclusion that ties together the story elements
		• Use varied sentence structure to create rhythm and flow
		• Focus on a single central conflict or event
		• If additional context is provided, incorporate those details naturally into the story

		Generate a complete, self-contained story that incorporates all the specified elements.
		Return only the story text without any explanations or formatting markers.
	`;
}

function build_character_name_prompt(body: {
	genre: string;
	origin: string;
	gender: string;
	style: string;
	traits?: string;
	count: number;
}): string {
	return dedent`
		You are an expert character name curator for fiction writers.
		Create ${body.count} names tailored to the following brief:

		• Genre or vibe: ${body.genre}
		• Cultural or phonetic origin: ${body.origin}
		• Gender expression: ${body.gender}
		• Style or tone: ${body.style}
		• Traits or themes to keep in mind: ${body.traits || 'use your best judgment'}

		Each meaning should describe why the name fits the prompt in one short sentence.
	`;
}

function build_plot_prompt(body: {
	genre: string;
	structure: string;
	conflict: string;
	twist: string;
	protagonist: string;
	setting: string;
}): string {
	return dedent`
		You are outlining story beats for a ${body.genre} project.

		Parameters:
		• Structure: ${body.structure}
		• Primary conflict: ${body.conflict}
		• Signature twist: ${body.twist}
		• Protagonist description: ${body.protagonist}
		• Setting: ${body.setting}

		Provide exactly three beats aligned to the requested structure.
	`;
}

function build_book_title_prompt(body: {
	genre: string;
	style: string;
	keywords: string;
	count: number;
}): string {
	return dedent`
		Generate ${body.count} compelling book titles.

		Parameters:
		• Genre/Vibe: ${body.genre}
		• Style tone: ${body.style}
		• Keywords or themes: ${body.keywords}
	`;
}

function build_pen_name_prompt(body: {
	genre: string;
	style: string;
	pronouns: string;
	keywords: string;
	include_initials?: boolean;
}): string {
	return dedent`
		Create 6 pseudonyms for an author.

		Genre focus: ${body.genre}
		Tone/style: ${body.style}
		Pronoun cue: ${body.pronouns}
		Brand keywords: ${body.keywords}
		Include initials: ${body.include_initials ? 'Yes' : 'No'}

		Keep taglines concise and evocative.
	`;
}

function build_town_name_prompt(body: {
	world_type: string;
	region: string;
	size: string;
	vibe: string;
	features: string;
	count: number;
}): string {
	return dedent`
		Create ${body.count} fictional settlements.

		World type: ${body.world_type}
		Region flavor: ${body.region}
		Settlement size: ${body.size}
		Tone/Vibe: ${body.vibe}
		Signature features: ${body.features}

		Descriptions should highlight texture and history in one or two sentences.
	`;
}

function build_fan_fiction_prompt(body: {
	fandom: string;
	ship_type: string;
	tone: string;
	canon_alignment: number;
	prompt_details: string;
}): string {
	return dedent`
		Generate a fan fiction prompt outline.

		Fandom: ${body.fandom}
		Relationship dynamic: ${body.ship_type}
		Tone: ${body.tone}
		Canon alignment percentage: ${body.canon_alignment}%
		Prompt details: ${body.prompt_details}

		Provide exactly three sections covering setup, conflict, and resolution/next steps.
	`;
}

function build_adult_story_prompt(body: {
	genre: string;
	tone: string;
	steam_level: number;
	tropes?: string[];
	custom_prompt: string;
}): string {
	return dedent`
		Generate a consent-first adult fiction story idea.

		Genre: ${body.genre}
		Tone: ${body.tone}
		Steam level: ${body.steam_level}%
		Tropes: ${body.tropes?.join(', ') || 'writer choice'}
		Custom prompt: ${body.custom_prompt}

		Paragraphs should be 2-3 sentences each and focus on character chemistry and emotional stakes.
	`;
}

const app = new Hono()
	.use('*', cors(MARKETING_CORS_CONFIG))
	.get('/api/marketing/health', (c) => {
		return c.json({
			status: 'ok',
			service: 'marketing',
			timestamp: new Date().toISOString()
		});
	})
	.post('/api/marketing/generate-story', async (c) => {
		const rate_limit_response = await apply_rate_limit(c);
		if (rate_limit_response) return rate_limit_response;

		try {
			const body = await c.req.json();
			const validation = validate_story_input(body);

			if (!validation.valid) {
				return c.json({ error: validation.error }, 400);
			}

			const { genre, theme, setting, tone, word_count = 300, context } = body;

			const client = openrouter(MARKETING_MODEL);
			const system_prompt = build_story_prompt(genre, theme, setting, tone, word_count, context);

			const common_options = {
				model: client,
				system: system_prompt,
				prompt: 'Generate the story based on the requirements provided.',
				temperature: AI_DEFAULTS.temperature
			};

			const stream = c.req.header('accept') === 'text/plain+stream';

			if (stream) {
				return streamText(common_options).toTextStreamResponse();
			}

			const result = await generateText(common_options);
			const story_text = result.text.trim();

			return c.json({
				story: story_text,
				metadata: {
					genre,
					theme,
					setting,
					tone,
					word_count: story_text.split(/\s+/).length
				}
			});
		} catch (error) {
			console.error('Story generation error:', error);
			return c.json({ error: 'Failed to generate story. Please try again.' }, 500);
		}
	})
	.post('/api/marketing/generate-character-names', async (c) => {
		const rate_limit_response = await apply_rate_limit(c);
		if (rate_limit_response) return rate_limit_response;

		try {
			const body = await c.req.json();
			const validation = validate_character_name_input(body);
			if (!validation.valid) {
				return c.json({ error: validation.error }, 400);
			}

			const payload = {
				genre: body.genre,
				origin: body.origin,
				gender: body.gender,
				style: body.style,
				traits: body.traits,
				count: validation.count
			};

			const result = await generateObject({
				model: openrouter(MARKETING_MODEL),
				schema: character_names_schema,
				prompt: build_character_name_prompt(payload),
				temperature: 0.7
			});

			return c.json(result.object);
		} catch (error) {
			console.error('Character name generation error:', error);
			return c.json({ error: 'Failed to generate names. Please try again.' }, 500);
		}
	})
	.post('/api/marketing/generate-plot', async (c) => {
		const rate_limit_response = await apply_rate_limit(c);
		if (rate_limit_response) return rate_limit_response;

		try {
			const body = await c.req.json();
			const validation = validate_plot_input(body);
			if (!validation.valid) {
				return c.json({ error: validation.error }, 400);
			}

			const payload = {
				genre: body.genre,
				structure: body.structure,
				conflict: body.conflict,
				twist: body.twist,
				protagonist: body.protagonist,
				setting: body.setting
			};

			const result = await generateObject({
				model: openrouter(MARKETING_MODEL),
				schema: plot_schema,
				prompt: build_plot_prompt(payload),
				temperature: 0.7
			});

			return c.json(result.object);
		} catch (error) {
			console.error('Plot generation error:', error);
			return c.json({ error: 'Failed to generate plot outline. Please try again.' }, 500);
		}
	})
	.post('/api/marketing/generate-book-titles', async (c) => {
		const rate_limit_response = await apply_rate_limit(c);
		if (rate_limit_response) return rate_limit_response;

		try {
			const body = await c.req.json();
			const validation = validate_book_title_input(body);
			if (!validation.valid) {
				return c.json({ error: validation.error }, 400);
			}

			const payload = {
				genre: body.genre,
				style: body.style,
				keywords: body.keywords,
				count: validation.count
			};

			const result = await generateObject({
				model: openrouter(MARKETING_MODEL),
				schema: book_titles_schema,
				prompt: build_book_title_prompt(payload),
				temperature: 0.7
			});

			return c.json(result.object);
		} catch (error) {
			console.error('Book title generation error:', error);
			return c.json({ error: 'Failed to generate titles. Please try again.' }, 500);
		}
	})
	.post('/api/marketing/generate-pen-names', async (c) => {
		const rate_limit_response = await apply_rate_limit(c);
		if (rate_limit_response) return rate_limit_response;

		try {
			const body = await c.req.json();
			const validation = validate_pen_name_input(body);
			if (!validation.valid) {
				return c.json({ error: validation.error }, 400);
			}

			const payload = {
				genre: body.genre,
				style: body.style,
				pronouns: body.pronouns,
				keywords: body.keywords,
				include_initials: body.include_initials
			};

			const result = await generateObject({
				model: openrouter(MARKETING_MODEL),
				schema: pen_names_schema,
				prompt: build_pen_name_prompt(payload),
				temperature: 0.7
			});

			return c.json(result.object);
		} catch (error) {
			console.error('Pen name generation error:', error);
			return c.json({ error: 'Failed to generate pen names. Please try again.' }, 500);
		}
	})
	.post('/api/marketing/generate-town-names', async (c) => {
		const rate_limit_response = await apply_rate_limit(c);
		if (rate_limit_response) return rate_limit_response;

		try {
			const body = await c.req.json();
			const validation = validate_town_name_input(body);
			if (!validation.valid) {
				return c.json({ error: validation.error }, 400);
			}

			const payload = {
				world_type: body.world_type,
				region: body.region,
				size: body.size,
				vibe: body.vibe,
				features: body.features,
				count: validation.count
			};

			const result = await generateObject({
				model: openrouter(MARKETING_MODEL),
				schema: town_names_schema,
				prompt: build_town_name_prompt(payload),
				temperature: 0.7
			});

			return c.json(result.object);
		} catch (error) {
			console.error('Town name generation error:', error);
			return c.json({ error: 'Failed to generate town names. Please try again.' }, 500);
		}
	})
	.post('/api/marketing/generate-fan-fiction', async (c) => {
		const rate_limit_response = await apply_rate_limit(c);
		if (rate_limit_response) return rate_limit_response;

		try {
			const body = await c.req.json();
			const validation = validate_fan_fiction_input(body);
			if (!validation.valid) {
				return c.json({ error: validation.error }, 400);
			}

			const payload = {
				fandom: body.fandom,
				ship_type: body.ship_type,
				tone: body.tone,
				canon_alignment: validation.canon_alignment,
				prompt_details: body.prompt_details
			};

			const result = await generateObject({
				model: openrouter(MARKETING_MODEL),
				schema: fan_fiction_schema,
				prompt: build_fan_fiction_prompt(payload),
				temperature: 0.7
			});

			return c.json(result.object);
		} catch (error) {
			console.error('Fan fiction generation error:', error);
			return c.json({ error: 'Failed to generate fan fiction prompt. Please try again.' }, 500);
		}
	})
	.post('/api/marketing/generate-adult-story', async (c) => {
		const rate_limit_response = await apply_rate_limit(c);
		if (rate_limit_response) return rate_limit_response;

		try {
			const body = await c.req.json();
			const validation = validate_adult_story_input(body);
			if (!validation.valid) {
				return c.json({ error: validation.error }, 400);
			}

			const payload = {
				genre: body.genre,
				tone: body.tone,
				steam_level: validation.steam_level,
				tropes: Array.isArray(body.tropes) ? body.tropes : undefined,
				custom_prompt: body.custom_prompt
			};

			const result = await generateObject({
				model: openrouter(MARKETING_MODEL),
				schema: adult_story_schema,
				prompt: build_adult_story_prompt(payload),
				temperature: 0.85
			});

			return c.json(result.object);
		} catch (error) {
			console.error('Adult story generation error:', error);
			return c.json({ error: 'Failed to generate adult story idea. Please try again.' }, 500);
		}
	});

export default app;
