import { createGroq, type GroqProvider, type GroqProviderOptions } from '@ai-sdk/groq';
import { generateText, streamText } from 'ai';
import dedent from 'dedent';
import { Hono } from 'hono';
import { bearerAuth } from 'hono/bearer-auth';
import { cors } from 'hono/cors';
import type { GumroadPurchaseResponse } from './types';

const GROQ_API_KEY = process.env.GROQ_API_KEY;

if (!GROQ_API_KEY) {
	throw new Error('GROQ_API_KEY environment variable is required');
}

const groq = createGroq({
	apiKey: GROQ_API_KEY
});

const MODELS = {
	PAID: 'llama-3.3-70b-versatile',
	FREE: 'meta-llama/llama-4-maverick-17b-128e-instruct'
} as const satisfies Record<string, Parameters<GroqProvider>[0]>;

const app = new Hono();

const auth_cache = new Map<string, { expires: number; data: GumroadPurchaseResponse }>();

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
		verifyToken: async (token) => {
			if (!token) return false;
			if (auth_cache.has(token)) {
				const cached = auth_cache.get(token);
				if (cached && cached.expires > Date.now()) {
					return cached.data.success;
				}
			}

			const response = await fetch('https://api.gumroad.com/v2/licenses/verify', {
				method: 'POST',
				headers: {
					'Content-Type': 'application/x-www-form-urlencoded'
				},
				body: new URLSearchParams({
					product_id: '2afaXdBrAUt6seA3ln257Q==',
					license_key: token
				})
			});

			if (!response.ok) return false;

			const data: GumroadPurchaseResponse = await response.json();

			if (!data.success) return false;
			const { subscription_ended_at, subscription_cancelled_at, subscription_failed_at } =
				data.purchase;

			if (
				subscription_ended_at !== null ||
				subscription_cancelled_at !== null ||
				subscription_failed_at !== null
			)
				return false;

			auth_cache.set(token, { expires: Date.now() + 60 * 60 * 24, data });

			return true;
		}
	})
);

