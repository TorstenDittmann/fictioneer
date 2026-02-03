<script lang="ts">
	import { onMount } from 'svelte';

	let mounted = $state(false);

	onMount(() => {
		mounted = true;
	});

	const stats = [
		{
			value: '100%',
			label: 'Privacy First',
			description: 'Your stories stay on your device',
			iconType: 'lock'
		},
		{
			value: 'Free',
			label: 'Forever',
			description: 'Core app with optional AI upgrades',
			iconType: 'gift'
		},
		{
			value: 'Zero',
			label: 'Distractions',
			description: 'Focus on what matters: writing',
			iconType: 'eye'
		}
	];
</script>

<section class="relative overflow-hidden px-4 py-24 sm:py-32">
	<div class="relative z-10 mx-auto max-w-5xl">
		<!-- Section Header -->
		<div class="mb-12 text-center lg:mb-16">
			<div class="pill mx-auto mb-6 w-max">
				<span class="h-1.5 w-1.5 rounded-full bg-paper-accent"></span>
				Trusted by writers
			</div>

			<h2
				class="font-serif text-3xl tracking-tight text-paper-text sm:text-4xl lg:text-5xl {mounted
					? 'animate-fade-in-up'
					: 'opacity-0'}"
			>
				Built for <span class="gradient-text">writers</span>, by writers
			</h2>

			<p
				class="mx-auto mt-4 max-w-2xl text-lg text-paper-text-light {mounted
					? 'animate-fade-in-up'
					: 'opacity-0'}"
				style:animation-delay="0.1s"
			>
				Join thousands of authors who have found their perfect writing companion
			</p>
		</div>

		<!-- Stats Grid -->
		<div class="grid gap-4 sm:grid-cols-3 sm:gap-5">
			{#each stats as stat, i (stat.label)}
				<div
					class="card-elevated overflow-hidden p-6 text-center transition-all duration-300 hover:scale-[1.02] sm:p-8 {mounted
						? 'animate-scale-in'
						: 'opacity-0'}"
					style:animation-delay="{0.15 + i * 0.08}s"
				>
					<!-- Icon -->
					<div
						class="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-2xl bg-linear-to-br from-paper-accent/10 to-paper-iris/10 text-paper-accent"
					>
						{#if stat.iconType === 'lock'}
							<svg
								class="h-5 w-5"
								fill="none"
								stroke="currentColor"
								stroke-width="1.5"
								viewBox="0 0 24 24"
							>
								<path
									stroke-linecap="round"
									stroke-linejoin="round"
									d="M16.5 10.5V6.75a4.5 4.5 0 10-9 0v3.75m-.75 11.25h10.5a2.25 2.25 0 002.25-2.25v-6.75a2.25 2.25 0 00-2.25-2.25H6.75a2.25 2.25 0 00-2.25 2.25v6.75a2.25 2.25 0 002.25 2.25z"
								></path>
							</svg>
						{:else if stat.iconType === 'gift'}
							<svg
								class="h-5 w-5"
								fill="none"
								stroke="currentColor"
								stroke-width="1.5"
								viewBox="0 0 24 24"
							>
								<path
									stroke-linecap="round"
									stroke-linejoin="round"
									d="M21 11.25v8.25a1.5 1.5 0 01-1.5 1.5H5.25a1.5 1.5 0 01-1.5-1.5v-8.25M12 4.875A2.625 2.625 0 109.375 7.5H12m0-2.625V7.5m0-2.625A2.625 2.625 0 1114.625 7.5H12m0 0V21m-8.625-9.75h18c.621 0 1.125-.504 1.125-1.125v-1.5c0-.621-.504-1.125-1.125-1.125h-18c-.621 0-1.125.504-1.125 1.125v1.5c0 .621.504 1.125 1.125 1.125z"
								></path>
							</svg>
						{:else}
							<svg
								class="h-5 w-5"
								fill="none"
								stroke="currentColor"
								stroke-width="1.5"
								viewBox="0 0 24 24"
							>
								<path
									stroke-linecap="round"
									stroke-linejoin="round"
									d="M3.98 8.223A10.477 10.477 0 001.934 12C3.226 16.338 7.244 19.5 12 19.5c.993 0 1.953-.138 2.863-.395M6.228 6.228A10.45 10.45 0 0112 4.5c4.756 0 8.773 3.162 10.065 7.498a10.523 10.523 0 01-4.293 5.774M6.228 6.228L3 3m3.228 3.228l3.65 3.65m7.894 7.894L21 21m-3.228-3.228l-3.65-3.65m0 0a3 3 0 10-4.243-4.243m4.242 4.242L9.88 9.88"
								></path>
							</svg>
						{/if}
					</div>

					<!-- Value -->
					<div class="mb-2 font-serif text-4xl font-bold tracking-tight lg:text-5xl">
						<span class="gradient-text">{stat.value}</span>
					</div>

					<!-- Label -->
					<div class="mb-2 text-base font-semibold text-paper-text lg:text-lg">
						{stat.label}
					</div>

					<!-- Description -->
					<div class="text-sm text-paper-text-muted">
						{stat.description}
					</div>
				</div>
			{/each}
		</div>
	</div>
</section>
