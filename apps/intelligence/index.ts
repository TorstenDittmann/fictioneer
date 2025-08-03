import { createGroq } from '@ai-sdk/groq';
import { generateText, streamText } from 'ai';
import dedent from 'dedent';

// Get API key from environment variable
const GROQ_API_KEY = process.env.GROQ_API_KEY;

if (!GROQ_API_KEY) {
	throw new Error('GROQ_API_KEY environment variable is required');
}

// Initialize Groq client with hardcoded model
const MODEL = 'llama-3.1-8b-instant';
const groq = createGroq({
	apiKey: GROQ_API_KEY
});

// Helper to add CORS headers
function add_cors_headers(headers: Record<string, string> = {}) {
	return {
		...headers,
		'Access-Control-Allow-Origin': '*',
		'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
		'Access-Control-Allow-Headers': 'Content-Type, Authorization, Cache-Control, X-Requested-With',
		'Access-Control-Expose-Headers': 'Content-Type, Cache-Control',
		'Access-Control-Max-Age': '86400'
	};
}

// Helper functions
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
		const names = ctx.character_names.filter(name => typeof name === 'string');
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
	const ctx = (context && typeof context === 'object' && context !== null) ? context as Record<string, unknown> : {};
	const instruction_context = (ctx.instruction && typeof ctx.instruction === 'string')
		? `\nSpecial instruction: ${ctx.instruction}`
		: '';

	return dedent`
		You are a creative writing assistant. ${base_context}${instruction_context}
		
		Continue writing from where the <CONTINUE_HERE> tag appears. You may either complete the current sentence (if it's getting too long) or continue with new sentences.
		
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
		
		Return only the text that should be inserted at <CONTINUE_HERE>, with no quotes or explanations.
	`;
}

export default {
	port: process.env.PORT || 3001,
	routes: {
		// Health check
		"/api/health": {
			GET: () => {
				return Response.json(
					{ status: 'ok', timestamp: new Date().toISOString() },
					{ headers: add_cors_headers() }
				);
			}
		},

		// Continue writing with streaming support
		"/api/continue": {
			POST: async (req: Request) => {
				try {
					const body = await req.json();
					const content = body?.content;
					const context = body?.context || {};
					const word_count = typeof body?.word_count === 'number' ? body.word_count : 100;
					const stream = body?.stream === true;

					if (!content || typeof content !== 'string') {
						return Response.json(
							{ error: 'Content is required and must be a string' },
							{ status: 400, headers: add_cors_headers() }
						);
					}

					const client = groq(MODEL);
					const system_prompt = build_system_prompt(context, content, word_count);

					const ctx = (context && typeof context === 'object' && context !== null) ? context as Record<string, unknown> : {};
					const recent_text = (ctx.recent_text && typeof ctx.recent_text === 'string') ? ctx.recent_text : '';
					
					const text_with_marker = recent_text
						? content.replace(recent_text, recent_text + '<CONTINUE_HERE>')
						: content + '<CONTINUE_HERE>';

					const user_prompt = dedent`
						<text>
						${text_with_marker}
						</text>
					`;

					if (stream) {
						// Use AI SDK toTextStreamResponse
						const result = streamText({
							model: client,
							system: system_prompt,
							prompt: user_prompt
						});

						const response = result.toTextStreamResponse();
						
						// Add CORS headers to the streaming response
						response.headers.set('Access-Control-Allow-Origin', '*');
						response.headers.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
						response.headers.set('Access-Control-Allow-Headers', 'Content-Type, Authorization, Cache-Control, X-Requested-With');
						response.headers.set('Access-Control-Expose-Headers', 'Content-Type, Cache-Control');
						
						return response;
					} else {
						// Non-streaming response
						const result = await generateText({
							model: client,
							system: system_prompt,
							prompt: user_prompt
						});

						return Response.json(
							{ text: result.text },
							{ headers: add_cors_headers() }
						);
					}
				} catch (error) {
					console.error('Continue writing error:', error);
					return Response.json(
						{ error: 'Failed to generate continuation' },
						{ status: 500, headers: add_cors_headers() }
					);
				}
			}
		}
	},

	// Handle CORS preflight for all routes
	fetch(req: Request) {
		const url = new URL(req.url);
		
		if (req.method === 'OPTIONS') {
			// Handle preflight for all routes including streaming
			return new Response(null, {
				status: 204,
				headers: add_cors_headers()
			});
		}
		
		// 404 for unmatched routes
		return Response.json(
			{ error: 'Not found' },
			{ status: 404, headers: add_cors_headers() }
		);
	}
};