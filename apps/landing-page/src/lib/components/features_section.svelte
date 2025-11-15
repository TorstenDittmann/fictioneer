<script lang="ts">
	import { onMount } from 'svelte';

	const feature_clusters = [
		{
			title: 'Distraction-free studio',
			description:
				'A tactile, cinematic canvas where scenes float in 3D space, letting you stitch chapters without modal clutter.',
			badge: 'Focus Stack',
			metric: 'Zero distractions'
		},
		{
			title: 'AI writing companion',
			description:
				'Context aware completions that preserve your tone, surface character notes, and keep lore synced as you draft.',
			badge: 'Resonant AI',
			metric: 'Voice-safe'
		},
		{
			title: 'Progress intelligence',
			description:
				'Beautiful streaks, milestone pulses, and pacing charts that react live as you type. Motivation without guilt.',
			badge: 'Story Pulse',
			metric: '+37% flow time'
		},
		{
			title: 'Pro-ready exports',
			description:
				'One tap EPUB, PDF, and DOCX pipelines with polished typography, margin control, and cover-ready templates.',
			badge: 'Delivery Lab',
			metric: 'EPUB · PDF · DOCX'
		}
	];

	const motion_highlights = [
		{ title: 'Scene bubbles', detail: 'Drag-and-drop arcs across depth' },
		{ title: 'Mood gradients', detail: 'Color-code emotion beats' },
		{ title: 'Audio focus', detail: 'Ambient scoring for sessions' }
	];

	const timeline_moments = [
		{
			title: 'Blueprint',
			description:
				'Sketch acts, characters, and beats with layered cards that orbit your manuscript.'
		},
		{
			title: 'Write in flow',
			description:
				'Lenis-powered smooth scrolling keeps your POV anchored so scenes feel cinematic.'
		},
		{
			title: 'Collaborate with AI',
			description:
				'Tap contextual suggestions, alternate takes, and tone coaching without leaving focus.'
		},
		{
			title: 'Ship everywhere',
			description:
				'Export to every major format with one click and keep brand-ready templates on standby.'
		}
	];

	const scene_cards = [
		{ title: 'Outline arcs', detail: 'Timeline + cards blended into space' },
		{ title: 'Dialogue polish', detail: 'AI tone shifts and cadence hints' },
		{ title: 'World bible', detail: 'Link characters, items, and lore nodes' }
	];

	const ai_base_text = 'She opened the door and';
	const ai_completions = [
		' gasped at the sight before her.',
		' found nothing but darkness.',
		' smiled at the familiar face.',
		' heard footsteps approaching quickly.',
		' felt a cold breeze rush past.',
		' saw her childhood home again.',
		' discovered a hidden garden blooming.',
		' stepped into another world entirely.',
		' realized she was too late.',
		' knew everything had changed forever.'
	];

	let ai_current_text = $state('');
	let ai_completion_index = $state(0);
	let ai_typing = $state(false);
	let pointer = $state({ x: 0, y: 0 });
	let parallax_ratio = $state(0);
	let section_ref: HTMLElement | null = null;

	onMount(() => {
		ai_typing = true;
		typewriterLoop();

		const handleScroll = () => {
			if (!section_ref) return;
			const rect = section_ref.getBoundingClientRect();
			const viewport = window.innerHeight || 1;
			const progress = 1 - Math.min(Math.max(rect.top / viewport, 0), 1);
			parallax_ratio = progress;
		};

		window.addEventListener('scroll', handleScroll, { passive: true });
		handleScroll();

		return () => {
			ai_typing = false;
			window.removeEventListener('scroll', handleScroll);
		};
	});

	async function typewriterLoop() {
		while (ai_typing) {
			ai_current_text = '';
			const completion = ai_completions[ai_completion_index];
			for (let i = 0; i <= completion.length; i++) {
				ai_current_text = completion.substring(0, i);
				await sleep(22);
			}
			await sleep(1200);
			for (let i = completion.length; i >= 0; i--) {
				ai_current_text = completion.substring(0, i);
				await sleep(14);
			}
			ai_completion_index = (ai_completion_index + 1) % ai_completions.length;
			await sleep(200);
		}
	}

	function sleep(ms: number) {
		return new Promise((resolve) => setTimeout(resolve, ms));
	}

	function handlePointerMove(event: PointerEvent) {
		const target = event.currentTarget as HTMLElement | null;
		if (!target) return;
		const rect = target.getBoundingClientRect();
		const x = (event.clientX - rect.left) / rect.width - 0.5;
		const y = (event.clientY - rect.top) / rect.height - 0.5;
		pointer = { x, y };
	}

	function resetPointer() {
		pointer = { x: 0, y: 0 };
	}
</script>

