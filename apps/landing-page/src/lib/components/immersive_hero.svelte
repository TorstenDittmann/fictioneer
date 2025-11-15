<script lang="ts">
	import { resolve } from '$app/paths';
	import { onMount, onDestroy } from 'svelte';
	import { browser } from '$app/environment';

	type HeroProps = {
		scroll_position?: number;
	};

	let { scroll_position = 0 }: HeroProps = $props();

	type Artifact = {
		title: string;
		body: string;
		accent: string;
		depth: number;
	};

	const artifacts: Artifact[] = [
		{
			title: '3D Manuscript Core',
			body: 'Layered, living chapters rendered as luminous pages so you can sense pacing at a glance.',
			accent: 'Structure',
			depth: 12
		},
		{
			title: 'Adaptive Story Graph',
			body: 'Timeline nodes float in space and respond to your scroll, revealing character arcs.',
			accent: 'Flow',
			depth: 18
		},
		{
			title: 'Atmospheric Room Tone',
			body: 'Parallax fog + light gradients calm the canvas and keep you in the zone.',
			accent: 'Focus',
			depth: 24
		}
	];

	const stats = [
		{ label: 'Realtime Co-Author', value: 'AI scenes', depth: 8 },
		{ label: 'Parallax Chapters', value: '12 layers', depth: 10 },
		{ label: 'Writers onboard', value: '38k+', depth: 14 }
	];

	const markers = [
		'Plot beats rendered in 3D',
		'Lenis-smoothed navigation',
		'Glowing focus timer',
		'Chapter energy heatmap'
	];

	const orbit_nodes = [0, 1, 2];

	let pointer = $state({ x: 0, y: 0 });
	let glow_rotation = $state(0);
	let raf_id = 0;

	const scroll_factor = $derived(scroll_position * 0.0025);

	function layerTransform(depth: number) {
		const baseY = scroll_factor * depth * 50;
		const pointerX = pointer.x * depth * 20;
		const pointerY = pointer.y * depth * 20;
		return `translate3d(${pointerX}px, calc(${baseY}px + ${pointerY}px), 0)`;
	}

	function handlePointer(event: PointerEvent) {
		const x = event.clientX / window.innerWidth - 0.5;
		const y = event.clientY / window.innerHeight - 0.5;
		pointer = { x, y };
	}

	function resetPointer() {
		pointer = { x: 0, y: 0 };
	}

	onMount(() => {
		if (!browser) return;
		const animateGlow = () => {
			glow_rotation += 0.005;
			raf_id = requestAnimationFrame(animateGlow);
		};
		raf_id = requestAnimationFrame(animateGlow);

		return () => {
			cancelAnimationFrame(raf_id);
		};
	});

	onDestroy(() => {
		cancelAnimationFrame(raf_id);
	});
</script>

<section
	class="immersive-hero"
	onpointermove={handlePointer}
	onpointerleave={resetPointer}
	style={`--glow-rotation: ${glow_rotation}rad;`}
>
	<div class="hero-background" aria-hidden="true">
		<div class="hero-gradient"></div>
		<div class="hero-gridlines"></div>
		<div class="hero-noise"></div>
		<div class="hero-aurora" style={`transform: ${layerTransform(20)}`}></div>
	</div>

	<div class="hero-content">
		<div class="hero-grid">
			<div class="hero-copy">
				<p class="hero-eyebrow">immersive lenis scroll • cinematic parallax • creative 3d models</p>
				<h1>
					Storycraft inside a
					<span>living studio</span>
				</h1>
				<p class="hero-subtitle">
					Fictioneer now ships with a volumetric writing room, spatialized chapters, and
					Lenis-smooth navigation so every scroll feels like gliding through your manuscript.
				</p>
				<div class="hero-cta">
					<a href={resolve('/download')} class="btn-primary">Download the app</a>
					<a href={resolve('/tools')} class="btn-secondary">Explore creative tools</a>
				</div>

				<div class="hero-stats">
					{#each stats as stat (stat.label)}
						<div class="stat-card" style={`transform: ${layerTransform(stat.depth)};`}>
							<span class="stat-label">{stat.label}</span>
							<span class="stat-value">{stat.value}</span>
						</div>
					{/each}
				</div>
			</div>

			<div class="hero-visual" aria-hidden="true">
				<div
					class="hologram"
					style={`transform: rotateX(${pointer.y * 10}deg) rotateY(${pointer.x * -10}deg);`}
				>
					<div class="hologram-core"></div>
					<div class="hologram-page page-one"></div>
					<div class="hologram-page page-two"></div>
					<div class="hologram-page page-three"></div>
					<div class="hologram-light"></div>
				</div>
				<div class="orbital" style={`transform: ${layerTransform(16)};`}>
					{#each orbit_nodes as node (node)}
						<span class={`orbital-node node-${node + 1}`}></span>
					{/each}
				</div>
			</div>
		</div>

		<div class="hero-marker-track" aria-hidden="true">
			{#each markers as marker, idx (marker + idx)}
				<div class="marker" style={`transform: ${layerTransform(10 + idx * 2)};`}>
					<span>{marker}</span>
				</div>
			{/each}
		</div>

		<div class="parallax-grid">
			{#each artifacts as artifact (artifact.title)}
				<article class="parallax-card" style={`transform: ${layerTransform(artifact.depth)};`}>
					<span class="badge">{artifact.accent}</span>
					<h3>{artifact.title}</h3>
					<p>{artifact.body}</p>
				</article>
			{/each}
		</div>

		<div class="hero-scroll-hint">
			<div class="scroll-indicator"></div>
			<p>Glide down for the full experience</p>
		</div>
	</div>
</section>
