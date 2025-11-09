import { createCerebras } from '@ai-sdk/cerebras';
import { generateText, streamText } from 'ai';
import dedent from 'dedent';
import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { aj } from './protection';
import { openrouter } from './ai';

const MARKETING_MODEL: Parameters<typeof openrouter>[0] = 'openai/gpt-oss-120b';

const app = new Hono();

app.use(
	'*',
	cors({
		origin: '*',
		allowMethods: ['GET', 'POST', 'OPTIONS'],
		allowHeaders: ['Content-Type', 'Cache-Control', 'X-Requested-With'],
		exposeHeaders: ['Content-Type', 'Cache-Control'],
		maxAge: 86400
	})
);

// Health check endpoint
app.get('/api/marketing/health', (c) => {
	return c.json({
		status: 'ok',
		service: 'marketing',
		timestamp: new Date().toISOString()
	});
});

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

function validate_story_input(body: any): { valid: boolean; error?: string } {
	const required_fields = ['genre', 'theme', 'setting', 'tone'];

	for (const field of required_fields) {
		if (!body[field] || typeof body[field] !== 'string') {
			return { valid: false, error: `${field} is required and must be a string` };
		}
	}

	const word_count = body.word_count;
	if (word_count && (typeof word_count !== 'number' || word_count < 50 || word_count > 1000)) {
		return { valid: false, error: 'word_count must be a number between 50 and 1000' };
	}

	const context = body.context;
	if (context && typeof context !== 'string') {
		return { valid: false, error: 'context must be a string' };
	}

	return { valid: true };
}

// AI Story Generator endpoint
app.post('/api/marketing/generate-story', async (c) => {
	const decision = await aj.protect(c.req.raw, { requested: 3 });
	if (decision.isDenied() && decision.reason.isRateLimit())
		return c.json({ error: 'Too many requests' }, 429);

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
			temperature: 0.8
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
});

// Export the Hono app for mounting in main server
export default app;
