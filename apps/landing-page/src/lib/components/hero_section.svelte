<script lang="ts">
	import { resolve } from '$app/paths';
	import logo from '$lib/assets/logo.svg';
</script>

<section class="relative overflow-hidden px-4 pb-20 pt-28 sm:pb-32 sm:pt-36 lg:pt-40">
	<div class="absolute inset-0 bg-gradient-to-b from-white via-white/60 to-paper-beige/60"></div>
	<div class="absolute inset-0" style:background="var(--gradient-radial)"></div>
	<div class="aurora-blob -left-12 top-10 h-64 w-64 bg-[rgba(124,140,255,0.28)]"></div>
	<div class="aurora-blob right-0 top-24 h-72 w-72 bg-[rgba(161,241,210,0.25)]"></div>
	<div class="aurora-blob left-1/3 -bottom-24 h-80 w-80 bg-[rgba(245,168,255,0.3)]"></div>
	<div class="pointer-events-none absolute inset-x-0 top-10 mx-auto h-[520px] max-w-5xl rounded-[40px] border border-white/30 bg-white/40 shadow-[0_20px_80px_rgba(15,23,42,0.12)] backdrop-blur-3xl"></div>

	<div class="relative z-10 mx-auto max-w-6xl">
		<div class="mb-10 flex justify-center">
			<div class="pill shadow-lg">
				<span
					class="flex h-9 w-9 items-center justify-center rounded-full bg-white/70 shadow-inner shadow-white/40"
				>
					<svg class="h-4 w-4 text-paper-text" fill="none" stroke="currentColor" viewBox="0 0 24 24">
						<path
							stroke-linecap="round"
							stroke-linejoin="round"
							stroke-width="2"
							d="M12 6l1.76 3.566L18 10.24l-2.8 2.73L15.52 17 12 15.158 8.48 17l.28-4.03L6 10.24l4.24-.674L12 6z"
						></path>
					</svg>
				</span>
				<span>Distraction-free writing software designed for novelists</span>
			</div>
		</div>

		<div class="flex flex-col items-center gap-10 text-center lg:gap-12">
			<div class="space-y-8 lg:max-w-4xl">
				<h1 class="font-serif text-5xl leading-[1.05] tracking-tight text-paper-text sm:text-6xl lg:text-7xl">
					Where Stories <span class="gradient-text">Come to Life</span>
				</h1>
				<p class="mx-auto max-w-2xl text-lg leading-relaxed text-paper-text-light sm:text-xl lg:text-2xl">
					Distraction-free writing software designed for novelists—crafted to keep you in flow.
				</p>
				<div class="flex w-full flex-col items-center gap-4 sm:flex-row sm:justify-center">
					<a href={resolve('/download')} class="btn-primary w-full sm:w-auto">
						<span class="flex items-center justify-center gap-2 text-base sm:text-lg">
							Download Free
							<svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
								<path
									stroke-linecap="round"
									stroke-linejoin="round"
									stroke-width="2"
									d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"
								></path>
							</svg>
						</span>
					</a>
					<a href="#features" class="btn-ghost w-full sm:w-auto">
						<span class="flex items-center justify-center gap-2">
							Explore features
							<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
								<path
									stroke-linecap="round"
									stroke-linejoin="round"
									stroke-width="2"
									d="M9 5l7 7-7 7"
								></path>
							</svg>
						</span>
					</a>
				</div>
			</div>

			<div class="relative w-full max-w-4xl">
				<div class="absolute -left-10 top-6 h-20 w-20 rounded-full bg-white/40 blur-3xl"></div>
				<div class="absolute -right-6 bottom-10 h-24 w-24 rounded-full bg-paper-accent/30 blur-3xl"></div>
				<div class="glass-strong relative overflow-hidden rounded-[28px] border border-white/60 p-6 shadow-2xl sm:p-8">
					<div class="absolute inset-0 bg-gradient-to-br from-white/45 via-paper-beige/60 to-white/30"></div>
					<div class="relative flex flex-col gap-6">
						<div class="flex items-center justify-between rounded-2xl border border-white/60 bg-white/50 px-4 py-3 shadow-inner shadow-white/40">
							<div class="flex items-center gap-3">
								<div class="h-10 w-10 rounded-full bg-gradient-to-br from-paper-accent to-paper-accent-light p-[2px]">
									<div class="flex h-full w-full items-center justify-center rounded-full bg-white/90">
										<img src={logo} alt="Fictioneer" class="h-6 w-6" />
									</div>
								</div>
								<div>
									<p class="text-xs font-semibold uppercase tracking-widest text-paper-text-muted">Preview</p>
									<p class="text-base font-semibold text-paper-text">Product screenshot</p>
								</div>
							</div>
							<div class="flex items-center gap-2 rounded-full bg-white/70 px-3 py-1 text-xs font-semibold text-paper-text">
								<span class="h-2 w-2 rounded-full bg-emerald-400 shadow-[0_0_12px_rgba(16,185,129,0.5)]"></span>
								Placeholder
							</div>
						</div>

						<div class="relative overflow-hidden rounded-2xl border border-white/60 bg-white/65 shadow-inner shadow-white/60">
							<div class="grid-overlay absolute inset-0 opacity-60"></div>
							<div class="relative aspect-[16/10] w-full bg-gradient-to-br from-paper-cream via-white to-paper-gray/60">
								<div class="absolute inset-0 flex items-center justify-center">
									<div class="glass rounded-full px-4 py-2 text-sm font-semibold text-paper-text">Screenshot placeholder</div>
								</div>
							</div>
						</div>
					</div>
					<div class="pointer-events-none absolute -inset-6 -z-10 bg-gradient-to-tr from-paper-accent/15 via-paper-accent-light/10 to-paper-accent-pink/10 blur-3xl"></div>
				</div>
			</div>
		</div>
	</div>
</section>
