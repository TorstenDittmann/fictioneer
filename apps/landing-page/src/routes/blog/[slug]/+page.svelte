<script lang="ts">
	import { resolve } from '$app/paths';
	import type { PageProps } from './$types';

	let { data }: PageProps = $props();

	const article_json_ld = $derived(
		JSON.stringify({
			'@context': 'https://schema.org',
			'@type': 'Article',
			headline: data.post.title,
			description: data.post.description || '',
			image: data.post.coverImage || 'https://fictioneer.app/og.png',
			datePublished: new Date(data.post.publishedAt).toISOString(),
			dateModified: new Date(data.post.publishedAt).toISOString(),
			author:
				data.post.authors && data.post.authors.length > 0
					? {
							'@type': 'Person',
							name: data.post.authors[0].name,
							image: data.post.authors[0].image || undefined
						}
					: {
							'@type': 'Organization',
							name: 'Fictioneer'
						},
			publisher: {
				'@type': 'Organization',
				name: 'Fictioneer',
				logo: {
					'@type': 'ImageObject',
					url: 'https://fictioneer.app/logo.svg'
				}
			},
			url: `https://fictioneer.app/blog/${data.post.slug}`,
			mainEntityOfPage: {
				'@type': 'WebPage',
				'@id': `https://fictioneer.app/blog/${data.post.slug}`
			}
		})
	);
</script>

<svelte:head>
	<title>{data.post.title} - Fictioneer</title>
	<meta name="description" content={data.post.description || ''} />
	<link rel="canonical" href={`https://fictioneer.app/blog/${data.post.slug}`} />
	<meta property="og:type" content="article" />
	<meta property="og:title" content={data.post.title} />
	<meta property="og:description" content={data.post.description || ''} />
	<meta property="og:url" content={`https://fictioneer.app/blog/${data.post.slug}`} />
	{#if data.post.coverImage}
		<meta property="og:image" content={data.post.coverImage} />
		<meta property="og:image:alt" content={data.post.title} />
	{/if}
	<meta property="article:published_time" content={new Date(data.post.publishedAt).toISOString()} />
	{#if data.post.category}
		<meta property="article:section" content={data.post.category.name} />
	{/if}
	{#if data.post.tags}
		{#each data.post.tags as tag (tag.id)}
			<meta property="article:tag" content={tag.name} />
		{/each}
	{/if}
	<meta property="twitter:card" content="summary_large_image" />
	<meta property="twitter:title" content={data.post.title} />
	<meta property="twitter:description" content={data.post.description || ''} />
	{#if data.post.coverImage}
		<meta property="twitter:image" content={data.post.coverImage} />
	{/if}
	<!-- eslint-disable-next-line -->
	{@html `${'<'}script type="application/ld+json">${article_json_ld}</script>`}
</svelte:head>

<div class="mx-auto max-w-3xl px-4 py-16 sm:px-6 lg:py-24">
	<a
		href={resolve('/blog')}
		class="mb-8 inline-flex items-center gap-2 text-sm font-medium text-paper-text-light transition-colors hover:text-paper-accent"
	>
		<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
			<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"
			></path>
		</svg>
		Back to Blog
	</a>

	{#if data.post.coverImage}
		<div class="mb-8 aspect-video overflow-hidden rounded-2xl">
			<img src={data.post.coverImage} alt={data.post.title} class="h-full w-full object-cover" />
		</div>
	{/if}

	<div class="mb-4 flex flex-wrap items-center gap-4 text-sm text-paper-text-muted">
		<time datetime={new Date(data.post.publishedAt).toISOString()}>
			{new Date(data.post.publishedAt).toLocaleDateString('en-US', {
				year: 'numeric',
				month: 'long',
				day: 'numeric'
			})}
		</time>
		{#if data.readTime}
			<span>•</span>
			<span>{data.readTime} min read</span>
		{/if}
		{#if data.post.category}
			<span>•</span>
			<span class="text-paper-accent">{data.post.category.name}</span>
		{/if}
	</div>

	<h1 class="mb-6 font-serif text-3xl font-semibold text-paper-text sm:text-4xl lg:text-5xl">
		{data.post.title}
	</h1>

	{#if data.post.description}
		<p class="mb-8 text-xl text-paper-text-light">{data.post.description}</p>
	{/if}

	{#if data.post.authors && data.post.authors.length > 0}
		<div class="mb-8 flex items-center gap-4">
			{#each data.post.authors.slice(0, 1) as author (author.id)}
				{#if author.image}
					<img src={author.image} alt={author.name} class="h-12 w-12 rounded-full object-cover" />
				{/if}
				<div>
					<p class="text-sm font-semibold text-paper-text">{author.name}</p>
					{#if author.role}
						<p class="text-sm text-paper-text-muted">{author.role}</p>
					{/if}
				</div>
			{/each}
		</div>
	{/if}

	<div class="card-elevated mb-8 p-8 sm:p-12">
		<article class="prose">
			<!-- eslint-disable-next-line -->
			{@html data.post.content}
		</article>
	</div>

	{#if data.post.tags && data.post.tags.length > 0}
		<div class="mb-8">
			<p class="mb-3 text-sm font-semibold tracking-wider text-paper-text-muted uppercase">Tags</p>
			<div class="flex flex-wrap gap-2">
				{#each data.post.tags as tag (tag.id)}
					<span
						class="rounded-full bg-paper-beige px-4 py-2 text-sm font-medium text-paper-text-muted"
					>
						{tag.name}
					</span>
				{/each}
			</div>
		</div>
	{/if}
</div>
