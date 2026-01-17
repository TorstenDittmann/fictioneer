<script lang="ts">
	import { resolve } from '$app/paths';
	import { theme } from '$lib/stores/theme.svelte';

	const current_year = new Date().getFullYear();
</script>

<footer
	class="relative overflow-hidden border-t border-paper-border bg-paper-beige/50 px-4 py-12 lg:py-16"
>
	<div class="absolute inset-0" style:background="var(--gradient-mesh)" style:opacity="0.5"></div>

	<div class="relative z-10 mx-auto max-w-6xl">
		<div class="grid gap-10 md:grid-cols-4 lg:gap-16">
			<!-- Brand -->
			<div class="md:col-span-2">
				<div class="mb-4 flex items-center gap-2.5">
					<div
						class="flex h-9 w-9 items-center justify-center rounded-xl bg-linear-to-br from-paper-accent to-paper-iris p-0.5"
					>
						<div
							class="flex h-full w-full items-center justify-center rounded-[10px] bg-paper-cream"
						>
							<img src="/logo.svg" alt="Fictioneer" class="h-5 w-5" />
						</div>
					</div>
					<span class="font-serif text-xl font-semibold text-paper-text">Fictioneer</span>
				</div>
				<p class="mb-6 max-w-sm text-sm leading-relaxed text-paper-text-light">
					The distraction-free writing environment for novelists who value focus, flow, and the
					craft of storytelling.
				</p>

				<!-- Social Links -->
				<div class="flex gap-3">
					<a
						href="https://x.com/FictioneerApp"
						target="_blank"
						rel="noopener noreferrer"
						class="flex h-9 w-9 items-center justify-center rounded-lg border border-paper-border bg-paper-cream/60 text-paper-text-muted transition-all hover:border-paper-accent hover:text-paper-accent"
						aria-label="Follow us on X"
					>
						<svg class="h-4 w-4" fill="currentColor" viewBox="0 0 24 24">
							<path
								d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"
							></path>
						</svg>
					</a>
				</div>
			</div>

			<!-- Product Links -->
			<div>
				<h4 class="mb-4 text-sm font-semibold text-paper-text">Product</h4>
				<ul class="space-y-2.5">
					<li>
						<a
							href={resolve('/')}
							class="text-sm text-paper-text-light transition-colors hover:text-paper-accent"
						>
							Features
						</a>
					</li>
					<li>
						<a
							href={resolve('/download')}
							class="text-sm text-paper-text-light transition-colors hover:text-paper-accent"
						>
							Download
						</a>
					</li>
					<li>
						<a
							href={resolve('/pricing')}
							class="text-sm text-paper-text-light transition-colors hover:text-paper-accent"
						>
							Pricing
						</a>
					</li>
				</ul>
			</div>

			<!-- Resources Links -->
			<div>
				<h4 class="mb-4 text-sm font-semibold text-paper-text">Resources</h4>
				<ul class="space-y-2.5">
					<li>
						<a
							href={resolve('/faq')}
							class="text-sm text-paper-text-light transition-colors hover:text-paper-accent"
						>
							FAQ
						</a>
					</li>
					<li>
						<a
							href={resolve('/tools')}
							class="text-sm text-paper-text-light transition-colors hover:text-paper-accent"
						>
							AI Tools
						</a>
					</li>
					<li>
						<a
							href={resolve('/blog')}
							class="text-sm text-paper-text-light transition-colors hover:text-paper-accent"
						>
							Blog
						</a>
					</li>
					<li>
						<a
							href="https://fictioneer.app/account"
							class="text-sm text-paper-text-light transition-colors hover:text-paper-accent"
						>
							Manage Subscription
						</a>
					</li>
				</ul>
			</div>
		</div>

		<!-- Bottom Bar -->
		<div
			class="mt-12 flex flex-col items-center justify-between gap-4 border-t border-paper-border pt-8 md:flex-row"
		>
			<p class="text-sm text-paper-text-muted">
				&copy; {current_year} Fictioneer. All rights reserved.
			</p>

			<div class="flex items-center gap-6">
				<!-- Theme Toggle -->
				<button
					onclick={() => theme.toggle()}
					class="flex h-9 w-9 items-center justify-center rounded-lg border border-paper-border bg-paper-cream/60 text-paper-text-muted transition-all hover:border-paper-accent hover:text-paper-accent"
					aria-label="Toggle theme"
				>
					{#if theme.current === 'dark'}
						<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
							<path
								stroke-linecap="round"
								stroke-linejoin="round"
								stroke-width="2"
								d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z"
							></path>
						</svg>
					{:else}
						<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
							<path
								stroke-linecap="round"
								stroke-linejoin="round"
								stroke-width="2"
								d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z"
							></path>
						</svg>
					{/if}
				</button>

				<a
					href={resolve('/privacy')}
					class="text-sm text-paper-text-muted transition-colors hover:text-paper-accent"
				>
					Privacy Policy
				</a>
				<a
					href={resolve('/terms')}
					class="text-sm text-paper-text-muted transition-colors hover:text-paper-accent"
				>
					Terms of Service
				</a>
			</div>
		</div>
	</div>
</footer>
