<script lang="ts">
	import { NavigationMenu } from 'bits-ui';
	import AppleLogo from 'phosphor-svelte/lib/AppleLogo';
	import WindowsLogo from 'phosphor-svelte/lib/WindowsLogo';
	import LinuxLogo from 'phosphor-svelte/lib/LinuxLogo';
	import type { Component } from 'svelte';
	import { asset, resolve } from '$app/paths';

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
			description: 'Generate creative story ideas with AI.'
		},
		{
			title: 'Character Builder',
			href: '/tools/character-name-generator',
			description: 'Create detailed character profiles.'
		},
		{
			title: 'Plot Outliner',
			href: '/tools/plot-generator',
			description: 'Structure your story with AI tools.'
		},
		{
			title: 'More AI Tools',
			href: '/tools',
			description: 'Explore all our AI writing tools.'
		}
	];

	const other_links: OtherLink[] = [
		{
			title: 'Blog',
			href: '/blog',
			description: 'Writing tips, updates, and insights.'
		},
		{
			title: 'FAQ',
			href: '/faq',
			description: 'Frequently asked questions.'
		}
	];
</script>

{#snippet download_link({ title, href, description, icon }: DownloadLink)}
	{@const Icon = icon}
	<li>
		<NavigationMenu.Link
			{href}
			class="group flex items-center gap-3 rounded-xl p-3 transition-all duration-200 hover:bg-paper-beige/60"
		>
			<div
				class="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-paper-accent/10 to-paper-iris/10 text-paper-accent transition-all duration-200 group-hover:from-paper-accent/20 group-hover:to-paper-iris/20"
			>
				<Icon class="h-5 w-5" weight="regular" />
			</div>
			<div class="flex-1">
				<div class="text-sm font-semibold text-paper-text">{title}</div>
				<p class="text-xs text-paper-text-muted">{description}</p>
			</div>
		</NavigationMenu.Link>
	</li>
{/snippet}

{#snippet other_link({ title, href, description }: OtherLink)}
	<li>
		<NavigationMenu.Link
			{href}
			class="group block rounded-xl p-3 transition-all duration-200 hover:bg-paper-beige/60"
		>
			<div class="text-sm font-semibold text-paper-text">{title}</div>
			<p class="mt-0.5 text-xs leading-relaxed text-paper-text-muted">{description}</p>
		</NavigationMenu.Link>
	</li>
{/snippet}

{#snippet web_tool_link({ title, href, description }: WebTool)}
	<li>
		<NavigationMenu.Link
			{href}
			class="group block rounded-xl p-3 transition-all duration-200 hover:bg-paper-beige/60"
		>
			<div class="text-sm font-semibold text-paper-text">{title}</div>
			<p class="mt-0.5 text-xs leading-relaxed text-paper-text-muted">{description}</p>
		</NavigationMenu.Link>
	</li>
{/snippet}

<nav class="fixed top-0 right-0 left-0 z-50 px-4 pt-4">
	<div
		class="glass-strong mx-auto flex max-w-5xl items-center justify-between rounded-2xl px-4 py-2.5"
	>
		<!-- Logo -->
		<a
			href={resolve('/')}
			class="group flex items-center gap-2.5 rounded-xl px-2 py-1.5 transition-all duration-200 hover:bg-paper-beige/50"
		>
			<div
				class="flex h-9 w-9 items-center justify-center rounded-xl bg-gradient-to-br from-paper-accent to-paper-iris p-0.5"
			>
				<div class="flex h-full w-full items-center justify-center rounded-[10px] bg-white">
					<img src={asset('/logo.svg')} alt="Fictioneer Logo" class="h-5 w-5" />
				</div>
			</div>
			<span class="text-[15px] font-semibold tracking-tight text-paper-text">Fictioneer</span>
		</a>

		<!-- Navigation Menu - Center -->
		<NavigationMenu.Root class="relative z-10 hidden md:flex">
			<NavigationMenu.List class="flex items-center gap-1">
				<NavigationMenu.Item>
					<NavigationMenu.Link
						href="/pricing"
						class="inline-flex h-9 items-center rounded-lg px-3.5 text-sm font-medium text-paper-text-light transition-all duration-200 hover:bg-paper-beige/60 hover:text-paper-text"
					>
						Pricing
					</NavigationMenu.Link>
				</NavigationMenu.Item>

				<NavigationMenu.Item value="download">
					<NavigationMenu.Trigger
						class="group inline-flex h-9 items-center gap-1.5 rounded-lg px-3.5 text-sm font-medium text-paper-text-light transition-all duration-200 hover:bg-paper-beige/60 hover:text-paper-text data-[state=open]:bg-paper-beige/60 data-[state=open]:text-paper-text"
					>
						Download
						<svg
							class="h-3.5 w-3.5 text-paper-text-muted transition-transform duration-200 group-data-[state=open]:rotate-180"
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
						<ul class="w-[300px] space-y-1 p-2">
							{#each download_links as link (link.title)}
								{@render download_link(link)}
							{/each}
						</ul>
					</NavigationMenu.Content>
				</NavigationMenu.Item>

				<NavigationMenu.Item value="other">
					<NavigationMenu.Trigger
						class="group inline-flex h-9 items-center gap-1.5 rounded-lg px-3.5 text-sm font-medium text-paper-text-light transition-all duration-200 hover:bg-paper-beige/60 hover:text-paper-text data-[state=open]:bg-paper-beige/60 data-[state=open]:text-paper-text"
					>
						Resources
						<svg
							class="h-3.5 w-3.5 text-paper-text-muted transition-transform duration-200 group-data-[state=open]:rotate-180"
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
						<div class="w-[320px] p-3">
							<!-- Regular Links -->
							<ul class="mb-3 space-y-1 border-b border-paper-border pb-3">
								{#each other_links as link (link.href)}
									{@render other_link(link)}
								{/each}
							</ul>

							<!-- Web Tools -->
							<div>
								<div
									class="mb-2 px-3 text-[11px] font-semibold tracking-wider text-paper-text-muted uppercase"
								>
									AI Tools
								</div>
								<ul class="space-y-1">
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
					class="data-[state=hidden]:animate-fade-out data-[state=visible]:animate-fade-in top-full z-10 flex h-2.5 items-end justify-center overflow-hidden transition-all duration-200 data-[state=hidden]:opacity-0"
				>
					<div
						class="relative top-[60%] h-2.5 w-2.5 rotate-45 rounded-tl-sm bg-white shadow-sm"
					></div>
				</NavigationMenu.Indicator>
			</NavigationMenu.List>

			<!-- Viewport -->
			<div class="absolute top-full right-0 left-0 flex justify-center perspective-[2000px]">
				<NavigationMenu.Viewport
					class="data-[state=closed]:animate-scale-out data-[state=open]:animate-scale-in relative mt-2 h-[var(--bits-navigation-menu-viewport-height)] w-[var(--bits-navigation-menu-viewport-width)] origin-top overflow-hidden rounded-2xl border border-paper-border bg-white/95 shadow-xl backdrop-blur-xl transition-[width,height] duration-200"
				/>
			</div>
		</NavigationMenu.Root>

		<!-- CTA Button -->
		<a href={resolve('/download')} class="btn-primary hidden px-5 py-2 text-sm sm:inline-flex">
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

		<!-- Mobile Menu Button -->
		<button
			class="inline-flex h-9 w-9 items-center justify-center rounded-lg text-paper-text-light transition-colors hover:bg-paper-beige/60 md:hidden"
			aria-label="Menu"
		>
			<svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
				<path
					stroke-linecap="round"
					stroke-linejoin="round"
					stroke-width="2"
					d="M4 6h16M4 12h16M4 18h16"
				/>
			</svg>
		</button>
	</div>
</nav>
