import { generateText, streamText } from 'ai';
import dedent from 'dedent';
import { Hono } from 'hono';
import { withTracing } from '@posthog/ai';
import { aj } from './protection';
import { posthog } from './tracking';
import { openrouter } from './ai';
import { AI_DEFAULTS } from './constants';
import { auth } from './auth';

type Model = Parameters<typeof openrouter>[0];

const MODELS = {
	SLOW: 'openai/gpt-oss-120b',
	FAST: 'x-ai/grok-4.1-fast'
} as const satisfies Record<string, Model>;

function create_model(model: Model) {
	return withTracing(openrouter(model), posthog, {});
}

const DIALOGUE_ENDINGS = [
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
] as const;

function is_mid_sentence(text: string): boolean {
	const clean_text = text.replace('<CONTINUE_HERE>', '').trim();
	if (!clean_text) return false;

	for (const ending of DIALOGUE_ENDINGS) {
		if (clean_text.endsWith(ending)) return false;
	}

	if (clean_text.endsWith('—') || clean_text.endsWith('--')) return true;

	return false;
}

function build_context_string(context: unknown): string {
	if (!context || typeof context !== 'object' || context === null) {
		return '';
	}

	const ctx = context as Record<string, unknown>;
	const parts: string[] = [];

	if (ctx.title && typeof ctx.title === 'string') parts.push(`Title: "${ctx.title}"`);
	if (ctx.genre && typeof ctx.genre === 'string') parts.push(`Genre: ${ctx.genre}`);
	if (ctx.tone && typeof ctx.tone === 'string') parts.push(`Tone: ${ctx.tone}`);
	if (Array.isArray(ctx.character_names)) {
		const names = ctx.character_names.filter((name): name is string => typeof name === 'string');
		if (names.length > 0) parts.push(`Characters: ${names.join(', ')}`);
	}
	if (ctx.scene_description && typeof ctx.scene_description === 'string') {
		parts.push(`Scene: ${ctx.scene_description}`);
	}

	return parts.length > 0 ? `Context: ${parts.join('. ')}.` : '';
}

const ALTERNATIVE_TYPE_INSTRUCTIONS = {
	vivid: dedent`
		Make this sentence MORE VIVID by:
		• Adding specific sensory details (sight, sound, touch, smell, taste)
		• Using more concrete, evocative imagery
		• Replacing vague words with precise, descriptive language
		• Creating a stronger visual or emotional impact
	`,
	tighter: dedent`
		Make this sentence TIGHTER by:
		• Eliminating unnecessary words and redundancy
		• Using stronger, more direct verbs
		• Combining related ideas efficiently
		• Maintaining impact while reducing word count
	`,
	show_dont_tell: dedent`
		Rewrite to SHOW DON'T TELL by:
		• Converting abstract statements into concrete actions or descriptions
		• Demonstrating emotions through behavior and physical reactions
		• Using dialogue, action, or sensory details instead of exposition
		• Letting readers infer meaning from what characters do and say
	`,
	change_pov: dedent`
		CHANGE THE POINT OF VIEW by:
		• If currently third person, try first person or vice versa
		• If currently omniscient, try limited perspective
		• Adjust pronouns and perspective accordingly
		• Maintain the same events but from a different viewpoint
	`,
	simplify: dedent`
		SIMPLIFY THE PROSE by:
		• Using shorter, clearer sentences
		• Replacing complex words with simpler alternatives
		• Reducing elaborate descriptions to essential elements
		• Making the language more accessible while keeping the meaning
	`
} as const;

type AlternativeType = keyof typeof ALTERNATIVE_TYPE_INSTRUCTIONS;

function build_alternatives_system_prompt(
	alternative_type: AlternativeType,
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

	return `${base_instructions}\n\n${ALTERNATIVE_TYPE_INSTRUCTIONS[alternative_type]}`;
}

