<script lang="ts">
        import { resolve } from '$app/paths';
        import ExMarkdown from 'svelte-exmarkdown';

        let { data } = $props();
        const post = $derived(data.post);
        const date_formatter = new Intl.DateTimeFormat('en', {
                month: 'long',
                day: 'numeric',
                year: 'numeric'
        });
        const formatted_date = $derived(date_formatter.format(new Date(post.date)));
</script>

<svelte:head>
        <title>{post.title} — Fictioneer Blog</title>
        <meta name="description" content={post.summary} />
        <link rel="canonical" href={`https://fictioneer.app/blog/${post.slug}`} />
</svelte:head>

<section class="bg-paper-cream px-6 py-16">
        <div class="mx-auto max-w-4xl space-y-6 text-center">
                        <a
                                href={resolve('/blog')}
                                class="inline-flex items-center gap-2 text-sm font-semibold text-paper-accent"
                        >
                                <svg class="h-4 w-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"
                                        stroke-linecap="round" stroke-linejoin="round"
                                >
                                        <path d="M19 12H5"></path>
                                        <path d="M12 5l-7 7 7 7"></path>
                                </svg>
                                Back to blog
                        </a>
                <p class="text-sm font-semibold uppercase tracking-[0.4em] text-paper-text-muted">Fictioneer Blog</p>
                <h1 class="text-4xl font-bold text-paper-text sm:text-5xl">{post.title}</h1>
                <p class="text-lg leading-relaxed text-paper-text-light">{post.summary}</p>
                <div class="flex flex-wrap items-center justify-center gap-3 text-sm font-semibold uppercase tracking-wide text-paper-text-muted">
                        <span>{formatted_date}</span>
                        <span class="h-1 w-1 rounded-full bg-paper-text-muted"></span>
                        <span>{post.read_time}</span>
                </div>
                <div class="flex flex-wrap justify-center gap-2 text-sm font-medium text-paper-text-muted">
                        {#each post.tags as tag (tag)}
                                <span class="rounded-full border border-paper-border px-3 py-1">#{tag}</span>
                        {/each}
                </div>
        </div>
</section>

<article class="bg-paper-white px-6 pb-24">
        <div class="mx-auto max-w-3xl overflow-hidden rounded-3xl border border-paper-border bg-white shadow-sm">
                <div class={`h-48 w-full bg-gradient-to-br ${post.cover_theme}`}></div>
                <div class="blog-content px-8 py-10">
                        <ExMarkdown source={post.content} />
                </div>
        </div>
</article>
