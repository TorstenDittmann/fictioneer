import { createGroq, type GroqProvider } from '@ai-sdk/groq';
import { generateText, streamText } from 'ai';
import dedent from 'dedent';
import { Hono } from 'hono';
import { bearerAuth } from 'hono/bearer-auth';
import { cors } from 'hono/cors';
import { verifyToken } from '@clerk/backend';
import type { JwtPayload } from '@clerk/types';

const GROQ_API_KEY = process.env.GROQ_API_KEY;
const CLERK_SECRET_KEY = process.env.CLERK_SECRET_KEY;

if (!GROQ_API_KEY) {
	throw new Error('GROQ_API_KEY environment variable is required');
}
if (!CLERK_SECRET_KEY) {
	throw new Error('CLERK_SECRET_KEY environment variable is required');
}

const groq = createGroq({
	apiKey: GROQ_API_KEY
});

const MODELS = {
	PREMIUM: 'moonshotai/kimi-k2-instruct',
	NORMAL: 'llama-3.3-70b-versatile',
	FREE: 'meta-llama/llama-4-scout-17b-16e-instruct'
} as const satisfies Record<string, Parameters<GroqProvider>[0]>;

const app = new Hono();

const auth_cache = new Map<string, { expires: number; session: JwtPayload }>();

app.use(
	'*',
	cors({
		origin: '*',
		allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
		allowHeaders: ['Content-Type', 'Authorization', 'Cache-Control', 'X-Requested-With'],
		exposeHeaders: ['Content-Type', 'Cache-Control'],
		maxAge: 86400
	})
);

app.use(
	'/api/*',
	bearerAuth({
		verifyToken: async (token, context) => {
			if (!token) return false;
			if (auth_cache.has(token)) {
				const { expires, session } = auth_cache.get(token)!;
				if (expires > Date.now()) {
					context.set('session', session);
					return true;
				}
			}
			try {
				const session = await verifyToken(token, {
					secretKey: CLERK_SECRET_KEY
				});
				context.set('session', session);
				auth_cache.set(token, {
					expires: Date.now() + 1000 * 60 * 15,
					session
				});
				return true;
			} catch (error) {
				console.error('Token verification failed:', error);
				return false;
			}
		}
	})
);

function is_mid_sentence(text: string): boolean {
	const clean_text = text.replace('<CONTINUE_HERE>', '').trim();
	if (!clean_text) return false;
	const last_char = clean_text[clean_text.length - 1];
	return last_char ? !['.', '!', '?', '"', "'", ')', ']', '}'].includes(last_char) : false;
}

function build_context_string(context: unknown): string {
	if (!context || typeof context !== 'object' || context === null) {
		return '';
	}

	const ctx = context as Record<string, unknown>;
	const parts = [];

	if (ctx.title && typeof ctx.title === 'string') parts.push(`Title: "${ctx.title}"`);
	if (ctx.genre && typeof ctx.genre === 'string') parts.push(`Genre: ${ctx.genre}`);
	if (ctx.tone && typeof ctx.tone === 'string') parts.push(`Tone: ${ctx.tone}`);
	if (Array.isArray(ctx.character_names)) {
		const names = ctx.character_names.filter((name) => typeof name === 'string');
		if (names.length > 0) parts.push(`Characters: ${names.join(', ')}`);
	}
	if (ctx.scene_description && typeof ctx.scene_description === 'string') {
		parts.push(`Scene: ${ctx.scene_description}`);
	}

	return parts.length > 0 ? `Context: ${parts.join('. ')}.` : '';
}

function build_system_prompt(
	context: unknown,
	text: string = '',
	word_count: number = 100
): string {
	const base_context = build_context_string(context);
	const ctx =
		context && typeof context === 'object' && context !== null
			? (context as Record<string, unknown>)
			: {};
	const instruction_context =
		ctx.instruction && typeof ctx.instruction === 'string'
			? `\nSpecial instruction: ${ctx.instruction}`
			: '';

	// Check if the text before <CONTINUE_HERE> ends mid-sentence
	const text_before_marker = text.split('<CONTINUE_HERE>')[0] || '';
	const is_mid_sentence_context = is_mid_sentence(text_before_marker);

	const sentence_instruction = is_mid_sentence_context
		? 'The text ends mid-sentence. Complete the current sentence first, then continue with new sentences.'
		: 'The text ends at a complete sentence. Start with a new sentence.';

	return dedent`
		You are a creative writing assistant. ${base_context}${instruction_context}
		
		Continue writing from where the <CONTINUE_HERE> tag appears. ${sentence_instruction}
		
		Rules:
		1. The provided text contains only complete words - there are no partial or incomplete words
		2. The <CONTINUE_HERE> tag shows exactly where to insert your text
		3. Write naturally with varied sentence lengths (maximum 30 words per sentence)
		4. NEVER repeat existing text - only add new content after the tag
		5. NEVER repeat words, phrases, or ideas from the existing text
		6. NEVER use similar vocabulary or sentence structures as what came before
		7. Maintain the same style, tone, and narrative voice while using fresh language
		8. Write around ${word_count} words, but prioritize natural sentence endings
		9. End at a natural stopping point - complete your sentences
		
		Return only the text that should be inserted at <CONTINUE_HERE>, with no quotes or explanations.`;
}

// Health check endpoint
app.get('/health', (c) => {
	return c.json({
		status: 'ok',
		timestamp: new Date().toISOString()
	});
});

// Continue writing endpoint
app.post('/api/continue', async (c) => {
	try {
		const body = await c.req.json();
		const content = body?.content;
		const context = body?.context || {};
		const word_count = typeof body?.word_count === 'number' ? body.word_count : 100;
		const stream = c.req.header('accept') === 'text/plain+stream';

		if (!content || typeof content !== 'string') {
			return c.json({ error: 'Content is required and must be a string' }, 400);
		}

		const client = groq(MODELS.FREE);
		const system_prompt = build_system_prompt(context, content, word_count);

		const ctx =
			context && typeof context === 'object' && context !== null
				? (context as Record<string, unknown>)
				: {};
		const recent_text =
			ctx.recent_text && typeof ctx.recent_text === 'string' ? ctx.recent_text : '';

		const text_with_marker = recent_text
			? content.replace(recent_text, recent_text + '<CONTINUE_HERE>')
			: content + '<CONTINUE_HERE>';

		const user_prompt = dedent`
			<text>
			${text_with_marker}
			</text>
		`;

		if (stream) {
			return streamText({
				model: client,
				system: system_prompt,
				prompt: user_prompt,
				temperature: 0.7
			}).toTextStreamResponse();
		} else {
			const result = await generateText({
				model: client,
				system: system_prompt,
				prompt: user_prompt,
				temperature: 0.7
			});

			return c.text(result.text);
		}
	} catch (error) {
		console.error('Continue writing error:', error);
		return c.json({ error: 'Failed to generate continuation' }, 500);
	}
});

// Start the server
const port = process.env.PORT || 3001;

export default {
	port: port,
	fetch: app.fetch
};
