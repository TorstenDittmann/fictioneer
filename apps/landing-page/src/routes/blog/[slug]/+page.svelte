<script lang="ts">
        import type { PageData } from './$types';
        import { resolve } from '$app/paths';
        import ExMarkdown from 'svelte-exmarkdown';

        const { data } = $props<{ data: PageData }>();
        const date_formatter = new Intl.DateTimeFormat('en', {
                month: 'long',
                day: 'numeric',
                year: 'numeric'
        });
</script>

<svelte:head>
        <title>{data.post.title} — Fictioneer Blog</title>
        <meta name="description" content={data.post.excerpt} />
        <meta property="og:title" content={data.post.title} />
        <meta property="og:description" content={data.post.excerpt} />
        <meta property="og:type" content="article" />
        <meta property="article:published_time" content={data.post.published_at} />
</svelte:head>

<section class="bg-paper-cream text-paper-text">
        <div class="mx-auto max-w-4xl px-6 py-16">
                <div class="text-sm font-medium uppercase tracking-wide text-paper-text-muted">
                        <a class="text-paper-gold no-underline" href={resolve('/blog')}>
                                ← Back to all posts
                        </a>
                </div>
                <div class="mt-6 flex flex-wrap items-center gap-3 text-sm text-paper-text-muted">
                        <span>{date_formatter.format(new Date(data.post.published_at))}</span>
                        <span>•</span>
                        <span>{data.post.reading_time_minutes} min read</span>
                        <span>•</span>
                        <span class="flex flex-wrap gap-2">
                                {#each data.post.tags as tag}
                                        <span class="rounded-full bg-paper-gray/50 px-3 py-1 text-xs uppercase tracking-wide">
                                                {tag}
                                        </span>
                                {/each}
                        </span>
                </div>
                <h1 class="mt-6 text-4xl font-serif leading-tight sm:text-5xl">{data.post.title}</h1>
                <p class="mt-4 text-lg text-paper-text-muted">{data.post.excerpt}</p>
        </div>
</section>

<section class="bg-white">
<div class="blog-content mx-auto max-w-3xl px-6 py-12">
<ExMarkdown source={data.post.content} />
</div>
</section>
