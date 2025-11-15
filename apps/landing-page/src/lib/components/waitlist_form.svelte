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

<section id="newsletter" class="relative overflow-hidden px-4 py-20 sm:py-32">
	<!-- Background gradient -->
	<div class="absolute inset-0 bg-linear-to-b from-white via-paper-gray/20 to-white"></div>

	<div class="relative mx-auto max-w-4xl">
		{#if is_success}
			<!-- Success state -->
			<div class="text-center {mounted ? 'animate-scale-in' : 'opacity-0'}">
				<!-- Success icon -->
				<div class="mb-6 flex justify-center sm:mb-8">
					<div class="relative">
						<div
							class="relative flex h-20 w-20 items-center justify-center rounded-full bg-linear-to-br from-paper-accent via-paper-accent-light to-paper-accent-pink sm:h-24 sm:w-24"
						>
							<svg
								class="h-10 w-10 text-white sm:h-12 sm:w-12"
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

				<h2 class="mb-4 font-serif text-3xl text-paper-text sm:text-4xl md:text-5xl">
					Check Your Email!
				</h2>

				<p class="mx-auto mb-6 max-w-2xl text-lg text-paper-text-light sm:mb-8 sm:text-xl">
					We've sent a confirmation email to <span class="font-medium text-paper-accent"
						>{submitted_email}</span
					>. You're now subscribed to our newsletter!
				</p>

				<div class="glass mx-auto mb-6 max-w-lg rounded-xl p-4 sm:mb-8 sm:rounded-2xl sm:p-6">
					<div class="space-y-3 sm:space-y-4">
						<div class="flex items-start gap-3 text-left">
							<div
								class="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-paper-accent/20 text-sm font-bold text-paper-accent sm:h-8 sm:w-8"
							>
								1
							</div>
							<div>
								<p class="mb-1 text-sm font-medium text-paper-text sm:text-base">Open your email</p>
								<p class="text-xs text-paper-text-muted sm:text-sm">
									Look for an email from Gumroad
								</p>
							</div>
						</div>
						<div class="flex items-start gap-3 text-left">
							<div
								class="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-paper-accent/20 text-sm font-bold text-paper-accent sm:h-8 sm:w-8"
							>
								2
							</div>
							<div>
								<p class="mb-1 text-sm font-medium text-paper-text sm:text-base">
									Click the verification link
								</p>
								<p class="text-xs text-paper-text-muted sm:text-sm">
									Confirm your newsletter subscription
								</p>
							</div>
						</div>
						<div class="flex items-start gap-3 text-left">
							<div
								class="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-paper-accent/20 text-sm font-bold text-paper-accent sm:h-8 sm:w-8"
							>
								3
							</div>
							<div>
								<p class="mb-1 text-sm font-medium text-paper-text sm:text-base">You're all set!</p>
								<p class="text-xs text-paper-text-muted sm:text-sm">
									You'll receive updates, tips, and news about Fictioneer
								</p>
							</div>
						</div>
					</div>
				</div>

				<div class="space-y-2 sm:space-y-3">
					<p class="text-xs text-paper-text-muted sm:text-sm">
						Can't find the email? Check your spam folder or
					</p>
					<button
						onclick={() => {
							is_success = false;
							submitted_email = '';
						}}
						class="text-sm font-medium text-paper-accent transition-colors hover:text-paper-accent-light sm:text-base"
					>
						Try a different email address
					</button>
				</div>
			</div>
		{:else}
			<!-- Form state -->
			<div class="text-center">
				<!-- Creator credit -->
				<div class="mb-6 {mounted ? 'animate-fade-in-down' : 'opacity-0'} sm:mb-8">
					<p class="text-xs text-paper-text-muted sm:text-sm">
						By the creator of <span class="font-medium text-paper-accent">OmniaWrite</span>
					</p>
				</div>

				<h2
					class="mb-4 font-serif text-3xl text-paper-text sm:mb-6 sm:text-4xl md:text-6xl {mounted
						? 'animate-fade-in-up'
						: 'opacity-0'}"
					style:animation-delay="0.1s"
				>
					Stay <span class="gradient-text">Updated</span>
				</h2>

				<p
					class="mx-auto mb-10 max-w-3xl text-lg text-paper-text-light sm:mb-12 sm:text-xl md:text-2xl {mounted
						? 'animate-fade-in-up'
						: 'opacity-0'}"
					style:animation-delay="0.2s"
				>
					Subscribe to our newsletter for writing tips, feature updates, and insights from the
					Fictioneer team.
				</p>

				<form
					onsubmit={handleSubmit}
					class="mx-auto max-w-xl {mounted ? 'animate-fade-in-up' : 'opacity-0'}"
					style:animation-delay="0.3s"
				>
					<div class="group relative">
						<!-- Input group -->
						<div
							class="glass relative flex flex-col gap-3 rounded-xl p-2 shadow-sm sm:flex-row sm:rounded-2xl"
						>
							<input
								type="email"
								bind:value={email}
								placeholder="Enter your email address"
								required
								disabled={is_submitting}
								class="flex-1 rounded-lg border border-paper-border bg-white px-4 py-3 text-paper-text placeholder-paper-text-muted transition-all outline-none focus:border-paper-accent focus:ring-2 focus:ring-paper-accent/20 disabled:opacity-50 sm:rounded-xl sm:px-6 sm:py-4"
							/>

							<button
								type="submit"
								disabled={is_submitting || !email}
								class="group transform rounded-lg bg-linear-to-r from-paper-accent via-paper-accent-light to-paper-accent-pink px-6 py-3 font-medium whitespace-nowrap text-white transition-all hover:scale-[1.02] hover:shadow-xl disabled:cursor-not-allowed disabled:opacity-50 sm:rounded-xl sm:px-8 sm:py-4"
							>
								{#if is_submitting}
									<span class="inline-flex items-center gap-2">
										<svg class="h-4 w-4 animate-spin sm:h-5 sm:w-5" fill="none" viewBox="0 0 24 24">
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
										<span class="text-sm sm:text-base">Reserving...</span>
									</span>
								{:else}
									<span class="inline-flex items-center gap-2">
										<span class="text-sm sm:text-base">Subscribe</span>
										<svg
											class="h-4 w-4 transition-transform group-hover:translate-x-1 sm:h-5 sm:w-5"
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
						<div
							class="animate-fade-in mt-3 rounded-lg border border-red-500/20 bg-red-500/10 p-3 sm:mt-4 sm:rounded-xl sm:p-4"
						>
							<p class="text-xs text-red-400 sm:text-sm">{error_message}</p>
						</div>
					{/if}

					<p class="mt-4 text-xs text-paper-text-muted sm:mt-6 sm:text-sm">
						Get writing tips, updates, and news. No spam, unsubscribe anytime.
					</p>
				</form>

				<!-- Benefits -->
				<div
					class="mx-auto mt-12 grid max-w-3xl grid-cols-1 gap-4 sm:mt-16 sm:grid-cols-3 sm:gap-6 {mounted
						? 'animate-fade-in-up'
						: 'opacity-0'}"
					style:animation-delay="0.4s"
				>
					<div class="glass hover-lift rounded-lg p-4 text-center shadow-sm sm:rounded-xl sm:p-6">
						<svg
							class="mx-auto mb-2 h-6 w-6 text-paper-accent sm:mb-3 sm:h-8 sm:w-8"
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
						<h4 class="mb-1 text-sm font-semibold text-paper-text sm:text-base">Writing Tips</h4>
						<p class="text-xs text-paper-text-muted sm:text-sm">Expert advice for novelists</p>
					</div>

					<div class="glass hover-lift rounded-lg p-4 text-center shadow-sm sm:rounded-xl sm:p-6">
						<svg
							class="mx-auto mb-2 h-6 w-6 text-paper-accent sm:mb-3 sm:h-8 sm:w-8"
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
						<h4 class="mb-1 text-sm font-semibold text-paper-text sm:text-base">Feature Updates</h4>
						<p class="text-xs text-paper-text-muted sm:text-sm">Stay informed on new releases</p>
					</div>

					<div class="glass hover-lift rounded-lg p-4 text-center shadow-sm sm:rounded-xl sm:p-6">
						<svg
							class="mx-auto mb-2 h-6 w-6 text-paper-accent sm:mb-3 sm:h-8 sm:w-8"
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
						<h4 class="mb-1 text-sm font-semibold text-paper-text sm:text-base">
							Community Insights
						</h4>
						<p class="text-xs text-paper-text-muted sm:text-sm">Stories from fellow writers</p>
					</div>
				</div>
			</div>
		{/if}
	</div>
</section>
