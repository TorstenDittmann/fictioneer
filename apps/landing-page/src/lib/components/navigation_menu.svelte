<script lang="ts">
	import { NavigationMenu } from 'bits-ui';
	import logo from '$lib/assets/logo.svg';
	import AppleLogo from 'phosphor-svelte/lib/AppleLogo';
	import WindowsLogo from 'phosphor-svelte/lib/WindowsLogo';
	import LinuxLogo from 'phosphor-svelte/lib/LinuxLogo';
	import type { Component } from 'svelte';
	import { resolve } from '$app/paths';

	type DownloadLink = {
		title: string;
		href: string;
		description: string;
		icon: Component;
	};

	type OtherLink = {
		title: string;
		href: string;
		description: string;
	};

	type WebTool = {
		title: string;
		href: string;
		description: string;
	};

	const download_links: DownloadLink[] = [
		{
			title: 'macOS',
			href: '/download',
			description: 'For macOS 11.0 and later',
			icon: AppleLogo
		},
		{
			title: 'Windows',
			href: '/download',
			description: 'For Windows 10 and later',
			icon: WindowsLogo
		},
		{
			title: 'Linux',
			href: '/download',
			description: 'For most modern distributions',
			icon: LinuxLogo
		}
	];

	const web_tools: WebTool[] = [
		{
			title: 'AI Story Generator',
			href: '/tools/ai-story-generator',
			description: 'Generate creative story ideas and plot points with AI.'
		},
		{
			title: 'Character Builder',
			href: '/tools#character-builder',
			description: 'Create detailed character profiles and backstories.'
		},
		{
			title: 'Plot Outliner',
			href: '/tools#plot-outliner',
			description: 'Structure your story with AI-powered outlining tools.'
		},
		{
			title: 'Writing Prompts',
			href: '/tools#prompts',
			description: 'Get inspired with AI-generated writing prompts.'
		}
	];

	const other_links: OtherLink[] = [
		{
			title: 'Blog',
			href: '/blog',
			description: 'Writing tips, updates, and insights from our team.'
		},
		{
			title: 'FAQ',
			href: '/faq',
			description: 'Frequently asked questions about Fictioneer.'
		}
	];
</script>

