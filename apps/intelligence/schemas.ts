import { z } from 'zod';

export const character_names_schema = z.object({
	names: z.array(
		z.object({
			name: z.string().describe('Full character name'),
			origin: z.string().describe('Cultural or linguistic origin'),
			meaning: z.string().describe('Why this name fits the prompt')
		})
	)
});

export const plot_schema = z.object({
	title: z.string().describe('Hooky outline title'),
	logline: z.string().describe('One sentence story summary'),
	beats: z
		.array(
			z.object({
				title: z.string().describe('Beat name'),
				description: z.string().describe('2-3 sentence description'),
				stakes: z.string().describe('What could go wrong')
			})
		)
		.length(3)
});

export const book_titles_schema = z.object({
	titles: z.array(
		z.object({
			title: z.string().describe('Finished book title'),
			hook: z.string().describe('One sentence marketing hook')
		})
	)
});

export const pen_names_schema = z.object({
	pen_names: z.array(
		z.object({
			name: z.string().describe('Signature pseudonym'),
			tagline: z.string().describe('Short branding hook')
		})
	)
});

export const town_names_schema = z.object({
	places: z.array(
		z.object({
			name: z.string().describe('Place name'),
			region: z.string().describe('Region descriptor'),
			description: z.string().describe('1-2 sentences highlighting texture and history'),
			population: z.string().describe('Approximate population')
		})
	)
});

export const fan_fiction_schema = z.object({
	title: z.string().describe('Prompt title'),
	tagline: z.string().describe('Short descriptor'),
	sections: z
		.array(
			z.object({
				heading: z.string().describe('Section title'),
				text: z.string().describe('2-3 sentences')
			})
		)
		.length(3)
});

export const adult_story_schema = z.object({
	title: z.string().describe('Story title'),
	steam: z.string().describe('Heat descriptor'),
	paragraphs: z.array(z.string().describe('2-3 sentences focusing on character chemistry'))
});

export type CharacterNamesResponse = z.infer<typeof character_names_schema>;
export type PlotResponse = z.infer<typeof plot_schema>;
export type BookTitlesResponse = z.infer<typeof book_titles_schema>;
export type PenNamesResponse = z.infer<typeof pen_names_schema>;
export type TownNamesResponse = z.infer<typeof town_names_schema>;
export type FanFictionResponse = z.infer<typeof fan_fiction_schema>;
export type AdultStoryResponse = z.infer<typeof adult_story_schema>;
