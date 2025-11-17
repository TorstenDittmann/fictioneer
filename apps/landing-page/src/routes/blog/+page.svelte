<script lang="ts">
        import type { PageData } from './$types';
        import { resolve } from '$app/paths';

        const { data } = $props<{ data: PageData }>();
        const date_formatter = new Intl.DateTimeFormat('en', {
                month: 'short',
                day: 'numeric',
                year: 'numeric'
        });

        const format_date = (value: string) => date_formatter.format(new Date(value));
</script>

<svelte:head>
        <title>Fictioneer Blog — updates for focused writers</title>
        <meta
                name="description"
                content="Product updates, AI insights, and writing craft lessons from the Fictioneer team."
        />
</svelte:head>

<section class="bg-paper-cream text-paper-text">
        <div class="mx-auto max-w-5xl px-6 py-24">
                <p class="text-sm font-semibold uppercase tracking-widest text-paper-text-muted">The Fictioneer Blog</p>
                <h1 class="mt-4 max-w-3xl text-4xl font-serif leading-tight sm:text-5xl">
                        Essays, product notes, and writing rituals from the Fictioneer team
                </h1>
                <p class="mt-6 max-w-3xl text-lg text-paper-text-muted">
                        Follow along for calm software updates, AI research, and creative practices that help novelists
                        finish their manuscripts.
                </p>
        </div>
</section>

<section class="bg-white text-paper-text">
        <div class="mx-auto grid max-w-5xl gap-6 px-6 py-16 sm:grid-cols-2">
                {#each data.posts as post (post.slug)}
                        <article class="flex h-full flex-col rounded-3xl border border-paper-border bg-paper-cream p-6">
                                <div class="text-sm font-medium uppercase tracking-wide text-paper-text-muted">
                                        {format_date(post.published_at)} · {post.reading_time_minutes} min read
                                </div>
                                <a
                                        class="mt-3 block text-2xl font-semibold leading-tight text-paper-text no-underline transition-colors hover:text-paper-gold"
                                        href={resolve(`/blog/${post.slug}`)}
                                >
                                        {post.title}
                                </a>
                                <p class="mt-4 flex-1 text-base text-paper-text-muted">{post.excerpt}</p>
                                <div class="mt-6 flex flex-wrap gap-2">
                                        {#each post.tags as tag}
                                                <span class="rounded-full border border-paper-border px-3 py-1 text-xs uppercase tracking-wide">
                                                        {tag}
                                                </span>
                                        {/each}
                                </div>
                                <a
                                        class="mt-6 inline-flex items-center gap-2 text-base font-semibold text-paper-gold no-underline"
                                        href={resolve(`/blog/${post.slug}`)}
                                >
                                        Read the story
                                        <span aria-hidden="true">→</span>
                                </a>
                        </article>
                {/each}
        </div>
</section>
