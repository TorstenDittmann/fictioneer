<script lang="ts">
	import { resolve } from '$app/paths';
	import type { PageProps } from './$types';

	let { data }: PageProps = $props();
</script>

<svelte:head>
	<title>Blog - Fictioneer</title>
	<meta
		name="description"
		content="Writing tips, updates, and insights about fiction writing and storytelling."
	/>
</svelte:head>

<div class="relative min-h-screen overflow-hidden">
	<div class="absolute inset-0" style:background="var(--gradient-mesh)"></div>
	<div
		class="aurora-blob-subtle top-[10%] left-[10%] h-[350px] w-[350px] rounded-full bg-paper-accent/15"
	></div>
	<div
		class="aurora-blob-subtle right-[15%] bottom-[20%] h-[400px] w-[400px] rounded-full bg-paper-iris/10"
	></div>

	<div class="relative z-10 mx-auto max-w-4xl px-4 py-16 sm:px-6 lg:py-24">
		<div class="mb-16 text-center">
			<div class="pill animate-fade-in mx-auto mb-6 w-max">
				<span class="h-1.5 w-1.5 rounded-full bg-paper-accent"></span>
				Blog
			</div>
			<h1
				class="animate-fade-in-up mb-4 font-serif text-3xl tracking-tight text-paper-text sm:text-4xl lg:text-5xl"
			>
				Writing Tips & <span class="gradient-text">Updates</span>
			</h1>
			<p class="animate-fade-in-up mx-auto max-w-2xl text-lg text-paper-text-light">
				Tips, trends, and news about Fictioneer and craft of writing.
			</p>
		</div>

		{#if data.posts.length > 0}
			<div class="space-y-8">
				{#each data.posts as post, idx (post.id)}
					<article
						class="animate-fade-in-up card-elevated group overflow-hidden"
						style:animation-delay="{idx * 0.1}s"
					>
						<a href={resolve(`/blog/${post.slug}`)} class="block">
							{#if post.coverImage}
								<div class="relative aspect-video overflow-hidden">
									<img
										src={post.coverImage}
										alt={post.title}
										class="h-full w-full object-cover transition-transform duration-300 group-hover:scale-105"
									/>
								</div>
							{/if}

							<div class="p-8">
								<div class="mb-3 flex items-center gap-3 text-sm text-paper-text-muted">
									<time datetime={new Date(post.publishedAt).toISOString()}>
										{new Date(post.publishedAt).toLocaleDateString('en-US', {
											year: 'numeric',
											month: 'long',
											day: 'numeric'
										})}
									</time>
									{#if post.category}
										<span>•</span>
										<span class="text-paper-accent">{post.category.name}</span>
									{/if}
								</div>

								<h2
									class="mb-3 font-serif text-2xl font-semibold text-paper-text transition-colors group-hover:text-paper-accent"
								>
									{post.title}
								</h2>

								{#if post.description}
									<p class="mb-4 line-clamp-2 text-paper-text-light">{post.description}</p>
								{/if}

								{#if post.tags && post.tags.length > 0}
									<div class="flex flex-wrap gap-2">
										{#each post.tags.slice(0, 3) as tag (tag.id)}
											<span
												class="rounded-full bg-paper-beige px-3 py-1 text-xs font-medium text-paper-text-muted"
											>
												{tag.name}
											</span>
										{/each}
									</div>
								{/if}
							</div>
						</a>
					</article>
				{/each}
			</div>
		{:else}
			<div class="card-elevated p-12 text-center">
				<p class="text-paper-text-muted">No posts published yet. Check back soon!</p>
			</div>
		{/if}
	</div>
</div>
