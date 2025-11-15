<script lang="ts">
	import { resolve } from '$app/paths';
	import { onMount } from 'svelte';

	const badges = [
		{ label: 'Beta invites open', detail: 'Reserve your studio' },
		{ label: 'Craft novels faster', detail: 'Flow-state UX' },
		{ label: 'Lenis smooth scroll', detail: 'Cinematic feel' }
	];

	const hero_stats = [
		{ label: 'Focus Sessions', value: '84 mins', detail: 'avg uninterrupted flow' },
		{ label: 'Scenes Organized', value: '1,200+', detail: 'kept in sync' },
		{ label: 'Writers onboard', value: '32K', detail: 'storytellers waiting' }
	];

	const orbit_highlights = [
		{ title: 'Context aware AI', detail: 'Understands your scenes' },
		{ title: 'Holographic outline', detail: 'Visualize every chapter' },
		{ title: 'Realtime mood board', detail: 'Blend notes + research' }
	];

	let parallax = $state({ stars: 0, nebula: 0, glow: 0 });
	let tilt = $state({ x: 0, y: 0 });

	onMount(() => {
		if (typeof window === 'undefined') {
			return () => {};
		}

		const handleScroll = () => {
			const y = window.scrollY;
			parallax = {
				stars: y * 0.12,
				nebula: y * 0.18,
				glow: y * 0.24
			};
		};

		window.addEventListener('scroll', handleScroll, { passive: true });
		handleScroll();

		return () => window.removeEventListener('scroll', handleScroll);
	});

	function handlePointerMove(event: PointerEvent) {
		const target = event.currentTarget as HTMLElement | null;
		if (!target) return;
		const rect = target.getBoundingClientRect();
		const x = (event.clientX - rect.left) / rect.width - 0.5;
		const y = (event.clientY - rect.top) / rect.height - 0.5;
		tilt = { x, y };
	}

	function resetTilt() {
		tilt = { x: 0, y: 0 };
	}

	function scrollToWaitlist() {
		document.getElementById('newsletter')?.scrollIntoView({ behavior: 'smooth' });
	}
</script>

