export type BlogPost = {
        slug: string;
        title: string;
        summary: string;
        date: string;
        read_time: string;
        tags: string[];
        cover_theme: string;
        content: string;
};

export const blog_posts: BlogPost[] = [
        {
                slug: 'fictioneer-writing-workflow',
                title: 'A Focused Workflow for Finishing Your Novel',
                summary:
                        'How we designed Fictioneer to take you from blank page to finished manuscript without losing momentum.',
                date: '2025-02-15',
                read_time: '8 min read',
                tags: ['workflow', 'process', 'product'],
                cover_theme: 'from-amber-100 via-orange-50 to-white',
                content: `# A Focused Workflow for Finishing Your Novel

Writing software should disappear when inspiration strikes. When we designed Fictioneer, we looked at how prolific authors maintain momentum and turned those patterns into a simple workflow you can repeat for every project.

## 1. Capture every idea instantly

- Create unlimited idea cards that stay docked next to your manuscript.
- Tag each idea with characters, locations, or arcs so they are searchable later.
- Convert an idea into a scene with one click, keeping your timeline intact.

> Momentum is lost when you switch tools. Fictioneer keeps brainstorms, outlines, and drafts together so you never copy-paste between apps again.

## 2. Outline with progressive detail

We recommend outlining in three passes:

1. **Beats** – write a sentence or two that captures the emotion of the moment.
2. **Scenes** – expand beats into conflicts, revelations, and hooks.
3. **Prose** – draft directly in focus mode with your outline pinned beside the editor.

Each pass can happen days or weeks apart. Fictioneer tracks your progress, surfacing what still needs attention in your dashboard.

## 3. Review with story-aware goals

Set a deadline, daily word target, or chapter milestone. The progress tracker understands your structure, so adding a new scene updates every stat automatically. When you fall behind, Fictioneer generates a catch-up plan that redistributes your workload based on the remaining outline.

### Bring it all together

A workflow only sticks when it is repeatable. Save your favorite templates, share them with collaborators, and duplicate them for the next book. Fictioneer remembers the metadata—point of view, tense, tone—so you start the next draft ready to write.

Ready to try it? Download the desktop app or explore our free web tools to see how the workflow feels with your story.`
        },
        {
                slug: 'ai-companions-for-authors',
                title: 'Designing AI Companions That Respect Your Voice',
                summary:
                        'A behind-the-scenes look at how Fictioneer blends AI assistance with human creativity without stealing the spotlight.',
                date: '2025-01-22',
                read_time: '7 min read',
                tags: ['ai', 'ethics', 'assistants'],
                cover_theme: 'from-rose-50 via-fuchsia-50 to-white',
                content: `# Designing AI Companions That Respect Your Voice

AI can remove friction, but only if it understands the boundaries of your creative process. We interviewed 40 authors to learn what felt helpful versus intrusive.

## What writers actually want

- **Context-aware suggestions** that reference existing chapters instead of generic tropes.
- **Transparent prompts** so you know exactly what was sent to the model.
- **Short-lived data** that never becomes training material for anyone else.

## Fictioneer's approach

We built three AI companions—Ideation, Draft Doctor, and Continuity Scout—each with a specific job. They work on top of your manuscript, not instead of it.

```mermaid
flowchart LR
    Idea[Ideation]
    Draft[Draft Doctor]
    Continuity[Continuity Scout]
    Manuscript((Your Manuscript))
    Idea --> Manuscript
    Draft --> Manuscript
    Continuity --> Manuscript
```

The assistants only see the text you highlight, and every request is logged so you can trace what changed.

## Guardrails you control

1. Decide whether AI suggestions appear inline or inside a side panel.
2. Require acceptance for every change so nothing slips through unnoticed.
3. Purge previous prompts with a single click if you want a clean slate.

Respect is the default. Fictioneer treats AI like a collaborative editor who answers when called—never a ghostwriter that runs ahead of you.`
        },
        {
                slug: 'fictioneer-public-roadmap',
                title: 'Opening Up the Fictioneer Roadmap',
                summary:
                        'We are sharing upcoming releases, research spikes, and ways for authors to influence what ships next.',
                date: '2024-12-05',
                read_time: '5 min read',
                tags: ['roadmap', 'community'],
                cover_theme: 'from-sky-100 via-indigo-50 to-white',
                content: `# Opening Up the Fictioneer Roadmap

Great tools grow alongside the community that uses them. This month we are publishing a living roadmap that tracks everything from bug fixes to ambitious experiments.

## How to read the board

- **Now**: actively in development with an estimated release window.
- **Next**: shortlisted items that need validation or UX polish.
- **Later**: explorations that depend on partnerships or research.

Each card links to a discussion thread where you can vote, attach examples, or volunteer for betas.

## Highlights for Q1

- **Multi-perspective tracking** – visualize POV distribution per chapter.
- **Audio scene notes** – dictate changes from your phone and sync later.
- **Snippet library** – reuse character descriptions and settings across books.

## Join the conversation

Subscribe to the roadmap to receive monthly digests, or hop into Discord for real-time chats with the team. Your requests truly shape the queue—we score everything by the number of authors impacted and the clarity of the use case.`
        }
];

export const find_blog_post = (slug: string) => blog_posts.find((post) => post.slug === slug);