function is_mid_sentence(text: string): boolean {
	const clean_text = text.replace('<CONTINUE_HERE>', '').trim();
	if (!clean_text) return false;

	// Check for ending patterns
	const dialogue_endings = [
		'.',
		'!',
		'?',
		'."',
		'!"',
		".'",
		"!'",
		"?'",
		'...',
		'…',
		'***',
		'* * *',
		'---'
	];
	for (const ending of dialogue_endings) {
		if (clean_text.endsWith(ending)) return false;
	}

	// Em-dash at the end usually indicates interruption (mid-sentence)
	if (clean_text.endsWith('—') || clean_text.endsWith('--')) return true;

	return false;
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

function build_alternatives_system_prompt(
	alternative_type: string,
	context_before: string,
	selected_sentence: string,
	context_after: string
): string {
	const base_instructions = dedent`
		You are a novelist's creative writing assistant. Your task is to rewrite the selected sentence according to the specific instruction given.
		
		Context before: "${context_before}"
		Selected sentence: "${selected_sentence}"
		Context after: "${context_after}"
		
		Important guidelines:
		• Only rewrite the selected sentence - do not modify the surrounding context
		• Maintain narrative continuity with the before and after context
		• Keep the same general meaning and story progression
		• Match the tense and voice of the surrounding text
		• Return only the rewritten sentence - no explanations or formatting
	`;

	const type_instructions = {
		vivid: dedent`
			${base_instructions}
			
			Make this sentence MORE VIVID by:
			• Adding specific sensory details (sight, sound, touch, smell, taste)
			• Using more concrete, evocative imagery
			• Replacing vague words with precise, descriptive language
			• Creating a stronger visual or emotional impact
		`,
		tighter: dedent`
			${base_instructions}
			
			Make this sentence TIGHTER by:
			• Eliminating unnecessary words and redundancy
			• Using stronger, more direct verbs
			• Combining related ideas efficiently
			• Maintaining impact while reducing word count
		`,
		show_dont_tell: dedent`
			${base_instructions}
			
			Rewrite to SHOW DON'T TELL by:
			• Converting abstract statements into concrete actions or descriptions
			• Demonstrating emotions through behavior and physical reactions
			• Using dialogue, action, or sensory details instead of exposition
			• Letting readers infer meaning from what characters do and say
		`,
		change_pov: dedent`
			${base_instructions}
			
			CHANGE THE POINT OF VIEW by:
			• If currently third person, try first person or vice versa
			• If currently omniscient, try limited perspective
			• Adjust pronouns and perspective accordingly
			• Maintain the same events but from a different viewpoint
		`,
		simplify: dedent`
			${base_instructions}
			
			SIMPLIFY THE PROSE by:
			• Using shorter, clearer sentences
			• Replacing complex words with simpler alternatives
			• Reducing elaborate descriptions to essential elements
			• Making the language more accessible while keeping the meaning
		`
	};

	return (
		type_instructions[alternative_type as keyof typeof type_instructions] || type_instructions.vivid
	);
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
			? `\nAuthor's guidance: ${ctx.instruction}`
			: '';

	// Check if the text before <CONTINUE_HERE> ends mid-sentence
	const text_before_marker = text.split('<CONTINUE_HERE>')[0] || '';
	const is_mid_sentence_context = is_mid_sentence(text_before_marker);

	const continuation_style = is_mid_sentence_context
		? 'Complete the current thought naturally, then continue the narrative.'
		: 'Begin with a compelling new sentence that advances the story.';

	return dedent`
		You are a novelist's creative writing assistant. ${base_context}${instruction_context}
		
		Your task: Continue the story from the <CONTINUE_HERE> marker. ${continuation_style}
		
		Writing approach:
		• Show don't tell - use vivid sensory details and actions to convey emotions
		• Every paragraph should advance plot, develop character, or build atmosphere
		• Match the established voice, tense, and pacing of the existing text
		• Vary sentence rhythm - blend short, punchy sentences with flowing descriptions
		• Use fresh, evocative language that avoids repetition from the previous text
		• Create smooth transitions that maintain narrative momentum
		• Aim for approximately ${word_count} words, but prioritize natural story breaks
		• End at a meaningful moment - a revelation, decision point, or scene transition
		
		Important: Continue the story seamlessly from where it left off. Don't repeat or summarize what came before.
		
		Return only your continuation text - no explanations or formatting.`;
}

// Health check endpoint
app.get('/health', (c) => {
	return c.json({
		status: 'ok',
		timestamp: new Date().toISOString()
	});
});

app.post('/api/verify', async (c) => {
	return c.text('OK');
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

		const user_prompt = `<text>${text_with_marker}</text>`;

		if (stream) {
			return streamText({
				model: client,
				system: system_prompt,
				prompt: user_prompt,
				temperature: 0.7,
				providerOptions: {
					groq: {} satisfies GroqProviderOptions
				}
			}).toTextStreamResponse();
		} else {
			const result = await generateText({
				model: client,
				system: system_prompt,
				prompt: user_prompt,
				temperature: 0.7,
				providerOptions: {
					groq: {} satisfies GroqProviderOptions
				}
			});

			return c.text(result.text);
		}
	} catch (error) {
		console.error('Continue writing error:', error);
		return c.json({ error: 'Failed to generate continuation' }, 500);
	}
});

// Rephrase endpoint
app.post('/api/rephrase', async (c) => {
	try {
		const body = await c.req.json();
		const { selected_sentence, context_before = '', context_after = '' } = body;

		if (!selected_sentence || typeof selected_sentence !== 'string') {
			return c.json({ error: 'selected_sentence is required and must be a string' }, 400);
		}

		const client = groq(MODELS.PAID);
		const alternative_types = ['vivid', 'tighter', 'show_dont_tell', 'change_pov', 'simplify'];

		const alternatives = await Promise.all(
			alternative_types.map(async (type) => {
				const system_prompt = build_alternatives_system_prompt(
					type,
					context_before,
					selected_sentence,
					context_after
				);

				const result = await generateText({
					model: client,
					system: system_prompt,
					prompt: selected_sentence,
					providerOptions: {
						groq: {} satisfies GroqProviderOptions
					}
				});

				return {
					type,
					alternative: result.text.trim()
				};
			})
		);

		return c.json({
			original: selected_sentence,
			rephrases: alternatives
		});
	} catch (error) {
		console.error('Rephrase generation error:', error);
		return c.json({ error: 'Failed to generate rephrases' }, 500);
	}
});

// Start the server
const port = process.env.PORT ? parseInt(process.env.PORT, 10) : 3001;

export default {
	port: port,
	fetch: app.fetch
};
