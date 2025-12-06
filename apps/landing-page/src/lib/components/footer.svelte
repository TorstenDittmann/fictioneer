<script lang="ts">
	import { resolve } from '$app/paths';

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
						class="flex h-9 w-9 items-center justify-center rounded-xl bg-gradient-to-br from-paper-accent to-paper-iris p-0.5"
					>
						<div class="flex h-full w-full items-center justify-center rounded-[10px] bg-white">
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
					<button
						class="flex h-9 w-9 items-center justify-center rounded-lg border border-paper-border bg-white/60 text-paper-text-muted transition-all hover:border-paper-accent hover:text-paper-accent"
						aria-label="Twitter"
					>
						<svg class="h-4 w-4" fill="currentColor" viewBox="0 0 24 24">
							<path
								d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"
							></path>
						</svg>
					</button>
					<button
						class="flex h-9 w-9 items-center justify-center rounded-lg border border-paper-border bg-white/60 text-paper-text-muted transition-all hover:border-paper-accent hover:text-paper-accent"
						aria-label="GitHub"
					>
						<svg class="h-4 w-4" fill="currentColor" viewBox="0 0 24 24">
							<path
								d="M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.531 1.032 1.531 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.202 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.92.678 1.855 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0022 12.017C22 6.484 17.522 2 12 2z"
							></path>
						</svg>
					</button>
				</div>
			</div>

			<!-- Product Links -->
			<div>
				<h4 class="mb-4 text-sm font-semibold text-paper-text">Product</h4>
				<ul class="space-y-2.5">
					<li>
						<a
							href="#features"
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
						<button class="text-sm text-paper-text-light transition-colors hover:text-paper-accent">
							Blog
						</button>
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

			<div class="flex gap-6">
				<button class="text-sm text-paper-text-muted transition-colors hover:text-paper-accent">
					Privacy Policy
				</button>
				<button class="text-sm text-paper-text-muted transition-colors hover:text-paper-accent">
					Terms of Service
				</button>
			</div>
		</div>
	</div>
</footer>
