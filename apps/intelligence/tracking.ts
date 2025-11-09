import { PostHog } from 'posthog-node';

export const posthog = new PostHog('phc_Rnfc8HPFJ1Duqo23ykhIYTivNNB8Mn5v6NqbVUxLJkS', {
	host: 'https://eu.i.posthog.com',
	flushInterval: 15
});