{#snippet download_link({ title, href, description, icon }: DownloadLink)}
	{@const Icon = icon}
	<li>
		<NavigationMenu.Link
			{href}
			class="block space-y-1 rounded-lg p-3 leading-none no-underline select-none hover:bg-paper-gray/60 focus:bg-paper-gray/60 focus:outline-none"
		>
			<div class="flex items-center gap-2 text-base leading-none font-medium text-paper-text">
				<Icon />
				{title}
			</div>
			<p class="text-base leading-snug text-paper-text-muted">
				{description}
			</p>
		</NavigationMenu.Link>
	</li>
{/snippet}

{#snippet other_link({ title, href, description }: OtherLink)}
	<li>
		<NavigationMenu.Link
			{href}
			class="block space-y-1 rounded-lg p-3 leading-none no-underline select-none hover:bg-paper-gray/60 focus:bg-paper-gray/60 focus:outline-none"
		>
			<div class="text-base leading-none font-medium text-paper-text">{title}</div>
			<p class="line-clamp-2 text-base leading-snug text-paper-text-muted">
				{description}
			</p>
		</NavigationMenu.Link>
	</li>
{/snippet}

{#snippet web_tool_link({ title, href, description }: WebTool)}
	<li>
		<NavigationMenu.Link
			{href}
			class="block space-y-1 rounded-lg p-3 leading-none no-underline select-none hover:bg-paper-gray/60 focus:bg-paper-gray/60 focus:outline-none"
		>
			<div class="text-base leading-none font-medium text-paper-text">{title}</div>
			<p class="line-clamp-2 text-base leading-snug text-paper-text-muted">
				{description}
			</p>
		</NavigationMenu.Link>
	</li>
{/snippet}

<nav
	class="fixed top-0 right-0 left-0 z-50"
>
	<div class="absolute inset-0 bg-gradient-to-b from-white/80 via-white/55 to-white/40 backdrop-blur-xl"></div>
	<div class="absolute inset-0" style:background="var(--gradient-radial)"></div>
	<div class="absolute inset-0 bg-[radial-gradient(circle_at_top_left,rgba(124,140,255,0.12),transparent_45%)]"></div>

	<div class="relative mx-auto flex max-w-7xl items-center gap-4 px-6 py-4">
		<a
			href={resolve('/')}
			class="glass inline-flex items-center gap-3 rounded-full px-4 py-2 text-sm font-semibold text-paper-text shadow-sm transition-smooth hover:-translate-y-0.5 hover:shadow-lg"
		>
			<img src={logo} alt="Fictioneer Logo" class="h-8 w-8" />
			<span class="tracking-tight">Fictioneer</span>
		</a>

		<!-- Navigation Menu - Centered -->
		<NavigationMenu.Root class="relative z-10 flex flex-1 justify-center">
			<NavigationMenu.List class="glass-strong flex list-none items-center gap-1 rounded-full px-2 py-1">
				<NavigationMenu.Item>
					<NavigationMenu.Link
						href="/pricing"
						class="inline-flex h-11 w-max items-center justify-center rounded-full px-4 text-sm font-semibold text-paper-text hover:bg-paper-gray/60 focus:bg-paper-gray/60 focus:outline-none"
					>
						Pricing
					</NavigationMenu.Link>
				</NavigationMenu.Item>

				<NavigationMenu.Item value="download">
					<NavigationMenu.Trigger
						class="inline-flex h-11 w-max items-center justify-center gap-1 rounded-full px-4 text-sm font-semibold text-paper-text hover:bg-paper-gray/60 focus:bg-paper-gray/60 focus:outline-none data-[state=open]:bg-white/50"
					>
						Download
						<svg
							class="relative h-3 w-3"
							aria-hidden="true"
							fill="none"
							stroke="currentColor"
							viewBox="0 0 24 24"
						>
							<path
								stroke-linecap="round"
								stroke-linejoin="round"
								stroke-width="2"
								d="M19 9l-7 7-7-7"
							></path>
						</svg>
					</NavigationMenu.Trigger>
					<NavigationMenu.Content
						class="data-[motion=from-end]:animate-enter-from-right data-[motion=from-start]:animate-enter-from-left data-[motion=to-end]:animate-exit-to-right data-[motion=to-start]:animate-exit-to-left absolute top-0 left-0 w-full sm:w-auto"
					>
						<ul
							class="m-0 grid list-none gap-2 rounded-2xl border border-white/60 bg-white/70 p-4 shadow-xl backdrop-blur-xl sm:w-[320px]"
						>
							{#each download_links as link (link.title)}
								{@render download_link(link)}
							{/each}
						</ul>
					</NavigationMenu.Content>
				</NavigationMenu.Item>

				<NavigationMenu.Item value="other">
					<NavigationMenu.Trigger
						class="inline-flex h-11 w-max items-center justify-center gap-1 rounded-full px-4 text-sm font-semibold text-paper-text hover:bg-paper-gray/60 focus:bg-paper-gray/60 focus:outline-none data-[state=open]:bg-white/50"
					>
						Other
						<svg
							class="relative h-3 w-3"
							aria-hidden="true"
							fill="none"
							stroke="currentColor"
							viewBox="0 0 24 24"
						>
							<path
								stroke-linecap="round"
								stroke-linejoin="round"
								stroke-width="2"
								d="M19 9l-7 7-7-7"
							></path>
						</svg>
					</NavigationMenu.Trigger>
					<NavigationMenu.Content
						class="data-[motion=from-end]:animate-enter-from-right data-[motion=from-start]:animate-enter-from-left data-[motion=to-end]:animate-exit-to-right data-[motion=to-start]:animate-exit-to-left absolute top-0 left-0 w-full sm:w-auto"
					>
						<div
							class="rounded-2xl border border-white/60 bg-white/75 p-4 shadow-2xl backdrop-blur-xl sm:w-[520px]"
						>
							<!-- Regular Links -->
							<ul class="m-0 mb-4 grid list-none gap-2 border-b border-paper-gray pb-4">
								{#each other_links as link (link.href)}
									{@render other_link(link)}
								{/each}
							</ul>

							<!-- Web Tools Submenu -->
							<div>
								<div
									class="mb-2 px-3 text-xs font-semibold uppercase tracking-wider text-paper-text-muted"
								>
									Web Tools
								</div>
								<ul class="m-0 grid list-none gap-2 sm:grid-cols-2">
									{#each web_tools as tool (tool.href)}
										{@render web_tool_link(tool)}
									{/each}
								</ul>
							</div>
						</div>
					</NavigationMenu.Content>
				</NavigationMenu.Item>

				<!-- Indicator -->
				<NavigationMenu.Indicator
					class="data-[state=visible]:animate-fade-in data-[state=hidden]:animate-fade-out top-full z-10 flex h-2 items-end justify-center overflow-hidden transition-all duration-200 data-[state=hidden]:opacity-0"
				>
					<div class="relative top-[70%] h-2 w-2 rotate-45 rounded-tl-sm bg-white/70"></div>
				</NavigationMenu.Indicator>
			</NavigationMenu.List>

			<!-- Viewport -->
			<div class="absolute top-full left-0 flex w-full justify-center perspective-[2000px]">
				<NavigationMenu.Viewport
					class="origin-top-center data-[state=open]:animate-scale-in data-[state=closed]:animate-scale-out relative mt-3 overflow-hidden rounded-2xl border border-white/70 shadow-xl backdrop-blur-xl transition-all duration-200"
					style="width: var(--bits-navigation-menu-viewport-width); height: var(--bits-navigation-menu-viewport-height);"
				/>
			</div>
		</NavigationMenu.Root>

		<a href={resolve('/download')} class="hidden sm:inline-flex btn-primary text-sm">
			<span class="flex items-center gap-2">
				Download
				<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
					<path
						stroke-linecap="round"
						stroke-linejoin="round"
						stroke-width="2"
						d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"
					></path>
				</svg>
			</span>
		</a>
	</div>
</nav>