<section class="immersive-hero">
	<div class="hero-backdrop">
		<div class="hero-layer layer-stars" style:transform={`translateY(${-parallax.stars}px)`}></div>
		<div
			class="hero-layer layer-nebula"
			style:transform={`translateY(${-parallax.nebula}px)`}
		></div>
		<div class="hero-layer layer-glow" style:transform={`translateY(${-parallax.glow}px)`}></div>
	</div>

	<div
		class="hero-grid"
		onpointermove={handlePointerMove}
		onpointerleave={resetTilt}
		aria-label="Fictioneer immersive hero"
	>
		<div class="hero-copy">
			<p class="eyebrow">Story OS · crafted for novelists</p>
			<h1>
				The cinematic studio <span>your characters deserve</span>
			</h1>
			<p class="lede">
				Fictioneer turns your manuscript into a living, breathing world with tactile controls,
				real-time AI collaboration, and spatial organization inspired by film studios.
			</p>

			<div class="cta-row">
				<a href={resolve('/download')} class="btn-primary hover-lift">
					<span>Download for free</span>
				</a>
				<button type="button" onclick={scrollToWaitlist} class="ghost-button">
					Join the waitlist
				</button>
			</div>

			<div class="badge-grid">
				{#each badges as badge (badge.label)}
					<div class="badge-pill">
						<span>{badge.label}</span>
						<p>{badge.detail}</p>
					</div>
				{/each}
			</div>
		</div>

		<div
			class="hero-stage"
			style:transform={`rotateX(${tilt.y * 10}deg) rotateY(${tilt.x * 16}deg)`}
		>
			<div class="book-model">
				<div class="book-cover front">Fictioneer</div>
				<div class="book-cover back"></div>
				<div class="book-spine"></div>
				<div class="book-pages"></div>
				<div class="book-glow"></div>
			</div>
			<div class="page-stack">
				<span class="floating-page one"></span>
				<span class="floating-page two"></span>
				<span class="floating-page three"></span>
			</div>
			<div class="hero-orbits">
				{#each orbit_highlights as highlight, i (highlight.title)}
					<div class="orbit-card" style:animation-delay={`${i * 0.4}s`}>
						<p class="orbit-title">{highlight.title}</p>
						<p class="orbit-detail">{highlight.detail}</p>
					</div>
				{/each}
			</div>
		</div>
	</div>

	<div class="hero-stats">
		{#each hero_stats as stat (stat.label)}
			<article>
				<p class="label">{stat.label}</p>
				<p class="value">{stat.value}</p>
				<p class="detail">{stat.detail}</p>
			</article>
		{/each}
	</div>
</section>

<style>
	.immersive-hero {
		position: relative;
		min-height: 110vh;
		padding: clamp(4rem, 8vw, 8rem) 1.5rem 6rem;
		overflow: hidden;
		background:
			radial-gradient(circle at 30% 20%, rgba(196, 164, 124, 0.2), transparent 55%),
			radial-gradient(circle at 70% 0%, rgba(255, 255, 255, 0.08), transparent 45%),
			linear-gradient(180deg, rgba(23, 20, 16, 0.4), rgba(23, 20, 16, 0.95));
	}

	.hero-backdrop {
		position: absolute;
		inset: 0;
		overflow: hidden;
	}

	.hero-layer {
		position: absolute;
		inset: -20%;
		will-change: transform;
	}

	.layer-stars {
		background: radial-gradient(circle, rgba(255, 255, 255, 0.35) 0, transparent 55%);
		opacity: 0.4;
		filter: blur(150px);
		animation: heroDrift 18s ease-in-out infinite;
	}

	.layer-nebula {
		background: conic-gradient(from 90deg, rgba(196, 164, 124, 0.4), transparent 60%);
		filter: blur(220px);
		opacity: 0.6;
	}

	.layer-glow {
		background: radial-gradient(circle at 50% 20%, rgba(255, 255, 255, 0.08), transparent 50%);
		opacity: 0.9;
	}

	.hero-grid {
		position: relative;
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
		gap: clamp(2rem, 4vw, 4rem);
		align-items: center;
	}

	.hero-copy {
		position: relative;
		z-index: 2;
		padding: clamp(1.5rem, 3vw, 3rem);
		border-radius: 32px;
		background: rgba(23, 20, 16, 0.6);
		border: 1px solid rgba(196, 164, 124, 0.15);
		box-shadow: 0 30px 60px rgba(0, 0, 0, 0.35);
	}

	.hero-copy .eyebrow {
		text-transform: uppercase;
		letter-spacing: 0.4em;
		font-size: 0.75rem;
		color: var(--color-paper-text-muted);
	}

	.hero-copy h1 {
		font-size: clamp(2.5rem, 5vw, 4.75rem);
		margin: 1rem 0;
		line-height: 1;
	}

	.hero-copy h1 span {
		display: block;
		color: var(--color-paper-accent);
	}

	.hero-copy .lede {
		font-size: 1.1rem;
		color: var(--color-paper-text-light);
		margin-bottom: 2rem;
	}

	.cta-row {
		display: flex;
		flex-wrap: wrap;
		gap: 1rem;
		margin-bottom: 1.5rem;
	}

	.ghost-button {
		padding: 0.85rem 2rem;
		border-radius: 999px;
		border: 1px solid rgba(196, 164, 124, 0.4);
		color: var(--color-paper-text);
		background: transparent;
		font-weight: 500;
		transition: all 0.3s ease;
	}

	.ghost-button:hover {
		transform: translateY(-2px);
		border-color: var(--color-paper-accent);
		color: var(--color-paper-accent);
	}

	.badge-grid {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
		gap: 0.75rem;
	}

	.badge-pill {
		padding: 0.85rem 1rem;
		border-radius: 18px;
		background: rgba(196, 164, 124, 0.08);
		border: 1px solid rgba(196, 164, 124, 0.2);
	}

	.badge-pill span {
		font-size: 0.85rem;
		letter-spacing: 0.08em;
		text-transform: uppercase;
		color: var(--color-paper-text-light);
	}

	.badge-pill p {
		margin-top: 0.3rem;
		color: var(--color-paper-text-muted);
		font-size: 0.85rem;
	}

	.hero-stage {
		position: relative;
		min-height: 420px;
		padding: 3rem;
		border-radius: 36px;
		background: radial-gradient(
			circle at 30% 20%,
			rgba(196, 164, 124, 0.15),
			rgba(20, 18, 15, 0.9)
		);
		border: 1px solid rgba(196, 164, 124, 0.2);
		transform-style: preserve-3d;
		transition: transform 0.3s ease;
	}

	.book-model {
		position: relative;
		width: clamp(220px, 40vw, 320px);
		aspect-ratio: 3 / 4;
		margin: 0 auto;
		transform-style: preserve-3d;
		transform: rotateY(-12deg) rotateX(8deg);
		animation: heroFloat 8s ease-in-out infinite;
	}

	.book-cover {
		position: absolute;
		inset: 0;
		border-radius: 18px;
		background: linear-gradient(135deg, rgba(255, 255, 255, 0.08), rgba(196, 164, 124, 0.4));
		border: 1px solid rgba(255, 255, 255, 0.2);
		backdrop-filter: blur(6px);
		transform-style: preserve-3d;
		display: flex;
		align-items: center;
		justify-content: center;
		font-size: 1.2rem;
		letter-spacing: 0.3em;
		text-transform: uppercase;
	}

	.book-cover.back {
		background: rgba(0, 0, 0, 0.6);
		transform: translateZ(-30px);
	}

	.book-spine {
		position: absolute;
		width: 30px;
		inset: 0;
		background: rgba(196, 164, 124, 0.3);
		transform: rotateY(90deg) translateZ(15px);
	}

	.book-pages {
		position: absolute;
		inset: 12px;
		border-radius: 12px;
		background: repeating-linear-gradient(
			90deg,
			rgba(255, 255, 255, 0.4) 0,
			rgba(255, 255, 255, 0.05) 3px
		);
		transform: translateZ(-8px);
	}

	.book-glow {
		position: absolute;
		inset: -20%;
		background: radial-gradient(circle, rgba(196, 164, 124, 0.45), transparent 60%);
		filter: blur(30px);
		transform: translateZ(-40px);
	}

	.page-stack {
		position: absolute;
		inset: 0;
		pointer-events: none;
	}

	.floating-page {
		position: absolute;
		width: 120px;
		height: 160px;
		border-radius: 12px;
		background: rgba(255, 255, 255, 0.08);
		border: 1px solid rgba(255, 255, 255, 0.2);
		animation: heroFloat 10s ease-in-out infinite;
	}

	.floating-page.one {
		top: -30px;
		right: 10%;
	}

	.floating-page.two {
		bottom: -20px;
		left: 0;
		animation-delay: 1.4s;
	}

	.floating-page.three {
		top: 40%;
		left: 70%;
		animation-delay: 2.4s;
	}

	.hero-orbits {
		position: absolute;
		inset: 1rem;
		display: grid;
		grid-template-columns: repeat(2, minmax(120px, 1fr));
		gap: 1rem;
		pointer-events: none;
	}

	.orbit-card {
		padding: 0.85rem;
		border-radius: 16px;
		background: rgba(23, 20, 16, 0.8);
		border: 1px solid rgba(196, 164, 124, 0.25);
		box-shadow: 0 10px 40px rgba(0, 0, 0, 0.35);
		animation: orbitPulse 6s ease-in-out infinite;
	}

	.orbit-title {
		font-size: 0.8rem;
		text-transform: uppercase;
		letter-spacing: 0.1em;
		color: var(--color-paper-text-muted);
	}

	.orbit-detail {
		margin-top: 0.25rem;
		color: var(--color-paper-text);
	}

	.hero-stats {
		margin-top: clamp(2rem, 4vw, 4rem);
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
		gap: 1rem;
	}

	.hero-stats article {
		padding: 1.5rem;
		border-radius: 20px;
		background: rgba(23, 20, 16, 0.6);
		border: 1px solid rgba(196, 164, 124, 0.15);
	}

	.hero-stats .label {
		text-transform: uppercase;
		letter-spacing: 0.1em;
		font-size: 0.75rem;
		color: var(--color-paper-text-muted);
	}

	.hero-stats .value {
		font-size: 1.9rem;
		margin: 0.4rem 0;
		color: var(--color-paper-accent);
	}

	.hero-stats .detail {
		color: var(--color-paper-text-light);
		font-size: 0.95rem;
	}

	@keyframes heroFloat {
		0%,
		100% {
			transform: translateY(0) rotateY(-12deg) rotateX(8deg);
		}
		50% {
			transform: translateY(-20px) rotateY(-14deg) rotateX(10deg);
		}
	}

	@keyframes heroDrift {
		0%,
		100% {
			transform: translate3d(0, 0, 0);
		}
		50% {
			transform: translate3d(15px, -15px, 0);
		}
	}

	@keyframes orbitPulse {
		0%,
		100% {
			opacity: 0.9;
			transform: translateY(0);
		}
		50% {
			opacity: 1;
			transform: translateY(-6px);
		}
	}

	@media (max-width: 768px) {
		.hero-stage {
			padding: 2rem;
		}

		.book-model {
			width: 220px;
		}
	}
</style>