<section id="features" class="cosmic-lab" bind:this={section_ref}>
	<div class="lab-backdrop">
		<span class="halo halo-one" style:transform={`translateY(${-parallax_ratio * 40}px)`}></span>
		<span class="halo halo-two" style:transform={`translateY(${-parallax_ratio * 80}px)`}></span>
	</div>

	<div class="lab-header">
		<p class="eyebrow">Immersive workspace</p>
		<h2>
			Built to feel like <span>a creative playground</span>
		</h2>
		<p>
			Parallax scenes, floating notes, and tactile controls make the landing page feel like a
			cinematic control room while highlighting everything Fictioneer can do.
		</p>
	</div>

	<div class="lab-grid" onpointermove={handlePointerMove} onpointerleave={resetPointer}>
		<div
			class="lab-stage"
			style:transform={`rotateX(${pointer.y * 10}deg) rotateY(${pointer.x * 16}deg)`}
		>
			<div class="lab-hologram">
				<p class="prompt">{ai_base_text}</p>
				<p class="completion">
					{ai_current_text}
					<span class="cursor"></span>
				</p>
			</div>
			<div class="scene-stack">
				{#each scene_cards as card, i (card.title)}
					<div class="scene-card" style={`--depth: ${i}`}>
						<p class="scene-title">{card.title}</p>
						<p class="scene-detail">{card.detail}</p>
					</div>
				{/each}
			</div>
			<div class="lab-rings">
				{#each motion_highlights as highlight, i (highlight.title)}
					<div class="ring-card" style:animation-delay={`${i * 0.3}s`}>
						<p class="ring-title">{highlight.title}</p>
						<p class="ring-detail">{highlight.detail}</p>
					</div>
				{/each}
			</div>
		</div>

		<div class="lab-details">
			{#each feature_clusters as feature (feature.title)}
				<article class="detail-card">
					<div class="detail-head">
						<span class="badge">{feature.badge}</span>
						<span class="metric">{feature.metric}</span>
					</div>
					<h3>{feature.title}</h3>
					<p>{feature.description}</p>
				</article>
			{/each}
		</div>
	</div>

	<div class="timeline-shell">
		{#each timeline_moments as moment, i (moment.title)}
			<div class="timeline-card" style:animation-delay={`${i * 0.1}s`}>
				<div class="timeline-index">{String(i + 1).padStart(2, '0')}</div>
				<h4>{moment.title}</h4>
				<p>{moment.description}</p>
			</div>
		{/each}
	</div>
</section>

<style>
	.cosmic-lab {
		position: relative;
		padding: clamp(4rem, 8vw, 8rem) 1.5rem clamp(4rem, 8vw, 9rem);
		overflow: hidden;
	}

	.lab-backdrop {
		position: absolute;
		inset: 0;
		overflow: hidden;
	}

	.halo {
		position: absolute;
		width: 120%;
		height: 120%;
		top: -10%;
		left: -10%;
		border-radius: 50%;
		background: radial-gradient(circle, rgba(196, 164, 124, 0.15), transparent 65%);
		filter: blur(80px);
	}

	.halo-two {
		background: radial-gradient(circle, rgba(255, 255, 255, 0.08), transparent 60%);
	}

	.lab-header {
		position: relative;
		text-align: center;
		max-width: 720px;
		margin: 0 auto 3rem;
	}

	.lab-header .eyebrow {
		text-transform: uppercase;
		letter-spacing: 0.4em;
		font-size: 0.75rem;
		color: var(--color-paper-text-muted);
	}

	.lab-header h2 {
		font-size: clamp(2.2rem, 5vw, 3.8rem);
		margin: 1rem 0;
	}

	.lab-header h2 span {
		color: var(--color-paper-accent);
	}

	.lab-header p {
		color: var(--color-paper-text-light);
	}

	.lab-grid {
		position: relative;
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
		gap: clamp(2rem, 4vw, 4rem);
		align-items: stretch;
	}

	.lab-stage {
		position: relative;
		min-height: 460px;
		border-radius: 36px;
		padding: 2.5rem;
		background: linear-gradient(135deg, rgba(196, 164, 124, 0.2), rgba(23, 20, 16, 0.9));
		border: 1px solid rgba(196, 164, 124, 0.2);
		box-shadow: 0 40px 80px rgba(0, 0, 0, 0.45);
		transform-style: preserve-3d;
		transition: transform 0.3s ease;
		overflow: hidden;
	}

	.lab-hologram {
		position: relative;
		padding: 1.5rem;
		border-radius: 24px;
		background: rgba(10, 8, 6, 0.7);
		border: 1px solid rgba(255, 255, 255, 0.1);
		box-shadow: inset 0 0 30px rgba(196, 164, 124, 0.1);
		margin-bottom: 1.5rem;
	}

	.lab-hologram .prompt {
		font-size: 0.9rem;
		color: var(--color-paper-text-muted);
	}

	.lab-hologram .completion {
		font-family: 'Libre Baskerville', serif;
		font-size: 1.2rem;
		color: var(--color-paper-accent);
		min-height: 2.6rem;
	}

	.cursor {
		display: inline-block;
		width: 0.45rem;
		height: 1.4rem;
		margin-left: 0.35rem;
		background: var(--color-paper-accent);
		animation: cursorBlink 1.2s steps(2) infinite;
	}

	.scene-stack {
		position: relative;
		display: grid;
		gap: 1rem;
	}

	.scene-card {
		position: relative;
		padding: 1.2rem;
		border-radius: 20px;
		background: rgba(23, 20, 16, 0.8);
		border: 1px solid rgba(196, 164, 124, 0.2);
		box-shadow: 0 calc(var(--depth) * 10px) calc(var(--depth) * 20px) rgba(0, 0, 0, 0.3);
		transform: translateZ(calc(var(--depth) * 24px)) translateY(calc(var(--depth) * -6px));
	}

	.scene-title {
		text-transform: uppercase;
		letter-spacing: 0.2em;
		font-size: 0.7rem;
		color: var(--color-paper-text-muted);
	}

	.scene-detail {
		margin-top: 0.45rem;
		color: var(--color-paper-text);
	}

	.lab-rings {
		position: absolute;
		inset: 1.5rem;
		display: grid;
		grid-template-columns: repeat(2, minmax(120px, 1fr));
		gap: 0.75rem;
		pointer-events: none;
	}

	.ring-card {
		padding: 0.85rem;
		border-radius: 16px;
		background: rgba(10, 8, 6, 0.8);
		border: 1px solid rgba(196, 164, 124, 0.25);
		animation: ringFloat 5s ease-in-out infinite;
	}

	.ring-title {
		font-size: 0.75rem;
		letter-spacing: 0.08em;
		text-transform: uppercase;
		color: var(--color-paper-text-muted);
	}

	.ring-detail {
		margin-top: 0.35rem;
		color: var(--color-paper-text);
	}

	.lab-details {
		display: grid;
		gap: 1.25rem;
	}

	.detail-card {
		padding: 1.5rem;
		border-radius: 24px;
		background: rgba(10, 8, 6, 0.7);
		border: 1px solid rgba(196, 164, 124, 0.15);
		box-shadow: 0 20px 40px rgba(0, 0, 0, 0.35);
	}

	.detail-head {
		display: flex;
		align-items: center;
		justify-content: space-between;
		margin-bottom: 0.75rem;
	}

	.badge {
		padding: 0.35rem 0.8rem;
		border-radius: 999px;
		border: 1px solid rgba(196, 164, 124, 0.4);
		font-size: 0.75rem;
		letter-spacing: 0.08em;
		text-transform: uppercase;
	}

	.metric {
		font-size: 0.9rem;
		color: var(--color-paper-text-muted);
	}

	.detail-card h3 {
		font-size: 1.5rem;
		margin-bottom: 0.4rem;
	}

	.detail-card p {
		color: var(--color-paper-text-light);
	}

	.timeline-shell {
		position: relative;
		margin-top: clamp(3rem, 6vw, 5rem);
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
		gap: 1rem;
	}

	.timeline-card {
		padding: 1.4rem;
		border-radius: 20px;
		background: rgba(10, 8, 6, 0.7);
		border: 1px solid rgba(196, 164, 124, 0.15);
		animation: timelineRise 0.8s ease forwards;
		opacity: 0;
		transform: translateY(20px);
	}

	.timeline-index {
		font-size: 0.85rem;
		letter-spacing: 0.3em;
		text-transform: uppercase;
		color: var(--color-paper-text-muted);
		margin-bottom: 0.5rem;
	}

	.timeline-card h4 {
		font-size: 1.3rem;
		margin-bottom: 0.35rem;
	}

	.timeline-card p {
		color: var(--color-paper-text-light);
	}

	@keyframes cursorBlink {
		0%,
		100% {
			opacity: 1;
		}
		50% {
			opacity: 0;
		}
	}

	@keyframes ringFloat {
		0%,
		100% {
			transform: translateY(0);
		}
		50% {
			transform: translateY(-8px);
		}
	}

	@keyframes timelineRise {
		to {
			opacity: 1;
			transform: translateY(0);
		}
	}

	@media (max-width: 768px) {
		.lab-stage {
			padding: 2rem;
		}

		.lab-rings {
			grid-template-columns: repeat(1, 1fr);
		}
	}
</style>
