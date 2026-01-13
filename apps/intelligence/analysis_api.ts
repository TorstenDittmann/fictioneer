/**
 * AI-powered text analysis endpoints
 * Provides Show vs Tell, POV, Tone, and Consistency analysis
 */

import { generateObject } from 'ai';
import dedent from 'dedent';
import { Hono } from 'hono';
import { withTracing } from '@posthog/ai';
import { z } from 'zod';
import { aj } from './protection';
import { posthog } from './tracking';
import { openrouter } from './ai';
import { AI_DEFAULTS } from './constants';
import { auth } from './auth';

type Model = Parameters<typeof openrouter>[0];

const MODELS = {
	ANALYSIS: 'openai/gpt-oss-120b'
} as const satisfies Record<string, Model>;

function create_model(model: Model) {
	return withTracing(openrouter(model), posthog, {});
}

// =============================================================================
// Schemas for structured output
// =============================================================================

const TellingPassageSchema = z.object({
	text: z.string().describe('The original text that is "telling" instead of "showing"'),
	position: z.number().describe('Approximate character position in the content (0-based)'),
	suggestion: z.string().describe('A rewritten version that "shows" instead of "tells"'),
	severity: z.enum(['minor', 'moderate', 'significant']).describe('How impactful this issue is')
});

const ShowTellResponseSchema = z.object({
	telling_passages: z
		.array(TellingPassageSchema)
		.describe('List of passages that could be improved'),
	show_tell_ratio: z
		.number()
		.min(0)
		.max(100)
		.describe('Percentage of text that effectively "shows" (0-100)'),
	assessment: z.string().describe('Brief overall assessment of the show vs tell balance')
});

const POVSlipSchema = z.object({
	text: z.string().describe('The text where POV inconsistency occurs'),
	position: z.number().describe('Approximate character position'),
	issue: z.string().describe('Description of the POV problem'),
	suggestion: z.string().describe('How to fix the POV slip')
});

const POVResponseSchema = z.object({
	pov_slips: z.array(POVSlipSchema).describe('List of POV inconsistencies found'),
	consistency_score: z.number().min(0).max(100).describe('POV consistency score (0-100)'),
	assessment: z.string().describe('Overall assessment of POV consistency')
});

const EmotionalArcPointSchema = z.object({
	position: z.number().min(0).max(100).describe('Position as percentage through text'),
	tension: z.number().min(0).max(10).describe('Tension level at this point'),
	dominant_emotion: z.string().describe('Primary emotion at this point')
});

const ToneResponseSchema = z.object({
	detected_tones: z
		.array(
			z.object({
				name: z.string().describe('Name of the detected tone'),
				confidence: z.number().min(0).max(100).describe('Confidence level 0-100')
			})
		)
		.describe('Tones detected with confidence scores'),
	tension_level: z.number().min(0).max(10).describe('Overall tension level'),
	emotional_arc: z
		.array(EmotionalArcPointSchema)
		.describe('Emotional progression through the scene'),
	tone_consistency: z.number().min(0).max(100).describe('How consistent the tone is'),
	assessment: z.string().describe('Overall tone assessment')
});

const CharacterInconsistencySchema = z.object({
	character: z.string().describe('Name of the character'),
	issue: z.string().describe('Description of the inconsistency'),
	evidence: z.string().describe('Quote or reference from the text')
});

const TimelineIssueSchema = z.object({
	issue: z.string().describe('Description of the timeline problem'),
	conflicting_passages: z.tuple([z.string(), z.string()]).describe('Two conflicting text passages')
});

const FactualContradictionSchema = z.object({
	fact: z.string().describe('The established fact'),
	contradiction: z.string().describe('The contradicting text')
});

const ConsistencyResponseSchema = z.object({
	character_inconsistencies: z.array(CharacterInconsistencySchema),
	timeline_issues: z.array(TimelineIssueSchema),
	factual_contradictions: z.array(FactualContradictionSchema),
	consistency_score: z.number().min(0).max(100),
	assessment: z.string()
});

// =============================================================================
// System Prompts
// =============================================================================

