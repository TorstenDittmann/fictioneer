<script lang="ts">
	import { onMount } from 'svelte';

	let email = $state('');
	let is_submitting = $state(false);
	let is_success = $state(false);
	let mounted = $state(false);
	let submitted_email = $state('');
	let error_message = $state('');

	onMount(() => {
		mounted = true;
	});

	async function handleSubmit(e: Event) {
		e.preventDefault();
		is_submitting = true;
		error_message = '';

		try {
			// Basic validation
			if (!email.includes('@') || !email.includes('.')) {
				throw new Error('Please enter a valid email address');
			}

			// Submit to Gumroad
			const formData = new FormData();
			formData.append('seller_id', '1628431409926');
			formData.append('email', email);

			await fetch('https://gumroad.com/follow_from_embed_form', {
				method: 'POST',
				body: formData,
				mode: 'no-cors' // This bypasses CORS but we can't read the response
			});

			// With no-cors, we can't read the response, but if no error was thrown, assume success
			// Gumroad will send the verification email
			submitted_email = email;
			is_success = true;
			email = '';
		} catch (err) {
			error_message =
				err instanceof Error ? err.message : 'Something went wrong. Please try again.';
		} finally {
			is_submitting = false;
		}
	}
</script>

<section id="waitlist" class="relative overflow-hidden px-4 py-32">
	<!-- Background gradient -->
	<div
		class="absolute inset-0 bg-gradient-to-b from-paper-white/20 via-paper-beige to-paper-cream/30"
	></div>

	<div class="relative mx-auto max-w-4xl">
		{#if is_success}
			<!-- Success state -->
			<div class="text-center {mounted ? 'animate-scale-in' : 'opacity-0'}">
				<!-- Success icon -->
				<div class="mb-8 flex justify-center">
					<div class="relative">
						<div
							class="relative flex h-24 w-24 items-center justify-center rounded-full bg-gradient-to-br from-paper-accent to-paper-accent-light"
						>
							<svg
								class="h-12 w-12 text-paper-beige"
								fill="none"
								stroke="currentColor"
								viewBox="0 0 24 24"
							>
								<path
									stroke-linecap="round"
									stroke-linejoin="round"
									stroke-width="3"
									d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"
								></path>
							</svg>
						</div>
					</div>
				</div>

				<h2 class="mb-4 font-serif text-4xl text-paper-text md:text-5xl">Check Your Email!</h2>

				<p class="mx-auto mb-8 max-w-2xl text-xl text-paper-text-light">
					We've sent a confirmation email to <span class="font-medium text-paper-accent"
						>{submitted_email}</span
					>
				</p>

				<div class="space-y-3">
					<p class="text-sm text-paper-text-muted">
						Can't find the email? Check your spam folder or
					</p>
					<button
						onclick={() => {
							is_success = false;
							submitted_email = '';
						}}
						class="font-medium text-paper-accent transition-colors hover:text-paper-accent-light"
					>
						Try a different email address
					</button>
				</div>
			</div>
		{:else}
			<!-- Form state -->
			<div class="text-center">
				<!-- Creator credit -->
				<div class="mb-8 {mounted ? 'animate-fade-in-down' : 'opacity-0'}">
					<p class="text-sm text-paper-text-muted">
						By the creator of <span class="font-medium text-paper-accent">OmniaWrite</span>
					</p>
				</div>

				<h2
					class="mb-6 font-serif text-4xl text-paper-text md:text-6xl {mounted
						? 'animate-fade-in-up'
						: 'opacity-0'}"
					style="animation-delay: 0.1s"
				>
					Reserve Your <span class="gradient-text">Spot</span>
				</h2>

				<p
					class="mx-auto mb-12 max-w-3xl text-xl text-paper-text-light md:text-2xl {mounted
						? 'animate-fade-in-up'
						: 'opacity-0'}"
					style="animation-delay: 0.2s"
				>
					Join writers waiting for the future of fiction writing. Get exclusive early access and
					shape the features that matter to you.
				</p>

				<form
					onsubmit={handleSubmit}
					class="mx-auto max-w-xl {mounted ? 'animate-fade-in-up' : 'opacity-0'}"
					style="animation-delay: 0.3s"
				>
					<div class="group relative">
						<!-- Input group -->
						<div class="glass relative flex flex-col gap-3 rounded-2xl p-2 sm:flex-row">
							<input
								type="email"
								bind:value={email}
								placeholder="Enter your email address"
								required
								disabled={is_submitting}
								class="flex-1 rounded-xl border border-paper-border/20 bg-paper-white/10 px-6 py-4 text-paper-text placeholder-paper-text-muted transition-all outline-none focus:border-paper-accent/50 focus:bg-paper-white/20 disabled:opacity-50"
							/>

							<button
								type="submit"
								disabled={is_submitting || !email}
								class="group transform rounded-xl bg-gradient-to-r from-paper-accent to-paper-accent-light px-8 py-4 font-medium whitespace-nowrap text-paper-beige transition-all hover:scale-[1.02] hover:shadow-xl disabled:cursor-not-allowed disabled:opacity-50"
							>
								{#if is_submitting}
									<span class="inline-flex items-center gap-2">
										<svg class="h-5 w-5 animate-spin" fill="none" viewBox="0 0 24 24">
											<circle
												class="opacity-25"
												cx="12"
												cy="12"
												r="10"
												stroke="currentColor"
												stroke-width="4"
											></circle>
											<path
												class="opacity-75"
												fill="currentColor"
												d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
											></path>
										</svg>
										Reserving...
									</span>
								{:else}
									<span class="inline-flex items-center gap-2">
										Get Early Access
										<svg
											class="h-5 w-5 transition-transform group-hover:translate-x-1"
											fill="none"
											stroke="currentColor"
											viewBox="0 0 24 24"
										>
											<path
												stroke-linecap="round"
												stroke-linejoin="round"
												stroke-width="2"
												d="M13 7l5 5m0 0l-5 5m5-5H6"
											></path>
										</svg>
									</span>
								{/if}
							</button>
						</div>
					</div>

					{#if error_message}
						<div class="animate-fade-in mt-4 rounded-xl border border-red-500/20 bg-red-500/10 p-4">
							<p class="text-sm text-red-400">{error_message}</p>
						</div>
					{/if}

					<p class="mt-6 text-sm text-paper-text-muted">
						We'll send you a verification email. No spam, unsubscribe anytime.
					</p>
				</form>

				<!-- Benefits -->
				<div
					class="mx-auto mt-16 grid max-w-3xl grid-cols-1 gap-6 sm:grid-cols-3 {mounted
						? 'animate-fade-in-up'
						: 'opacity-0'}"
					style="animation-delay: 0.4s"
				>
					<div class="glass hover-lift rounded-xl p-6 text-center">
						<svg
							class="mx-auto mb-3 h-8 w-8 text-paper-accent"
							fill="none"
							stroke="currentColor"
							viewBox="0 0 24 24"
						>
							<path
								stroke-linecap="round"
								stroke-linejoin="round"
								stroke-width="2"
								d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
							></path>
						</svg>
						<h4 class="mb-1 font-semibold text-paper-text">Early Access</h4>
						<p class="text-sm text-paper-text-muted">Be first to experience Fictioneer</p>
					</div>

					<div class="glass hover-lift rounded-xl p-6 text-center">
						<svg
							class="mx-auto mb-3 h-8 w-8 text-paper-accent"
							fill="none"
							stroke="currentColor"
							viewBox="0 0 24 24"
						>
							<path
								stroke-linecap="round"
								stroke-linejoin="round"
								stroke-width="2"
								d="M11 4a2 2 0 114 0v1a1 1 0 001 1h3a1 1 0 011 1v3a1 1 0 01-1 1h-1a2 2 0 100 4h1a1 1 0 011 1v3a1 1 0 01-1 1h-3a1 1 0 01-1-1v-1a2 2 0 10-4 0v1a1 1 0 01-1 1H7a1 1 0 01-1-1v-3a1 1 0 00-1-1H4a2 2 0 110-4h1a1 1 0 001-1V7a1 1 0 011-1h3a1 1 0 001-1V4z"
							></path>
						</svg>
						<h4 class="mb-1 font-semibold text-paper-text">Founding Member</h4>
						<p class="text-sm text-paper-text-muted">Special status and benefits</p>
					</div>

					<div class="glass hover-lift rounded-xl p-6 text-center">
						<svg
							class="mx-auto mb-3 h-8 w-8 text-paper-accent"
							fill="none"
							stroke="currentColor"
							viewBox="0 0 24 24"
						>
							<path
								stroke-linecap="round"
								stroke-linejoin="round"
								stroke-width="2"
								d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"
							></path>
						</svg>
						<h4 class="mb-1 font-semibold text-paper-text">Shape the Future</h4>
						<p class="text-sm text-paper-text-muted">Your feedback drives our features</p>
					</div>
				</div>
			</div>
		{/if}
	</div>
</section>