function build_system_prompt(
	context: unknown,
	text: string = '',
	word_count: number = 100,
	recent_text: string = ''
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

	const text_before_marker = text.split('<CONTINUE_HERE>')[0] || '';
	const is_mid_sentence_context = is_mid_sentence(text_before_marker);

	const continuation_style = is_mid_sentence_context
		? 'Complete the current thought naturally, then continue the narrative.'
		: 'Begin with a compelling new sentence that advances the story.';

	const recent_text_warning = recent_text
		? `\n\nThe text immediately before <CONTINUE_HERE> is: "${recent_text}"\nDo NOT repeat this text. Your response should start with NEW words that come AFTER "${recent_text}".`
		: '';

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
		• Aim for around ${word_count} words
		• End at a meaningful moment - a revelation, decision point, or scene transition

		CRITICAL: The <CONTINUE_HERE> marker shows where to continue from. Write ONLY what comes AFTER this marker.
		Do NOT repeat any text that appears before the marker. Start with fresh, new content that continues the narrative.${recent_text_warning}

		Return only your continuation text - no explanations or formatting.`;
}

function build_start_system_prompt(context: Record<string, unknown>, word_count: number): string {
	return dedent`
		You are a creative writing assistant helping a fiction author. The user has provided a prompt to start writing from.

		Context: ${JSON.stringify(context, null, 2)}

		Generate creative, engaging fiction writing based on the prompt. Write in a natural, flowing style appropriate for fiction. Aim for approximately ${word_count} words.

		Focus on:
		- Natural narrative flow
		- Engaging prose
		- Character voice and perspective
		- Scene setting and atmosphere
		- Forward momentum in the story

		Return only the generated text without any explanations or metadata.`;
}

const ALTERNATIVE_TYPES: AlternativeType[] = [
	'vivid',
	'tighter',
	'show_dont_tell',
	'change_pov',
	'simplify'
];

const app = new Hono()
	.use('*', auth)
	.post('/api/verify', async (c) => {
		const decision = await aj.protect(c.req.raw, { requested: 1 });
		if (decision.isDenied() && decision.reason.isRateLimit()) {
			return c.json({ error: 'Too many requests' }, 429);
		}

		return c.text('OK');
	})
	.post('/api/continue', async (c) => {
		const decision = await aj.protect(c.req.raw, { requested: 1 });
		if (decision.isDenied() && decision.reason.isRateLimit()) {
			return c.json({ error: 'Too many requests' }, 429);
		}

		try {
			const body = await c.req.json();
			const content = body?.content;
			const context = body?.context || {};
			const word_count = typeof body?.word_count === 'number' ? body.word_count : 100;
			const stream = c.req.header('accept') === 'text/plain+stream';

			if (!content || typeof content !== 'string') {
				return c.json({ error: 'Content is required and must be a string' }, 400);
			}

			const client = create_model(MODELS.FAST);

			const ctx =
				context && typeof context === 'object' && context !== null
					? (context as Record<string, unknown>)
					: {};
			const recent_text =
				ctx.recent_text && typeof ctx.recent_text === 'string' ? ctx.recent_text : '';

			const system_prompt = build_system_prompt(context, content, word_count, recent_text);

			const text_with_marker = recent_text
				? content.replace(recent_text, recent_text + '<CONTINUE_HERE>')
				: content + '<CONTINUE_HERE>';

			const user_prompt = `<text>${text_with_marker}</text>`;

			const common_options = {
				model: client,
				system: system_prompt,
				prompt: user_prompt,
				temperature: AI_DEFAULTS.temperature,
				topP: AI_DEFAULTS.topP,
				providerOptions: {
					openrouter: {
						reasoning: {
							enabled: false
						}
					}
				}
			};

			if (stream) {
				return streamText(common_options).toTextStreamResponse();
			}

			const result = await generateText(common_options);
			return c.text(result.text);
		} catch (error) {
			console.error('Continue writing error:', error);
			return c.json({ error: 'Failed to generate continuation' }, 500);
		}
	})
	.post('/api/rephrase', async (c) => {
		const decision = await aj.protect(c.req.raw, { requested: 1 });
		if (decision.isDenied() && decision.reason.isRateLimit()) {
			return c.json({ error: 'Too many requests' }, 429);
		}

		try {
			const body = await c.req.json();
			const { selected_sentence, context_before = '', context_after = '' } = body;

			if (!selected_sentence || typeof selected_sentence !== 'string') {
				return c.json({ error: 'selected_sentence is required and must be a string' }, 400);
			}

			const client = create_model(MODELS.SLOW);

			const alternatives = await Promise.all(
				ALTERNATIVE_TYPES.map(async (type) => {
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
						temperature: AI_DEFAULTS.temperature,
						topP: AI_DEFAULTS.topP
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
	})
	.post('/api/start', async (c) => {
		const decision = await aj.protect(c.req.raw, { requested: 1 });
		if (decision.isDenied() && decision.reason.isRateLimit()) {
			return c.json({ error: 'Too many requests' }, 429);
		}

		try {
			const body = await c.req.json();
			const prompt = body?.prompt;
			const context = body?.context || {};
			const word_count = typeof body?.word_count === 'number' ? body.word_count : 150;
			const stream = c.req.header('accept') === 'text/plain+stream';

			if (!prompt || typeof prompt !== 'string') {
				return c.json({ error: 'Prompt is required and must be a string' }, 400);
			}

			const client = create_model(MODELS.FAST);
			const system_prompt = build_start_system_prompt(context, word_count);
			const user_prompt = `<prompt>${prompt}</prompt>`;

			const common_options = {
				model: client,
				system: system_prompt,
				prompt: user_prompt,
				temperature: AI_DEFAULTS.temperature,
				topP: AI_DEFAULTS.topP
			};

			if (stream) {
				return streamText(common_options).toTextStreamResponse();
			}

			const result = await generateText(common_options);
			return c.text(result.text);
		} catch (error) {
			console.error('Start writing error:', error);
			return c.json({ error: 'Failed to generate content from prompt' }, 500);
		}
	});

export default app;