const SHOW_TELL_SYSTEM_PROMPT = dedent`
	You are an expert fiction editor specializing in narrative technique analysis.
	Your task is to identify passages that "tell" instead of "show" and suggest improvements.

	"Telling" includes:
	- Stating emotions directly ("She was angry", "He felt sad")
	- Explaining character motivations ("She wanted to leave because...")
	- Summarizing actions instead of depicting them
	- Using abstract descriptions instead of concrete sensory details
	- Narrator commentary that explains rather than demonstrates

	"Showing" includes:
	- Physical actions and behaviors that reveal emotion
	- Dialogue that expresses feelings indirectly
	- Sensory details (sight, sound, smell, touch, taste)
	- Body language and facial expressions
	- Environmental details that create atmosphere

	When suggesting rewrites:
	- Convert emotional statements to physical reactions
	- Replace abstractions with concrete images
	- Use dialogue to reveal character state
	- Add sensory details where appropriate
	- Maintain the author's voice and style

	Analyze the provided text and identify instances of "telling" that could be improved.
	For each, provide the original text, its approximate position, and a suggested rewrite.
`;

const POV_SYSTEM_PROMPT = dedent`
	You are an expert fiction editor specializing in point of view (POV) analysis.
	Your task is to identify POV inconsistencies and head-hopping.

	Common POV issues include:
	- Head-hopping: Shifting between characters' internal thoughts without clear transitions
	- Knowledge violations: POV character knowing things they couldn't know
	- Perspective leaks: Third-person limited revealing other characters' thoughts
	- Tense inconsistencies related to POV
	- First-person narrators describing their own appearance unnaturally

	For third-person limited:
	- Only the POV character's thoughts should be directly accessible
	- Other characters' emotions should be inferred from external observations
	- The narrator should stay close to the POV character's perspective

	For first-person:
	- Everything should be filtered through the narrator's perception
	- The narrator cannot know others' thoughts unless told
	- Self-descriptions should feel natural to the character

	Analyze the text for POV consistency based on the declared POV type.
	Flag any slips and suggest how to fix them.
`;

const TONE_SYSTEM_PROMPT = dedent`
	You are an expert fiction editor specializing in tone and emotional arc analysis.
	Your task is to analyze the emotional texture and tension of a scene.

	Consider these tone categories:
	- Suspenseful, Tense, Anxious
	- Romantic, Intimate, Passionate
	- Melancholic, Sad, Grieving
	- Humorous, Light, Playful
	- Dark, Ominous, Foreboding
	- Hopeful, Optimistic, Uplifting
	- Nostalgic, Reflective, Contemplative
	- Angry, Confrontational, Aggressive

	When analyzing tension:
	- 0-2: Calm, peaceful, low stakes
	- 3-4: Mild tension, anticipation
	- 5-6: Moderate tension, conflict brewing
	- 7-8: High tension, active conflict
	- 9-10: Peak tension, climactic moments

	Track the emotional arc by identifying how tension and emotion change through the text.
	Note any jarring shifts that might need smoothing.
`;

const CONSISTENCY_SYSTEM_PROMPT = dedent`
	You are an expert fiction editor specializing in narrative consistency.
	Your task is to identify inconsistencies in character behavior, timeline, and established facts.

	Look for:
	1. Character inconsistencies:
	   - Actions contradicting established personality
	   - Skills appearing/disappearing
	   - Relationship dynamics shifting without explanation
	   - Speech patterns changing unexpectedly

	2. Timeline issues:
	   - Events happening out of order
	   - Time jumps that don't make sense
	   - Characters being in two places at once
	   - Day/night inconsistencies

	3. Factual contradictions:
	   - Physical descriptions changing
	   - Setting details conflicting
	   - Rules of the world being broken
	   - Established backstory being contradicted

	Compare the current scene against provided context (previous scenes, character info).
	Flag any inconsistencies you find.
`;

// =============================================================================
// Routes
// =============================================================================

