<script lang="ts">
	import { resolve } from '$app/paths';
	import type { RouteId } from '$app/types';
	import FaqSection from '$lib/components/faq_section.svelte';

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
			cta_href: '/checkout',
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

<div class="relative min-h-screen overflow-hidden">
	<!-- Background -->
	<div class="absolute inset-0" style:background="var(--gradient-mesh)"></div>
	<div
		class="aurora-blob-subtle top-[10%] left-[10%] h-[400px] w-[400px] rounded-full bg-paper-accent/15"
	></div>
	<div
		class="aurora-blob-subtle right-[5%] bottom-[20%] h-[500px] w-[500px] rounded-full bg-paper-iris/10"
	></div>

	<div class="relative z-10 mx-auto max-w-6xl px-4 py-16 sm:px-6 lg:py-24">
		<!-- Hero Section -->
		<div class="mb-16 text-center">
			<div class="pill animate-fade-in mx-auto mb-6 w-max">
				<span class="h-1.5 w-1.5 rounded-full bg-paper-accent"></span>
				Simple pricing
			</div>

			<h1
				class="animate-fade-in-up mb-4 font-serif text-3xl tracking-tight text-paper-text sm:text-4xl lg:text-5xl"
			>
				Simple, <span class="gradient-text">Transparent</span> Pricing
			</h1>
			<p
				class="animate-fade-in-up mx-auto max-w-2xl text-lg text-paper-text-light"
				style:animation-delay="0.1s"
			>
				Write your novel for free. Unlock advanced AI tools when you're ready to level up.
			</p>
		</div>

		<!-- Pricing Cards -->
		<div class="mx-auto mb-20 grid max-w-4xl gap-6 lg:grid-cols-2">
			{#each plans as plan, idx (plan.name)}
				<div
					class="animate-fade-in-up card-elevated relative overflow-hidden p-8 {plan.highlighted
						? 'ring-2 ring-paper-accent'
						: ''}"
					style:animation-delay="{0.15 + idx * 0.08}s"
				>
					<!-- Highlighted Badge -->
					{#if plan.highlighted}
						<div class="absolute -top-px left-1/2 -translate-x-1/2">
							<div
								class="rounded-b-lg bg-gradient-to-r from-paper-accent to-paper-iris px-4 py-1.5 text-xs font-semibold text-white"
							>
								Most Popular
							</div>
						</div>
					{/if}

					<!-- Plan Header -->
					<div class="mb-6 text-center {plan.highlighted ? 'pt-4' : ''}">
						{#if plan.description}
							<p class="mb-3 text-sm text-paper-text-muted">{plan.description}</p>
						{/if}
						<div class="flex items-baseline justify-center gap-1">
							<span class="font-serif text-4xl font-bold text-paper-text lg:text-5xl"
								>{plan.price}</span
							>
							<span class="text-paper-text-muted">/ {plan.period}</span>
						</div>
					</div>

					<!-- Features List -->
					<ul class="mb-8 space-y-3">
						{#each plan.features as feature (feature.text)}
							<li class="flex items-start gap-3">
								{#if feature.included}
									<div
										class="mt-0.5 flex h-5 w-5 items-center justify-center rounded-full bg-paper-accent/15 text-paper-accent"
									>
										<svg
											class="h-3 w-3"
											fill="none"
											stroke="currentColor"
											stroke-width="3"
											viewBox="0 0 24 24"
										>
											<path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7"
											></path>
										</svg>
									</div>
								{:else}
									<div
										class="mt-0.5 flex h-5 w-5 items-center justify-center rounded-full bg-paper-text-muted/10 text-paper-text-muted/40"
									>
										<svg
											class="h-3 w-3"
											fill="none"
											stroke="currentColor"
											stroke-width="2"
											viewBox="0 0 24 24"
										>
											<path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"
											></path>
										</svg>
									</div>
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
						class="block w-full text-center {plan.highlighted ? 'btn-primary' : 'btn-secondary'}"
					>
						{plan.cta_text}
					</a>
				</div>
			{/each}
		</div>

		<!-- FAQ Section -->
		<div class="mx-auto max-w-3xl">
			<FaqSection intro="Everything about pricing, billing, and the AI Tools subscription." />
		</div>

		<!-- Bottom CTA -->
		<div
			class="animate-fade-in-up mx-auto mt-20 max-w-2xl text-center"
			style:animation-delay="0.6s"
		>
			<div class="card-elevated overflow-hidden p-8">
				<div
					class="absolute inset-0 bg-gradient-to-br from-paper-accent/5 via-transparent to-paper-iris/5"
				></div>
				<div class="relative">
					<h2 class="mb-3 font-serif text-xl font-semibold text-paper-text sm:text-2xl">
						Ready to start writing?
					</h2>
					<p class="mb-6 text-paper-text-light">
						Download Fictioneer for free and experience distraction-free writing.
					</p>
					<div class="flex flex-wrap justify-center gap-3">
						<a href={resolve('/download')} class="btn-primary">
							<span class="flex items-center gap-2">
								Download Free
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
				</div>
			</div>
		</div>
	</div>
</div>
