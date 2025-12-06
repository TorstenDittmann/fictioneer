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
			if (!email.includes('@') || !email.includes('.')) {
				throw new Error('Please enter a valid email address');
			}

			const formData = new FormData();
			formData.append('seller_id', '1628431409926');
			formData.append('email', email);

			await fetch('https://gumroad.com/follow_from_embed_form', {
				method: 'POST',
				body: formData,
				mode: 'no-cors'
			});

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

	const benefits = [
		{
			iconType: 'clock' as const,
			title: 'Writing Tips',
			description: 'Expert advice for novelists'
		},
		{
			iconType: 'puzzle' as const,
			title: 'Feature Updates',
			description: 'Stay informed on releases'
		},
		{
			iconType: 'users' as const,
			title: 'Community Insights',
			description: 'Stories from writers'
		}
	];
</script>

<section id="newsletter" class="relative overflow-hidden px-4 py-24 sm:py-32">
	<!-- Background -->
	<div class="absolute inset-0" style:background="var(--gradient-mesh)"></div>
	<div
		class="aurora-blob-subtle top-[15%] left-[5%] h-[350px] w-[350px] rounded-full bg-paper-accent/12"
	></div>
	<div
		class="aurora-blob-subtle right-[10%] bottom-[10%] h-[400px] w-[400px] rounded-full bg-paper-iris/10"
	></div>

	<div class="relative z-10 mx-auto max-w-3xl">
		{#if is_success}
			<!-- Success State -->
			<div
				class="card-elevated overflow-hidden p-8 text-center sm:p-12 {mounted
					? 'animate-scale-in'
					: 'opacity-0'}"
			>
				<div class="relative">
					<!-- Success Icon -->
					<div
						class="mx-auto mb-6 flex h-16 w-16 items-center justify-center rounded-2xl bg-gradient-to-br from-paper-accent to-paper-iris shadow-lg"
					>
						<svg class="h-8 w-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
							<path
								stroke-linecap="round"
								stroke-linejoin="round"
								stroke-width="2.5"
								d="M5 13l4 4L19 7"
							></path>
						</svg>
					</div>

					<h2 class="mb-3 font-serif text-2xl font-semibold text-paper-text sm:text-3xl">
						Check Your Email!
					</h2>

					<p class="mb-6 text-paper-text-light">
						We've sent a confirmation to <span class="font-medium text-paper-accent"
							>{submitted_email}</span
						>
					</p>

					<!-- Steps -->
					<div
						class="mx-auto mb-8 max-w-sm rounded-xl border border-paper-border bg-paper-beige/30 p-5"
					>
						<div class="space-y-4 text-left">
							{#each [{ step: '1', text: 'Check your inbox' }, { step: '2', text: 'Click the verification link' }, { step: '3', text: "You're all set!" }] as item (item.step)}
								<div class="flex items-center gap-3">
									<div
										class="flex h-7 w-7 items-center justify-center rounded-full bg-paper-accent/15 text-xs font-bold text-paper-accent"
									>
										{item.step}
									</div>
									<span class="text-sm text-paper-text-light">{item.text}</span>
								</div>
							{/each}
						</div>
					</div>

					<button
						onclick={() => {
							is_success = false;
							submitted_email = '';
						}}
						class="text-sm font-medium text-paper-accent hover:text-paper-iris"
					>
						Use a different email
					</button>
				</div>
			</div>
		{:else}
			<!-- Form State -->
			<div class="card-elevated overflow-hidden p-8 sm:p-12">
				<div class="relative">
					<!-- Header -->
					<div class="mb-8 text-center">
						<p
							class="mb-4 text-sm text-paper-text-muted {mounted
								? 'animate-fade-in-down'
								: 'opacity-0'}"
						>
							By the creator of <span class="font-medium text-paper-accent">OmniaWrite</span>
						</p>

						<h2
							class="mb-3 font-serif text-2xl font-semibold text-paper-text sm:text-3xl lg:text-4xl {mounted
								? 'animate-fade-in-up'
								: 'opacity-0'}"
							style:animation-delay="0.1s"
						>
							Stay <span class="gradient-text">Updated</span>
						</h2>

						<p
							class="text-paper-text-light {mounted ? 'animate-fade-in-up' : 'opacity-0'}"
							style:animation-delay="0.15s"
						>
							Subscribe for writing tips, feature updates, and insights from the Fictioneer team.
						</p>
					</div>

					<!-- Form -->
					<form
						onsubmit={handleSubmit}
						class="mx-auto max-w-md {mounted ? 'animate-fade-in-up' : 'opacity-0'}"
						style:animation-delay="0.2s"
					>
						<div class="flex flex-col gap-3 sm:flex-row">
							<input
								type="email"
								bind:value={email}
								placeholder="Enter your email"
								required
								disabled={is_submitting}
								class="input flex-1"
							/>

							<button
								type="submit"
								disabled={is_submitting || !email}
								class="btn-primary whitespace-nowrap disabled:cursor-not-allowed disabled:opacity-50"
							>
								{#if is_submitting}
									<span class="flex items-center gap-2">
										<svg class="h-4 w-4 animate-spin" fill="none" viewBox="0 0 24 24">
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
										Joining...
									</span>
								{:else}
									Subscribe
								{/if}
							</button>
						</div>

						{#if error_message}
							<div class="mt-3 rounded-lg border border-red-200 bg-red-50 p-3">
								<p class="text-sm text-red-600">{error_message}</p>
							</div>
						{/if}

						<p class="mt-4 text-center text-xs text-paper-text-muted">
							No spam, unsubscribe anytime.
						</p>
					</form>

					<!-- Benefits -->
					<div
						class="mx-auto mt-10 grid max-w-lg gap-3 sm:grid-cols-3 {mounted
							? 'animate-fade-in-up'
							: 'opacity-0'}"
						style:animation-delay="0.25s"
					>
						{#each benefits as benefit (benefit.title)}
							<div
								class="rounded-xl border border-paper-border bg-paper-beige/30 p-4 text-center transition-all duration-200 hover:bg-paper-beige/50"
							>
								<div
									class="mx-auto mb-2 flex h-10 w-10 items-center justify-center rounded-xl bg-paper-accent/10 text-paper-accent"
								>
									{#if benefit.iconType === 'clock'}
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
												d="M12 6v6h4.5m4.5 0a9 9 0 11-18 0 9 9 0 0118 0z"
											></path>
										</svg>
									{:else if benefit.iconType === 'puzzle'}
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
												d="M14.25 6.087c0-.355.186-.676.401-.959.221-.29.349-.634.349-1.003 0-1.036-1.007-1.875-2.25-1.875s-2.25.84-2.25 1.875c0 .369.128.713.349 1.003.215.283.401.604.401.959v0a.64.64 0 01-.657.643 48.39 48.39 0 01-4.163-.3c.186 1.613.293 3.25.315 4.907a.656.656 0 01-.658.663v0c-.355 0-.676-.186-.959-.401a1.647 1.647 0 00-1.003-.349c-1.036 0-1.875 1.007-1.875 2.25s.84 2.25 1.875 2.25c.369 0 .713-.128 1.003-.349.283-.215.604-.401.959-.401v0c.31 0 .555.26.532.57a48.039 48.039 0 01-.642 5.056c1.518.19 3.058.309 4.616.354a.64.64 0 00.657-.643v0c0-.355-.186-.676-.401-.959a1.647 1.647 0 01-.349-1.003c0-1.035 1.008-1.875 2.25-1.875 1.243 0 2.25.84 2.25 1.875 0 .369-.128.713-.349 1.003-.215.283-.4.604-.4.959v0c0 .333.277.599.61.58a48.1 48.1 0 005.427-.63 48.05 48.05 0 00.582-4.717.532.532 0 00-.533-.57v0c-.355 0-.676.186-.959.401-.29.221-.634.349-1.003.349-1.035 0-1.875-1.007-1.875-2.25s.84-2.25 1.875-2.25c.37 0 .713.128 1.003.349.283.215.604.401.96.401v0a.656.656 0 00.658-.663 48.422 48.422 0 00-.37-5.36c-1.886.342-3.81.574-5.766.689a.578.578 0 01-.61-.58v0z"
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
												d="M18 18.72a9.094 9.094 0 003.741-.479 3 3 0 00-4.682-2.72m.94 3.198l.001.031c0 .225-.012.447-.037.666A11.944 11.944 0 0112 21c-2.17 0-4.207-.576-5.963-1.584A6.062 6.062 0 016 18.719m12 0a5.971 5.971 0 00-.941-3.197m0 0A5.995 5.995 0 0012 12.75a5.995 5.995 0 00-5.058 2.772m0 0a3 3 0 00-4.681 2.72 8.986 8.986 0 003.74.477m.94-3.197a5.971 5.971 0 00-.94 3.197M15 6.75a3 3 0 11-6 0 3 3 0 016 0zm6 3a2.25 2.25 0 11-4.5 0 2.25 2.25 0 014.5 0zm-13.5 0a2.25 2.25 0 11-4.5 0 2.25 2.25 0 014.5 0z"
											></path>
										</svg>
									{/if}
								</div>
								<div class="mb-1 text-sm font-semibold text-paper-text">{benefit.title}</div>
								<div class="text-xs text-paper-text-muted">{benefit.description}</div>
							</div>
						{/each}
					</div>
				</div>
			</div>
		{/if}
	</div>
</section>
