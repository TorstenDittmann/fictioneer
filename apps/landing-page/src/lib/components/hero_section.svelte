<script lang="ts">
	import { asset, resolve } from '$app/paths';
</script>

<section class="relative overflow-hidden px-4 pt-32 pb-24 sm:pt-40 sm:pb-32 lg:pt-48 lg:pb-40">
	<div class="relative z-10 mx-auto max-w-6xl">
		<!-- Pill Badge -->
		<div class="animate-fade-in-down mb-8 flex justify-center">
			<div class="pill">
				<span class="flex h-2 w-2 items-center justify-center">
					<span class="absolute h-2 w-2 animate-ping rounded-full bg-paper-accent/60"></span>
					<span class="relative h-2 w-2 rounded-full bg-paper-accent"></span>
				</span>
				<span class="text-paper-text-light">Distraction-free writing for novelists</span>
			</div>
		</div>

		<!-- Main Content -->
		<div class="flex flex-col items-center gap-8 text-center lg:gap-10">
			<!-- Headline -->
			<div class="animate-fade-in-up max-w-4xl" style:animation-delay="0.1s">
				<h1
					class="font-serif text-4xl leading-[1.1] tracking-tight text-paper-text sm:text-5xl md:text-6xl lg:text-7xl"
				>
					Where Stories
					<span class="gradient-text"> Come to Life</span>
				</h1>
			</div>

			<!-- Subheadline -->
			<p
				class="animate-fade-in-up max-w-2xl text-lg leading-relaxed text-paper-text-light sm:text-xl lg:text-2xl"
				style:animation-delay="0.2s"
			>
				A beautiful, distraction-free writing environment with AI-powered tools to help you craft
				your next masterpiece.
			</p>

			<!-- CTA Buttons -->
			<div
				class="animate-fade-in-up flex w-full flex-col items-center gap-3 sm:flex-row sm:justify-center sm:gap-4"
				style:animation-delay="0.3s"
			>
				<a href={resolve('/download')} class="btn-primary w-full sm:w-auto">
					<span class="flex items-center justify-center gap-2">
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
				<a href="#features" class="btn-ghost w-full sm:w-auto">
					<span class="flex items-center justify-center gap-2">
						See Features
						<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
							<path
								stroke-linecap="round"
								stroke-linejoin="round"
								stroke-width="2"
								d="M19 9l-7 7-7-7"
							></path>
						</svg>
					</span>
				</a>
			</div>

			<!-- Product Preview Card -->
			<div
				class="animate-fade-in-up relative mt-8 w-full max-w-4xl lg:mt-12"
				style:animation-delay="0.4s"
			>
				<!-- Glow Effect -->
				<div
					class="absolute -inset-4 rounded-[32px] bg-gradient-to-r from-paper-accent/20 via-paper-iris/10 to-paper-accent-pink/20 opacity-60 blur-3xl"
				></div>

				<!-- Card -->
				<div class="card-elevated relative overflow-hidden p-2">
					<!-- Header Bar -->
					<div class="flex items-center justify-between rounded-t-xl bg-paper-beige/50 px-4 py-3">
						<div class="flex items-center gap-3">
							<!-- Window Controls -->
							<div class="flex gap-1.5">
								<div class="h-3 w-3 rounded-full bg-red-400/80"></div>
								<div class="h-3 w-3 rounded-full bg-yellow-400/80"></div>
								<div class="h-3 w-3 rounded-full bg-green-400/80"></div>
							</div>

							<!-- App Info -->
							<div class="flex items-center gap-2">
								<div
									class="h-6 w-6 rounded-lg bg-gradient-to-br from-paper-accent to-paper-iris p-0.5"
								>
									<div
										class="flex h-full w-full items-center justify-center rounded-md bg-paper-cream"
									>
										<img src={asset('/logo.svg')} alt="Fictioneer" class="h-3.5 w-3.5" />
									</div>
								</div>
								<span class="text-xs font-medium text-paper-text-muted">Fictioneer Preview</span>
							</div>
						</div>

						<div class="flex items-center gap-2">
							<span class="badge">
								<span class="mr-1 h-1.5 w-1.5 rounded-full bg-paper-lime"></span>
								Coming Soon
							</span>
						</div>
					</div>

					<!-- Preview Content -->
					<div class="relative overflow-hidden rounded-b-xl bg-paper-cream/80">
						<div class="grid-overlay absolute inset-0 opacity-40"></div>

						<!-- Simulated Editor Interface -->
						<div class="relative flex min-h-[280px] sm:min-h-[320px] lg:min-h-[380px]">
							<!-- Sidebar -->
							<div
								class="hidden w-48 border-r border-paper-border/50 bg-paper-beige/30 p-4 lg:block"
							>
								<div class="mb-4">
									<div
										class="mb-2 text-[10px] font-semibold tracking-wider text-paper-text-muted uppercase"
									>
										Manuscript
									</div>
									<div class="space-y-1.5">
										<div
											class="flex items-center gap-2 rounded-lg bg-paper-accent/10 px-2.5 py-1.5"
										>
											<div class="h-1.5 w-1.5 rounded-full bg-paper-accent"></div>
											<span class="text-xs font-medium text-paper-text">Chapter 1</span>
										</div>
										<div class="flex items-center gap-2 px-2.5 py-1.5">
											<div class="h-1.5 w-1.5 rounded-full bg-paper-text-muted/30"></div>
											<span class="text-xs text-paper-text-muted">Chapter 2</span>
										</div>
										<div class="flex items-center gap-2 px-2.5 py-1.5">
											<div class="h-1.5 w-1.5 rounded-full bg-paper-text-muted/30"></div>
											<span class="text-xs text-paper-text-muted">Chapter 3</span>
										</div>
									</div>
								</div>

								<div>
									<div
										class="mb-2 text-[10px] font-semibold tracking-wider text-paper-text-muted uppercase"
									>
										Notes
									</div>
									<div class="space-y-1.5">
										<div class="flex items-center gap-2 px-2.5 py-1.5">
											<div class="h-1.5 w-1.5 rounded-full bg-paper-iris/50"></div>
											<span class="text-xs text-paper-text-muted">Characters</span>
										</div>
										<div class="flex items-center gap-2 px-2.5 py-1.5">
											<div class="h-1.5 w-1.5 rounded-full bg-paper-accent-pink/50"></div>
											<span class="text-xs text-paper-text-muted">Plot</span>
										</div>
									</div>
								</div>
							</div>

							<!-- Main Editor Area -->
							<div class="flex flex-1 flex-col p-6 lg:p-8">
								<div class="mx-auto w-full max-w-lg">
									<!-- Fake Text Lines -->
									<div class="space-y-3">
										<div class="h-3 w-3/4 rounded bg-paper-text/8"></div>
										<div class="h-3 w-full rounded bg-paper-text/8"></div>
										<div class="h-3 w-5/6 rounded bg-paper-text/8"></div>
										<div class="h-3 w-full rounded bg-paper-text/8"></div>
										<div class="h-3 w-2/3 rounded bg-paper-text/8"></div>
									</div>

									<div class="mt-6 space-y-3">
										<div class="h-3 w-full rounded bg-paper-text/8"></div>
										<div class="h-3 w-4/5 rounded bg-paper-text/8"></div>
										<div class="h-3 w-full rounded bg-paper-text/8"></div>
										<div class="h-3 w-3/4 rounded bg-paper-text/8"></div>
									</div>

									<!-- AI Suggestion Indicator -->
									<div
										class="mt-8 rounded-xl border border-paper-accent/20 bg-gradient-to-r from-paper-accent/5 to-paper-iris/5 p-4"
									>
										<div class="flex items-start gap-3">
											<div
												class="flex h-8 w-8 items-center justify-center rounded-lg bg-paper-accent/10"
											>
												<svg
													class="h-4 w-4 text-paper-accent"
													fill="none"
													stroke="currentColor"
													viewBox="0 0 24 24"
												>
													<path
														stroke-linecap="round"
														stroke-linejoin="round"
														stroke-width="2"
														d="M13 10V3L4 14h7v7l9-11h-7z"
													></path>
												</svg>
											</div>
											<div class="flex-1">
												<div class="mb-1.5 text-xs font-semibold text-paper-accent">
													AI Suggestion
												</div>
												<div class="space-y-1.5">
													<div class="h-2 w-full rounded bg-paper-accent/15"></div>
													<div class="h-2 w-4/5 rounded bg-paper-accent/10"></div>
												</div>
											</div>
										</div>
									</div>
								</div>
							</div>
						</div>
					</div>
				</div>
			</div>
		</div>
	</div>
</section>
