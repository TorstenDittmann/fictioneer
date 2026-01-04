<script lang="ts">
	import { resolve } from '$app/paths';
</script>

<svelte:head>
	<title>Privacy Policy - Fictioneer</title>
	<meta
		name="description"
		content="Learn how Fictioneer protects your privacy and handles your data."
	/>
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
				Privacy Policy
			</h1>
			<p class="animate-fade-in-up mt-4 text-paper-text-light" style:animation-delay="0.1s">
				Last updated: January 2, 2025
			</p>
		</div>

		<!-- Content -->
		<div class="prose prose-paper animate-fade-in-up" style:animation-delay="0.2s">
			<div class="card-elevated space-y-8 p-8">
				<section>
					<h2 class="font-serif text-xl font-semibold text-paper-text">Overview</h2>
					<p class="mt-3 text-paper-text-light">
						Fictioneer is built with privacy as a core principle. Your writing stays on your device,
						and we collect only what's necessary to provide our services.
					</p>
				</section>

				<section>
					<h2 class="font-serif text-xl font-semibold text-paper-text">Data We Collect</h2>
					<div class="mt-3 space-y-4 text-paper-text-light">
						<div>
							<h3 class="font-medium text-paper-text">Your Writing</h3>
							<p>
								All your stories, chapters, scenes, and notes are stored locally on your device in
								<code>.fictioneer</code> files. We never have access to your creative work.
							</p>
						</div>
						<div>
							<h3 class="font-medium text-paper-text">AI Tools Subscription</h3>
							<p>
								If you subscribe to AI Tools, we collect your email address and payment information
								(processed securely by DodoPayments). When you use AI features, your text is sent to
								our servers for processing but is not stored after the response is generated.
							</p>
						</div>
						<div>
							<h3 class="font-medium text-paper-text">Analytics</h3>
							<p>
								We use privacy-focused analytics to understand how our website and app are used.
								This data is anonymized and helps us improve Fictioneer.
							</p>
						</div>
					</div>
				</section>

				<section>
					<h2 class="font-serif text-xl font-semibold text-paper-text">How We Use Your Data</h2>
					<ul class="mt-3 list-inside list-disc space-y-2 text-paper-text-light">
						<li>To provide and maintain our services</li>
						<li>To process your subscription payments</li>
						<li>To send important updates about your account</li>
						<li>To improve our products based on usage patterns</li>
					</ul>
				</section>

				<section>
					<h2 class="font-serif text-xl font-semibold text-paper-text">Data Sharing</h2>
					<p class="mt-3 text-paper-text-light">
						We do not sell your personal information. We only share data with:
					</p>
					<ul class="mt-2 list-inside list-disc space-y-2 text-paper-text-light">
						<li>DodoPayments for payment processing</li>
						<li>AI service providers to process AI feature requests (text is not stored)</li>
					</ul>
				</section>

				<section>
					<h2 class="font-serif text-xl font-semibold text-paper-text">Your Rights</h2>
					<p class="mt-3 text-paper-text-light">You have the right to:</p>
					<ul class="mt-2 list-inside list-disc space-y-2 text-paper-text-light">
						<li>Access your personal data</li>
						<li>Delete your account and associated data</li>
						<li>Export your data</li>
						<li>Opt out of marketing communications</li>
					</ul>
				</section>

				<section>
					<h2 class="font-serif text-xl font-semibold text-paper-text">Contact</h2>
					<p class="mt-3 text-paper-text-light">
						For privacy-related questions, contact us at
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
