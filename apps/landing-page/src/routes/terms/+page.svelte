<script lang="ts">
	import { resolve } from '$app/paths';
</script>

<svelte:head>
	<title>Terms of Service - Fictioneer</title>
	<meta name="description" content="Terms of Service for using Fictioneer." />
</svelte:head>

<div class="relative min-h-screen overflow-hidden">
	<!-- Background -->
	<div class="absolute inset-0" style:background="var(--gradient-mesh)"></div>
	<div
		class="aurora-blob-subtle top-[10%] left-[10%] h-[350px] w-[350px] rounded-full bg-paper-accent/15"
	></div>
	<div
		class="aurora-blob-subtle right-[15%] bottom-[20%] h-[400px] w-[400px] rounded-full bg-paper-iris/10"
	></div>

	<div class="relative z-10 mx-auto max-w-3xl px-4 py-16 sm:px-6 lg:py-24">
		<!-- Hero -->
		<div class="mb-12 text-center">
			<div class="pill animate-fade-in mx-auto mb-6 w-max">
				<span class="h-1.5 w-1.5 rounded-full bg-paper-accent"></span>
				Legal
			</div>
			<h1 class="animate-fade-in-up font-serif text-4xl font-bold text-paper-text">
				Terms of Service
			</h1>
			<p class="animate-fade-in-up mt-4 text-paper-text-light" style:animation-delay="0.1s">
				Last updated: January 2, 2025
			</p>
		</div>

		<!-- Content -->
		<div class="prose prose-paper animate-fade-in-up" style:animation-delay="0.2s">
			<div class="card-elevated space-y-8 p-8">
				<section>
					<h2 class="font-serif text-xl font-semibold text-paper-text">Agreement</h2>
					<p class="mt-3 text-paper-text-light">
						By using Fictioneer, you agree to these terms. If you don't agree, please don't use our
						services.
					</p>
				</section>

				<section>
					<h2 class="font-serif text-xl font-semibold text-paper-text">Using Fictioneer</h2>
					<div class="mt-3 space-y-4 text-paper-text-light">
						<div>
							<h3 class="font-medium text-paper-text">Free Desktop App</h3>
							<p>
								The Fictioneer desktop application is free to use. You may use it for personal or
								commercial writing projects without restriction.
							</p>
						</div>
						<div>
							<h3 class="font-medium text-paper-text">AI Tools Subscription</h3>
							<p>
								AI Tools is an optional paid subscription at $10/month. It includes a 7-day free
								trial. You can cancel anytime through your account portal.
							</p>
						</div>
					</div>
				</section>

				<section>
					<h2 class="font-serif text-xl font-semibold text-paper-text">Your Content</h2>
					<p class="mt-3 text-paper-text-light">
						You own everything you write. Fictioneer does not claim any rights to your stories,
						characters, or ideas. Your work is stored locally on your device and remains yours.
					</p>
				</section>

				<section>
					<h2 class="font-serif text-xl font-semibold text-paper-text">AI-Generated Content</h2>
					<p class="mt-3 text-paper-text-light">
						When using AI Tools, you may use, modify, and publish any AI-generated suggestions in
						your work. You are responsible for reviewing and editing AI suggestions before use.
					</p>
				</section>

				<section>
					<h2 class="font-serif text-xl font-semibold text-paper-text">Payments & Refunds</h2>
					<p class="mt-3 text-paper-text-light">
						AI Tools subscriptions are billed monthly. Due to the nature of digital services and the
						included free trial, we generally do not offer refunds. If you have concerns about a
						charge, please contact us.
					</p>
				</section>

				<section>
					<h2 class="font-serif text-xl font-semibold text-paper-text">Acceptable Use</h2>
					<p class="mt-3 text-paper-text-light">You agree not to:</p>
					<ul class="mt-2 list-inside list-disc space-y-2 text-paper-text-light">
						<li>Use the service for any illegal purpose</li>
						<li>Attempt to reverse engineer or exploit the software</li>
						<li>Share your license key with others</li>
						<li>Use automated systems to abuse the AI features</li>
					</ul>
				</section>

				<section>
					<h2 class="font-serif text-xl font-semibold text-paper-text">Disclaimer</h2>
					<p class="mt-3 text-paper-text-light">
						Fictioneer is provided "as is" without warranties. We do our best to keep the service
						running smoothly, but we can't guarantee uninterrupted access. Please keep backups of
						your important work.
					</p>
				</section>

				<section>
					<h2 class="font-serif text-xl font-semibold text-paper-text">Changes</h2>
					<p class="mt-3 text-paper-text-light">
						We may update these terms occasionally. Continued use of Fictioneer after changes means
						you accept the new terms.
					</p>
				</section>

				<section>
					<h2 class="font-serif text-xl font-semibold text-paper-text">Contact</h2>
					<p class="mt-3 text-paper-text-light">
						Questions? Reach out at
						<a href="mailto:hello@fictioneer.app" class="text-paper-accent hover:underline">
							hello@fictioneer.app
						</a>
					</p>
				</section>
			</div>
		</div>

		<!-- Back Link -->
		<div class="mt-8 text-center">
			<a href={resolve('/')} class="btn-ghost">Back to home</a>
		</div>
	</div>
</div>
