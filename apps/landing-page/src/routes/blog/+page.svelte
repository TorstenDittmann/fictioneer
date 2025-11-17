<script lang="ts">
        import { resolve } from '$app/paths';

        let { data } = $props();
        const posts = $derived(data.posts);
        const date_formatter = new Intl.DateTimeFormat('en', {
                month: 'long',
                day: 'numeric',
                year: 'numeric'
        });

        const format_date = (value: string) => date_formatter.format(new Date(value));
</script>

<svelte:head>
        <title>Fictioneer Blog — Writing workflows, product updates, and creator tips</title>
        <meta
                name="description"
                content="Read the latest Fictioneer updates, writing workflows, and productivity systems for novelists."
        />
        <link rel="canonical" href="https://fictioneer.app/blog" />
</svelte:head>

<section class="bg-paper-cream px-6 py-24">
        <div class="mx-auto max-w-4xl text-center">
                <p class="text-base font-semibold uppercase tracking-[0.3em] text-paper-text-muted">Fictioneer Blog</p>
                <h1 class="mt-6 text-4xl font-bold text-paper-text sm:text-5xl">
                        Essays, updates, and practical systems for finishing your book
                </h1>
                <p class="mt-6 text-lg leading-relaxed text-paper-text-light">
                        We interview authors, share the product roadmap, and document the craft lessons we learn while building
                        Fictioneer. Grab a cup of coffee and dive in.
                </p>
        </div>
</section>

<section class="bg-paper-white px-6 pb-28">
        <div class="mx-auto grid max-w-6xl gap-8 md:grid-cols-2">
                {#each posts as post (post.slug)}
                        <article class="group flex flex-col overflow-hidden rounded-3xl border border-paper-border bg-white shadow-sm">
                                <div class={`h-40 w-full bg-gradient-to-br ${post.cover_theme}`}></div>
                                <div class="flex flex-1 flex-col p-8">
                                        <div class="flex items-center gap-3 text-sm font-semibold uppercase tracking-wide text-paper-text-muted">
                                                <span>{format_date(post.date)}</span>
                                                <span class="h-1 w-1 rounded-full bg-paper-text-muted"></span>
                                                <span>{post.read_time}</span>
                                        </div>
                                        <h2 class="mt-4 text-2xl font-bold text-paper-text group-hover:text-paper-accent">
                                                {post.title}
                                        </h2>
                                        <p class="mt-3 flex-1 text-base leading-relaxed text-paper-text-light">{post.summary}</p>
                                        <div class="mt-6 flex flex-wrap gap-2 text-sm font-medium text-paper-text-muted">
                                                {#each post.tags as tag (tag)}
                                                        <span class="rounded-full border border-paper-border px-3 py-1">#{tag}</span>
                                                {/each}
                                        </div>
                                        <a
                                                href={resolve(`/blog/${post.slug}`)}
                                                class="mt-8 inline-flex items-center gap-2 text-base font-semibold text-paper-accent"
                                        >
                                                Read article
                                                <svg
                                                        class="h-4 w-4 transition-transform duration-150 group-hover:translate-x-1"
                                                        viewBox="0 0 24 24"
                                                        fill="none"
                                                        stroke="currentColor"
                                                        stroke-width="2"
                                                        stroke-linecap="round"
                                                        stroke-linejoin="round"
                                                >
                                                        <path d="M5 12h14"></path>
                                                        <path d="M12 5l7 7-7 7"></path>
                                                </svg>
                                        </a>
                                </div>
                        </article>
                {/each}
        </div>
</section>
