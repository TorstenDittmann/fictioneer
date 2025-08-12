<script lang="ts">
	const current_year = new Date().getFullYear();
</script>

<footer class="border-t border-paper-border bg-paper-beige px-4 py-12">
	<div class="mx-auto max-w-7xl">
		<div class="mb-8 grid grid-cols-1 gap-8 md:grid-cols-4">
			<!-- Brand -->
			<div class="md:col-span-2">
				<h3 class="mb-4 font-serif text-2xl text-paper-accent">Fictioneer</h3>
				<p class="mb-4 text-sm text-paper-text-light">
					The distraction-free writing environment for novelists who value focus, flow, and the
					craft of storytelling.
				</p>
			</div>

			<!-- Quick Links -->
			<div>
				<h4 class="mb-4 font-semibold text-paper-text">Product</h4>
				<ul class="space-y-2">
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
							href="#waitlist"
							class="text-sm text-paper-text-light transition-colors hover:text-paper-accent"
						>
							Join Waitlist
						</a>
					</li>
					<li>
						<button
							class="text-left text-sm text-paper-text-light transition-colors hover:text-paper-accent"
						>
							Pricing (Coming Soon)
						</button>
					</li>
				</ul>
			</div>

			<!-- Support -->
			<div>
				<h4 class="mb-4 font-semibold text-paper-text">Support</h4>
				<ul class="space-y-2">
					<li>
						<button
							class="text-left text-sm text-paper-text-light transition-colors hover:text-paper-accent"
						>
							Documentation
						</button>
					</li>
					<li>
						<button
							class="text-left text-sm text-paper-text-light transition-colors hover:text-paper-accent"
						>
							Contact
						</button>
					</li>
					<li>
						<button
							class="text-left text-sm text-paper-text-light transition-colors hover:text-paper-accent"
						>
							Blog
						</button>
					</li>
				</ul>
			</div>
		</div>

		<!-- Bottom bar -->
		<div
			class="flex flex-col items-center justify-between gap-4 border-t border-paper-border pt-8 md:flex-row"
		>
			<p class="text-sm text-paper-text-muted">
				© {current_year} Fictioneer. All rights reserved.
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
