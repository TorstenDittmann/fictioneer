<script lang="ts">
	import { resolve } from '$app/paths';
	import type { RouteId } from '$app/types';

	type Feature = {
		text: string;
		included: boolean;
	};

	type Plan = {
		name: string;
		price: string;
		period: string;
		description: string;
		features: Feature[];
		cta_text: string;
		cta_href: RouteId;
		highlighted: boolean;
	};

	const plans: Plan[] = [
		{
			name: 'Free',
			price: 'Free',
			period: 'forever',
			description: '',
			features: [
				{ text: 'Distraction-free writing interface', included: true },
				{ text: 'Unlimited projects and chapters', included: true },
				{ text: 'Export to multiple formats', included: true },
				{ text: 'Progress tracking & analytics', included: true },
				{ text: 'Basic AI writing assistance', included: true },
				{ text: 'Advanced AI tools', included: false },
				{ text: 'AI story generation', included: false },
				{ text: 'Character & plot builders', included: false }
			],
			cta_text: 'Download Free',
			cta_href: '/download',
			highlighted: false
		},
		{
			name: 'AI Tools',
			price: '$10',
			period: 'per month',
			description: 'Unlock advanced AI-powered writing tools',
			features: [
				{ text: 'Everything in Free', included: true },
				{ text: 'Advanced AI assistance', included: true },
				{ text: 'Unlimited AI generations', included: true },
				{ text: 'Priority support', included: true },
				{ text: 'Early access to new features', included: true }
			],
			cta_text: 'Subscribe Now',
			cta_href: '/',
			highlighted: true
		}
	];
</script>

<svelte:head>
	<title>Pricing - Fictioneer</title>
	<meta
		name="description"
		content="Fictioneer is free to use. Unlock advanced AI writing tools for $10/month."
	/>
</svelte:head>

