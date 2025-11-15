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
			description: 'Your stories stay on your device'
		},
		{
			value: 'Free',
			label: 'Forever',
			description: 'No hidden costs or subscriptions'
		},
		{
			value: '0',
			label: 'Distractions',
			description: 'Focus on what matters: writing'
		}
	];
</script>

<section class="relative overflow-hidden px-4 py-16 sm:py-24">
	<div class="absolute inset-0 bg-linear-to-b from-white via-paper-gray/30 to-white"></div>

	<div class="relative z-10 mx-auto max-w-7xl">
		<div class="text-center">
			<h2
				class="mb-4 font-serif text-3xl text-paper-text sm:text-4xl lg:text-5xl {mounted
					? 'animate-fade-in-up'
					: 'opacity-0'}"
			>
				Built for <span class="gradient-text">writers</span>, by writers
			</h2>
			<p
				class="mx-auto mb-12 max-w-2xl text-lg text-paper-text-light sm:mb-16 sm:text-xl {mounted
					? 'animate-fade-in-up'
					: 'opacity-0'}"
				style:animation-delay="0.1s"
			>
				Join thousands of authors who have found their perfect writing companion
			</p>
		</div>

		<!-- Stats grid -->
		<div class="grid gap-6 sm:grid-cols-3 sm:gap-8">
			{#each stats as stat, i (stat.label)}
				<div
					class="glass rounded-2xl p-8 text-center shadow-sm sm:rounded-3xl {mounted
						? 'animate-scale-in'
						: 'opacity-0'}"
					style:animation-delay="{0.2 + i * 0.1}s"
				>
					<div class="gradient-text mb-2 font-serif text-4xl font-bold sm:text-5xl lg:text-6xl">
						{stat.value}
					</div>
					<div class="mb-2 text-lg font-medium text-paper-text sm:text-xl">
						{stat.label}
					</div>
					<div class="text-sm text-paper-text-muted sm:text-base">
						{stat.description}
					</div>
				</div>
			{/each}
		</div>
	</div>
</section>
