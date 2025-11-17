export type BlogPost = {
        slug: string;
        title: string;
        published_at: string;
        reading_time_minutes: number;
        excerpt: string;
        tags: string[];
        content: string;
};

export const blog_posts: BlogPost[] = [
        {
                slug: 'designing-calmer-writing-workflows',
                title: 'Designing calmer writing workflows',
                published_at: '2025-01-11',
                reading_time_minutes: 6,
                excerpt:
                        'How we approach UX for long-form writing and why Fictioneer favors deliberate, distraction-free rituals.',
                tags: ['Product', 'Writing Craft'],
                content: `# Design with less noise

When we prototyped Fictioneer we focused on the routines authors already rely on. Notifications, badges, and ambient pings are distracting in traditional apps, so Fictioneer keeps inputs calm: typography that breathes, spacing that matches a printed manuscript, and panels that only appear when you invite them.

## Rituals over widgets

We learned that the best "feature" is sometimes a well-timed pause. Instead of shipping more chrome, we focus on rhythms—session timers, a single focus mode toggle, and templates that preserve your voice. These rituals keep you accountable while still honoring the weird, wandering parts of drafting.

> Craft thrives when tools fade into the background.

## Upcoming improvements

- More granular manuscript histories for collaborators
- An AI assistant that critiques structure instead of prose
- Better syncing between desktop and the lightweight web dashboard

We are building these updates with the same guardrails: low latency, quick undo, and zero nagging popups. Let us know what ritual you want to protect next.`
        },
        {
                slug: 'ai-companions-for-fiction-writers',
                title: 'AI companions for fiction writers',
                published_at: '2024-12-04',
                reading_time_minutes: 5,
                excerpt:
                        'A behind-the-scenes look at how our intelligence service helps you brainstorm without flattening your voice.',
                tags: ['AI', 'Roadmap'],
                content: `# AI that edits with you

Fictioneer's intelligence service is tuned for long-form narratives. Instead of rewriting entire paragraphs, it nudges the work forward by suggesting scene goals, conflict escalations, or structural fixes. We cap responses to a digestible size so you can keep typing.

## Guardrails we enforce

1. **Local-first drafts.** The desktop app stores your manuscript offline and only sends the minimum context that the model needs.
2. **Critiques over completion.** We prioritize feedback that sharpens intent—"raise the stakes" or "tighten this POV"—rather than ghostwriting.
3. **Transparency.** Every AI suggestion lists the prompt we sent so you can recreate or modify it later.

## What is shipping next

- Inline character consistency checker
- Prompt presets for romance, thriller, and lit fic beats
- API hooks so you can connect custom research notebooks

Tell us which genre-specific helpers you would like to see in the beta!`
        },
        {
                slug: 'shipping-the-fictioneer-public-beta',
                title: 'Shipping the Fictioneer public beta',
                published_at: '2024-10-21',
                reading_time_minutes: 4,
                excerpt:
                        'The milestones that unlocked our cross-platform beta and what you can expect over the next release cycle.',
                tags: ['Product', 'Company'],
                content: `# A calmer beta rollout

We have been in private preview for a few months, refining sync, AI calls, and export tooling. Opening the doors required three big milestones:

- **Deterministic exports.** EPUB, DOCX, and Markdown now match what you see in the editor.
- **Faster sync.** We rewrote our conflict resolver so remote chapters merge in milliseconds.
- **Unified theming.** Light and dark modes are perfectly aligned between desktop and the web dashboard.

## How to join

1. Download the desktop build for your OS.
2. Join the waitlist so we can gradually enable sync and AI slots.
3. Drop feedback in Discord—every rant helps.

We will keep publishing weekly changelog posts here so you always know what changed before you update.`
        }
];

export const get_blog_post = (slug: string) => blog_posts.find((post) => post.slug === slug);
