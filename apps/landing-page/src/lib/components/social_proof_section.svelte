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

<section class="relative overflow-hidden px-4 py-20 sm:py-28">
	<div class="absolute inset-0 bg-gradient-to-b from-white via-paper-gray/30 to-white"></div>
	<div class="absolute inset-0" style:background="var(--gradient-radial)"></div>
	<div class="aurora-blob left-4 top-6 h-52 w-52 bg-[rgba(124,140,255,0.2)]"></div>
	<div class="aurora-blob right-4 bottom-0 h-64 w-64 bg-[rgba(245,168,255,0.2)]"></div>
	<div class="pointer-events-none absolute inset-x-8 top-10 mx-auto h-64 max-w-5xl rounded-[30px] border border-white/50 bg-white/40 shadow-[0_20px_60px_rgba(15,23,42,0.08)] backdrop-blur-3xl"></div>

	<div class="relative z-10 mx-auto max-w-6xl">
		<div class="text-center">
			<div class="pill mx-auto w-max shadow-md">
				<span class="h-2 w-2 rounded-full bg-paper-accent"></span>
				Trusted by the writing community
			</div>
			<h2
				class="mt-6 mb-3 font-serif text-3xl text-paper-text sm:text-4xl lg:text-5xl {mounted
					? 'animate-fade-in-up'
					: 'opacity-0'}"
			>
				Built for <span class="gradient-text">writers</span>, by writers
			</h2>
			<p
				class="mx-auto mb-12 max-w-3xl text-lg text-paper-text-light sm:mb-16 sm:text-xl {mounted
					? 'animate-fade-in-up'
					: 'opacity-0'}"
				style:animation-delay="0.1s"
			>
				Join thousands of authors who have found their perfect writing companion
			</p>
		</div>

		<div class="grid gap-5 sm:grid-cols-3 sm:gap-6">
			{#each stats as stat, i (stat.label)}
				<div
					class="glass rounded-3xl p-8 text-center shadow-xl transition-smooth hover:-translate-y-1 hover:shadow-2xl sm:p-10 {mounted
						? 'animate-scale-in'
						: 'opacity-0'}"
					style:animation-delay="{0.2 + i * 0.1}s"
				>
					<div class="gradient-text mb-3 font-serif text-4xl font-bold sm:text-5xl lg:text-6xl">
						{stat.value}
					</div>
					<div class="mb-2 text-lg font-semibold text-paper-text sm:text-xl">
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
