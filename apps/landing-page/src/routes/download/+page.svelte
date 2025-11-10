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

<div class="min-h-screen bg-paper-beige pt-24 pb-16">
	<div class="mx-auto max-w-7xl px-6">
		<!-- Hero Section -->
		<div class="mb-16 text-center">
			<h1
				class="mb-6 font-serif text-4xl leading-tight tracking-tight text-paper-text sm:text-5xl md:text-6xl"
			>
				Download <span class="gradient-text">Fictioneer</span>
			</h1>
			<p
				class="mx-auto max-w-2xl text-base text-paper-text-light/90 sm:text-lg md:text-xl"
				style="animation-delay: 0.1s"
			>
				Get started with the writing environment designed for novelists. Available for all major
				platforms.
			</p>
		</div>

		<div class="grid gap-8 md:grid-cols-3">
			{#each data.download_options as option (option.platform)}
				{@const Icon = get_icon(option.platform)}
				<div
					class="glass hover-lift scroll-mt-24 rounded-2xl p-8 transition-all"
					class:ring-2={data.detected_platform === option.platform}
					class:ring-paper-accent={data.detected_platform === option.platform}
				>
					<!-- Platform Header -->
					<div class="mb-6 text-center">
						<div class="mb-3 flex justify-center">
							<Icon class="h-12 w-12 text-paper-accent" weight="fill" />
						</div>
						<h3 class="mb-2 text-2xl font-bold text-paper-text">
							{option.name}
						</h3>
						<p class="text-sm text-paper-text-muted">{option.description}</p>
						{#if data.detected_platform === option.platform}
							<div
								class="mt-3 inline-block rounded-full bg-paper-accent/20 px-3 py-1 text-xs font-medium text-paper-accent"
							>
								Detected Platform
							</div>
						{/if}
					</div>

					<!-- Download Versions -->
					<div class="space-y-3">
						{#each option.versions as version (version.arch)}
							<!-- eslint-disable svelte/no-navigation-without-resolve-->
							<a
								href={version.url}
								class="group w-full rounded-xl border border-paper-border bg-paper-beige/50 p-4 text-left transition-all hover:border-paper-accent/50 hover:bg-paper-gray/30"
							>
								<div class="flex items-center justify-between">
									<span class="font-medium text-paper-text">{version.arch}</span>
									<svg
										class="h-4 w-4 text-paper-accent transition-transform group-hover:translate-x-1"
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
								</div>
							</a>
						{/each}
					</div>
				</div>
			{/each}
		</div>

		<div class="mt-16 grid gap-8 md:grid-cols-2">
			<div
				class="animate-fade-in-up rounded-2xl border border-paper-border bg-paper-cream/30 p-8 backdrop-blur-sm"
				style="animation-delay: 0.6s"
			>
				<h3 class="mb-4 text-xl font-bold text-paper-text">System Requirements</h3>
				<ul class="space-y-3 text-paper-text-light">
					<li class="flex items-start gap-2">
						<svg
							class="mt-1 h-5 w-5 shrink-0 text-paper-accent"
							fill="currentColor"
							viewBox="0 0 20 20"
						>
							<path
								fill-rule="evenodd"
								d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
								clip-rule="evenodd"
							></path>
						</svg>
						<span><strong>macOS:</strong> 11.0 Big Sur or later</span>
					</li>
					<li class="flex items-start gap-2">
						<svg
							class="mt-1 h-5 w-5 shrink-0 text-paper-accent"
							fill="currentColor"
							viewBox="0 0 20 20"
						>
							<path
								fill-rule="evenodd"
								d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
								clip-rule="evenodd"
							></path>
						</svg>
						<span><strong>Windows:</strong> Windows 10 version 1809 or later</span>
					</li>
					<li class="flex items-start gap-2">
						<svg
							class="mt-1 h-5 w-5 shrink-0 text-paper-accent"
							fill="currentColor"
							viewBox="0 0 20 20"
						>
							<path
								fill-rule="evenodd"
								d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
								clip-rule="evenodd"
							></path>
						</svg>
						<span><strong>Linux:</strong> Ubuntu 20.04, Fedora 34, or equivalent</span>
					</li>
					<li class="flex items-start gap-2">
						<svg
							class="mt-1 h-5 w-5 shrink-0 text-paper-accent"
							fill="currentColor"
							viewBox="0 0 20 20"
						>
							<path
								fill-rule="evenodd"
								d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
								clip-rule="evenodd"
							></path>
						</svg>
						<span><strong>Memory:</strong> 4GB RAM minimum, 8GB recommended</span>
					</li>
					<li class="flex items-start gap-2">
						<svg
							class="mt-1 h-5 w-5 shrink-0 text-paper-accent"
							fill="currentColor"
							viewBox="0 0 20 20"
						>
							<path
								fill-rule="evenodd"
								d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
								clip-rule="evenodd"
							></path>
						</svg>
						<span><strong>Storage:</strong> 500MB available disk space</span>
					</li>
				</ul>
			</div>

			<div class="rounded-2xl border border-paper-border bg-paper-cream/30 p-8 backdrop-blur-sm">
				<h3 class="mb-4 text-xl font-bold text-paper-text">What's Included</h3>
				<ul class="space-y-3 text-paper-text-light">
					<li class="flex items-start gap-2">
						<svg
							class="mt-1 h-5 w-5 shrink-0 text-paper-accent"
							fill="currentColor"
							viewBox="0 0 20 20"
						>
							<path
								fill-rule="evenodd"
								d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
								clip-rule="evenodd"
							></path>
						</svg>
						<span>Distraction-free writing interface</span>
					</li>
					<li class="flex items-start gap-2">
						<svg
							class="mt-1 h-5 w-5 shrink-0 text-paper-accent"
							fill="currentColor"
							viewBox="0 0 20 20"
						>
							<path
								fill-rule="evenodd"
								d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
								clip-rule="evenodd"
							></path>
						</svg>
						<span>AI-powered writing assistance</span>
					</li>
					<li class="flex items-start gap-2">
						<svg
							class="mt-1 h-5 w-5 shrink-0 text-paper-accent"
							fill="currentColor"
							viewBox="0 0 20 20"
						>
							<path
								fill-rule="evenodd"
								d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
								clip-rule="evenodd"
							></path>
						</svg>
						<span>Progress tracking & analytics</span>
					</li>
					<li class="flex items-start gap-2">
						<svg
							class="mt-1 h-5 w-5 shrink-0 text-paper-accent"
							fill="currentColor"
							viewBox="0 0 20 20"
						>
							<path
								fill-rule="evenodd"
								d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
								clip-rule="evenodd"
							></path>
						</svg>
						<span>Cloud sync & local storage</span>
					</li>
					<li class="flex items-start gap-2">
						<svg
							class="mt-1 h-5 w-5 shrink-0 text-paper-accent"
							fill="currentColor"
							viewBox="0 0 20 20"
						>
							<path
								fill-rule="evenodd"
								d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
								clip-rule="evenodd"
							></path>
						</svg>
						<span>Export to multiple formats</span>
					</li>
				</ul>
			</div>
		</div>

		<!-- Help Section -->
		<div
			class="animate-fade-in-up mt-16 rounded-2xl border border-paper-border bg-paper-cream/30 p-8 text-center backdrop-blur-sm"
			style="animation-delay: 0.8s"
		>
			<h3 class="mb-3 text-xl font-bold text-paper-text">Need Help?</h3>
			<p class="mb-6 text-paper-text-light">
				Having trouble downloading or installing? Check our documentation or reach out to support.
			</p>
			<div class="flex flex-wrap justify-center gap-4">
				<button
					type="button"
					onclick={() => alert('Documentation coming soon!')}
					class="inline-flex items-center gap-2 rounded-lg border border-paper-accent px-6 py-3 font-medium text-paper-accent transition-colors hover:bg-paper-accent/10"
				>
					Documentation
				</button>
				<button
					type="button"
					onclick={() => alert('Support coming soon!')}
					class="inline-flex items-center gap-2 rounded-lg border border-paper-border px-6 py-3 font-medium text-paper-text transition-colors hover:bg-paper-gray/30"
				>
					Contact Support
				</button>
			</div>
		</div>
	</div>
</div>
