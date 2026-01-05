<script lang="ts">
	import type { Component } from 'svelte';
	import type { PageProps } from './$types';
	import type { DownloadOption } from './+page.server';
	import AppleLogo from 'phosphor-svelte/lib/AppleLogo';
	import WindowsLogo from 'phosphor-svelte/lib/WindowsLogo';
	import LinuxLogo from 'phosphor-svelte/lib/LinuxLogo';

	let { data }: PageProps = $props();

	function get_icon(platform: DownloadOption['name']): Component {
		switch (platform) {
			case 'mac':
				return AppleLogo;
			case 'windows':
				return WindowsLogo;
			case 'linux':
				return LinuxLogo;
			default:
				return AppleLogo;
		}
	}
</script>

<svelte:head>
	<title>Download Fictioneer - Writing App for Novelists</title>
	<meta
		name="description"
		content="Download Fictioneer for macOS, Windows, and Linux. Start writing your novel with the best distraction-free writing environment."
	/>
</svelte:head>

<div class="mx-auto max-w-6xl px-4 py-16 sm:px-6 lg:py-24">
	<!-- Hero Section -->
	<div class="mb-16 text-center">
		<div class="pill animate-fade-in mx-auto mb-6 w-max">
			<span class="h-1.5 w-1.5 rounded-full bg-paper-lime"></span>
			Available now
		</div>

		<h1
			class="animate-fade-in-up mb-4 font-serif text-3xl tracking-tight text-paper-text sm:text-4xl lg:text-5xl"
		>
			Download <span class="gradient-text">Fictioneer</span>
		</h1>
		<p
			class="animate-fade-in-up mx-auto max-w-2xl text-lg text-paper-text-light"
			style:animation-delay="0.1s"
		>
			Get started with the writing environment designed for novelists. Available for all major
			platforms.
		</p>
	</div>

	<!-- Download Cards -->
	<div class="mb-16 grid gap-5 md:grid-cols-3">
		{#each data.download_options as option, idx (option.platform)}
			{@const Icon = get_icon(option.platform)}
			<div
				class="animate-fade-in-up card-elevated relative overflow-hidden p-6 transition-all duration-300 hover:scale-[1.02] {data.detected_platform ===
				option.platform
					? 'ring-2 ring-paper-accent'
					: ''}"
				style:animation-delay="{0.15 + idx * 0.08}s"
			>
				{#if data.detected_platform === option.platform}
					<div class="absolute top-3 right-3">
						<span class="badge">Detected</span>
					</div>
				{/if}

				<!-- Platform Header -->
				<div class="mb-6 text-center">
					<div
						class="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-2xl bg-linear-to-br from-paper-accent/10 to-paper-iris/10 text-paper-accent"
					>
						<Icon class="h-7 w-7" weight="regular" />
					</div>
					<h3 class="mb-1 font-serif text-xl font-semibold text-paper-text">{option.name}</h3>
					<p class="text-sm text-paper-text-muted">{option.description}</p>
				</div>

				<!-- Download Versions -->
				<div class="space-y-2">
					{#each option.versions as version (version.arch)}
						<!-- eslint-disable svelte/no-navigation-without-resolve-->
						<a
							href={version.url}
							class="group flex items-center justify-between rounded-xl border border-paper-border bg-paper-beige/30 p-3 transition-all hover:border-paper-accent/30 hover:bg-paper-beige/60"
						>
							<span class="text-sm font-medium text-paper-text">{version.arch}</span>
							<svg
								class="h-4 w-4 text-paper-text-muted transition-colors group-hover:text-paper-accent"
								fill="none"
								stroke="currentColor"
								viewBox="0 0 24 24"
							>
								<path
									stroke-linecap="round"
									stroke-linejoin="round"
									stroke-width="2"
									d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"
								></path>
							</svg>
						</a>
					{/each}
				</div>
			</div>
		{/each}
	</div>

	<!-- Info Cards -->
	<div class="grid gap-5 md:grid-cols-2">
		<!-- System Requirements -->
		<div class="animate-fade-in-up card overflow-hidden p-6" style:animation-delay="0.4s">
			<h3 class="mb-4 font-serif text-lg font-semibold text-paper-text">System Requirements</h3>
			<ul class="space-y-3">
				{#each [{ bold: 'macOS:', text: '10.15 Catalina or later' }, { bold: 'Windows:', text: 'Windows 10 or Windows 11' }, { bold: 'Linux:', text: 'Ubuntu 18.04+, Fedora 30+, or equivalent' }, { bold: 'Memory:', text: '2GB RAM minimum, 4GB recommended' }, { bold: 'Storage:', text: '100MB available disk space' }] as req (req.bold)}
					<li class="flex items-start gap-2.5">
						<div
							class="mt-1 flex h-4 w-4 items-center justify-center rounded-full bg-paper-accent/15 text-paper-accent"
						>
							<svg
								class="h-2.5 w-2.5"
								fill="none"
								stroke="currentColor"
								stroke-width="3"
								viewBox="0 0 24 24"
							>
								<path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7"></path>
							</svg>
						</div>
						<span class="text-sm text-paper-text-light">
							<strong class="text-paper-text">{req.bold}</strong>
							{req.text}
						</span>
					</li>
				{/each}
			</ul>
		</div>

		<!-- What's Included -->
		<div class="animate-fade-in-up card overflow-hidden p-6" style:animation-delay="0.45s">
			<h3 class="mb-4 font-serif text-lg font-semibold text-paper-text">What's Included</h3>
			<ul class="space-y-3">
				{#each ['Distraction-free writing interface', 'AI-powered writing assistance', 'Progress tracking & analytics', 'Local storage', 'Export to multiple formats'] as feature (feature)}
					<li class="flex items-start gap-2.5">
						<div
							class="mt-1 flex h-4 w-4 items-center justify-center rounded-full bg-paper-accent/15 text-paper-accent"
						>
							<svg
								class="h-2.5 w-2.5"
								fill="none"
								stroke="currentColor"
								stroke-width="3"
								viewBox="0 0 24 24"
							>
								<path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7"></path>
							</svg>
						</div>
						<span class="text-sm text-paper-text-light">{feature}</span>
					</li>
				{/each}
			</ul>
		</div>
	</div>
</div>