<div class="min-h-screen bg-paper-beige pt-24 pb-16">
	<div class="mx-auto max-w-7xl px-6">
		<!-- Hero Section -->
		<div class="mb-16 text-center">
			<h1
				class="animate-fade-in-up mb-6 font-serif text-4xl leading-tight tracking-tight text-paper-text sm:text-5xl md:text-6xl"
			>
				Simple, <span class="gradient-text">Transparent</span> Pricing
			</h1>
			<p
				class="animate-fade-in-up mx-auto max-w-2xl text-base text-paper-text-light/90 sm:text-lg md:text-xl"
				style:animation-delay="0.1s"
			>
				Write your novel for free. Unlock advanced AI tools when you're ready to level up your
				writing.
			</p>
		</div>

		<!-- Pricing Cards -->
		<div class="mx-auto grid max-w-6xl gap-8 lg:grid-cols-2">
			{#each plans as plan, idx (plan.name)}
				<div
					class="animate-fade-in-up relative rounded-2xl border p-8 transition-all {plan.highlighted
						? 'hover-lift border-paper-accent bg-paper-cream shadow-xl'
						: 'border-paper-border bg-paper-cream/30'}"
					style:animation-delay="{0.2 + idx * 0.1}s"
				>
					<!-- Highlighted Badge -->
					{#if plan.highlighted}
						<div
							class="absolute -top-4 left-1/2 -translate-x-1/2 rounded-full bg-paper-accent px-4 py-1 text-xs font-semibold text-paper-beige"
						>
							Most Popular
						</div>
					{/if}

					<!-- Plan Header -->
					<div class="mb-6 text-center">
						{#if plan.description}
							<p class="mb-4 text-sm text-paper-text-muted">{plan.description}</p>
						{/if}
						<div class="flex items-baseline justify-center gap-2">
							<span class="text-5xl font-bold text-paper-text">{plan.price}</span>
							<span class="text-paper-text-muted">/ {plan.period}</span>
						</div>
					</div>

					<!-- Features List -->
					<ul class="mb-8 space-y-3">
						{#each plan.features as feature (feature.text)}
							<li class="flex items-start gap-3">
								{#if feature.included}
									<svg
										class="mt-0.5 h-5 w-5 shrink-0 text-paper-accent"
										fill="currentColor"
										viewBox="0 0 20 20"
									>
										<path
											fill-rule="evenodd"
											d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
											clip-rule="evenodd"
										></path>
									</svg>
								{:else}
									<svg
										class="mt-0.5 h-5 w-5 shrink-0 text-paper-text-muted/40"
										fill="currentColor"
										viewBox="0 0 20 20"
									>
										<path
											fill-rule="evenodd"
											d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
											clip-rule="evenodd"
										></path>
									</svg>
								{/if}
								<span
									class="text-sm {feature.included
										? 'text-paper-text-light'
										: 'text-paper-text-muted/60 line-through'}"
								>
									{feature.text}
								</span>
							</li>
						{/each}
					</ul>

					<!-- CTA Button -->
					<a
						href={resolve(plan.cta_href)}
						class="block w-full rounded-lg py-3 text-center text-sm font-medium transition-all {plan.highlighted
							? 'bg-paper-accent text-paper-beige hover:bg-paper-accent-light'
							: 'border border-paper-accent text-paper-accent hover:bg-paper-accent/10'}"
					>
						{plan.cta_text}
					</a>
				</div>
			{/each}
		</div>

		<!-- FAQ Section -->
		<div class="mx-auto mt-20 max-w-4xl">
			<h2
				class="animate-fade-in-up mb-10 text-center text-3xl font-bold text-paper-text"
				style:animation-delay="0.4s"
			>
				Frequently Asked Questions
			</h2>

			<div class="space-y-6">
				<div
					class="animate-fade-in-up rounded-2xl border border-paper-border bg-paper-cream/30 p-6"
					style:animation-delay="0.5s"
				>
					<h3 class="mb-2 text-lg font-semibold text-paper-text">Is Fictioneer really free?</h3>
					<p class="text-paper-text-light">
						Yes! Fictioneer is completely free to download and use. You get unlimited access to our
						distraction-free writing interface, progress tracking, and basic AI features. No credit
						card required, no trial period – it's free forever.
					</p>
				</div>

				<div
					class="animate-fade-in-up rounded-2xl border border-paper-border bg-paper-cream/30 p-6"
					style:animation-delay="0.6s"
				>
					<h3 class="mb-2 text-lg font-semibold text-paper-text">
						What do I get with the AI Tools subscription?
					</h3>
					<p class="text-paper-text-light">
						The AI Tools subscription unlocks advanced AI features like story generation, character
						building, plot outlining, and unlimited AI-powered suggestions. These tools are designed
						to help you overcome writer's block and develop richer stories.
					</p>
				</div>

				<div
					class="animate-fade-in-up rounded-2xl border border-paper-border bg-paper-cream/30 p-6"
					style:animation-delay="0.7s"
				>
					<h3 class="mb-2 text-lg font-semibold text-paper-text">Can I cancel anytime?</h3>
					<p class="text-paper-text-light">
						Absolutely. You can cancel your AI Tools subscription at any time. No questions asked.
						If you cancel, you'll continue to have access until the end of your billing period, and
						you can still use the free version of Fictioneer forever.
					</p>
				</div>

				<div
					class="animate-fade-in-up rounded-2xl border border-paper-border bg-paper-cream/30 p-6"
					style:animation-delay="0.8s"
				>
					<h3 class="mb-2 text-lg font-semibold text-paper-text">
						What payment methods do you accept?
					</h3>
					<p class="text-paper-text-light">
						We accept all major credit cards (Visa, Mastercard, American Express) and other payment
						methods through our secure payment processor. All payments are encrypted and secure.
					</p>
				</div>

				<div
					class="animate-fade-in-up rounded-2xl border border-paper-border bg-paper-cream/30 p-6"
					style:animation-delay="0.9s"
				>
					<h3 class="mb-2 text-lg font-semibold text-paper-text">Do you offer refunds?</h3>
					<p class="text-paper-text-light">
						We offer a 30-day money-back guarantee. If you're not satisfied with the AI Tools
						subscription within the first 30 days, contact us for a full refund.
					</p>
				</div>
			</div>
		</div>

		<!-- CTA Section -->
		<div
			class="animate-fade-in-up mx-auto mt-20 max-w-3xl rounded-2xl border border-paper-accent/30 bg-paper-cream/50 p-8 text-center backdrop-blur-sm"
			style:animation-delay="1s"
		>
			<h2 class="mb-4 text-2xl font-bold text-paper-text">Ready to start writing?</h2>
			<p class="mb-6 text-paper-text-light">
				Download Fictioneer for free and experience the joy of distraction-free writing.
			</p>
			<div class="flex flex-wrap justify-center gap-4">
				<a
					href={resolve('/download')}
					class="inline-flex items-center gap-2 rounded-lg bg-paper-accent px-8 py-3 font-medium text-paper-beige transition-all hover:bg-paper-accent-light"
				>
					Download Free
					<svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
						<path
							stroke-linecap="round"
							stroke-linejoin="round"
							stroke-width="2"
							d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"
						></path>
					</svg>
				</a>
				<a
					href="#subscribe"
					class="inline-flex items-center gap-2 rounded-lg border border-paper-border px-8 py-3 font-medium text-paper-text transition-all hover:bg-paper-gray/30"
				>
					Try AI Tools
				</a>
			</div>
		</div>
	</div>
</div>