const app = new Hono()
	.use('*', auth)
	.post('/api/analyze/show-tell', async (c) => {
		const decision = await aj.protect(c.req.raw, { requested: 5 });
		if (decision.isDenied() && decision.reason.isRateLimit()) {
			return c.json({ error: 'Too many requests' }, 429);
		}

		try {
			const body = await c.req.json();
			const { content, scene_context = '' } = body;

			if (!content || typeof content !== 'string') {
				return c.json({ error: 'Content is required and must be a string' }, 400);
			}

			const client = create_model(MODELS.ANALYSIS);

			const user_prompt = scene_context
				? `Scene context: ${scene_context}\n\nText to analyze:\n${content}`
				: content;

			const result = await generateObject({
				model: client,
				schema: ShowTellResponseSchema,
				system: SHOW_TELL_SYSTEM_PROMPT,
				prompt: user_prompt,
				temperature: AI_DEFAULTS.temperature
			});

			return c.json(result.object);
		} catch (error) {
			console.error('Show/Tell analysis error:', error);
			return c.json({ error: 'Failed to analyze show vs tell' }, 500);
		}
	})
	.post('/api/analyze/pov', async (c) => {
		const decision = await aj.protect(c.req.raw, { requested: 5 });
		if (decision.isDenied() && decision.reason.isRateLimit()) {
			return c.json({ error: 'Too many requests' }, 429);
		}

		try {
			const body = await c.req.json();
			const { content, declared_pov, pov_character } = body;

			if (!content || typeof content !== 'string') {
				return c.json({ error: 'Content is required and must be a string' }, 400);
			}

			if (!declared_pov || !['first', 'third_limited', 'third_omniscient'].includes(declared_pov)) {
				return c.json(
					{ error: 'declared_pov must be one of: first, third_limited, third_omniscient' },
					400
				);
			}

			const client = create_model(MODELS.ANALYSIS);

			const pov_context = pov_character
				? `Declared POV: ${declared_pov}, POV Character: ${pov_character}`
				: `Declared POV: ${declared_pov}`;

			const user_prompt = `${pov_context}\n\nText to analyze:\n${content}`;

			const result = await generateObject({
				model: client,
				schema: POVResponseSchema,
				system: POV_SYSTEM_PROMPT,
				prompt: user_prompt,
				temperature: AI_DEFAULTS.temperature
			});

			return c.json(result.object);
		} catch (error) {
			console.error('POV analysis error:', error);
			return c.json({ error: 'Failed to analyze POV consistency' }, 500);
		}
	})
	.post('/api/analyze/tone', async (c) => {
		const decision = await aj.protect(c.req.raw, { requested: 5 });
		if (decision.isDenied() && decision.reason.isRateLimit()) {
			return c.json({ error: 'Too many requests' }, 429);
		}

		try {
			const body = await c.req.json();
			const { content, intended_tone } = body;

			if (!content || typeof content !== 'string') {
				return c.json({ error: 'Content is required and must be a string' }, 400);
			}

			const client = create_model(MODELS.ANALYSIS);

			const tone_context = intended_tone
				? `The author intended this scene to feel: ${intended_tone}\n\n`
				: '';

			const user_prompt = `${tone_context}Text to analyze:\n${content}`;

			const result = await generateObject({
				model: client,
				schema: ToneResponseSchema,
				system: TONE_SYSTEM_PROMPT,
				prompt: user_prompt,
				temperature: AI_DEFAULTS.temperature
			});

			return c.json(result.object);
		} catch (error) {
			console.error('Tone analysis error:', error);
			return c.json({ error: 'Failed to analyze tone' }, 500);
		}
	})
	.post('/api/analyze/consistency', async (c) => {
		const decision = await aj.protect(c.req.raw, { requested: 10 });
		if (decision.isDenied() && decision.reason.isRateLimit()) {
			return c.json({ error: 'Too many requests' }, 429);
		}

		try {
			const body = await c.req.json();
			const { current_scene, previous_scenes = [], characters = [], established_facts = [] } = body;

			if (!current_scene || typeof current_scene !== 'string') {
				return c.json({ error: 'current_scene is required and must be a string' }, 400);
			}

			const client = create_model(MODELS.ANALYSIS);

			// Build context
			const context_parts: string[] = [];

			if (characters.length > 0) {
				const char_info = characters
					.map(
						(char: { name: string; traits: string[] }) => `${char.name}: ${char.traits.join(', ')}`
					)
					.join('\n');
				context_parts.push(`Characters:\n${char_info}`);
			}

			if (established_facts.length > 0) {
				context_parts.push(`Established facts:\n- ${established_facts.join('\n- ')}`);
			}

			if (previous_scenes.length > 0) {
				const prev_text = previous_scenes
					.map((scene: string, i: number) => `Previous scene ${i + 1}:\n${scene}`)
					.join('\n\n');
				context_parts.push(prev_text);
			}

			const full_context =
				context_parts.length > 0
					? context_parts.join('\n\n---\n\n')
					: 'No additional context provided.';

			const user_prompt = `Context:\n${full_context}\n\n---\n\nCurrent scene to analyze:\n${current_scene}`;

			const result = await generateObject({
				model: client,
				schema: ConsistencyResponseSchema,
				system: CONSISTENCY_SYSTEM_PROMPT,
				prompt: user_prompt,
				temperature: AI_DEFAULTS.temperature
			});

			return c.json(result.object);
		} catch (error) {
			console.error('Consistency analysis error:', error);
			return c.json({ error: 'Failed to analyze consistency' }, 500);
		}
	});

export default app;
