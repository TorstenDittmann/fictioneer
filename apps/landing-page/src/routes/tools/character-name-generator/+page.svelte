<script lang="ts">
	import { resolve } from '$app/paths';
	import { client } from '$lib/config';

	const GENRES = [
		{ value: 'fantasy', label: 'Fantasy', icon: '🏰' },
		{ value: 'sci-fi', label: 'Sci-Fi', icon: '🚀' },
		{ value: 'romance', label: 'Romance', icon: '💕' },
		{ value: 'mystery', label: 'Mystery', icon: '🔍' },
		{ value: 'historical', label: 'Historical', icon: '🏛️' }
	] as const;

	const ORIGINS = [
		{ value: 'western', label: 'Western', icon: '🌎' },
		{ value: 'japanese', label: 'Japanese', icon: '🗾' },
		{ value: 'celtic', label: 'Celtic', icon: '☘️' },
		{ value: 'latin', label: 'Latin', icon: '🏛️' },
		{ value: 'arabic', label: 'Arabic', icon: '🌙' },
		{ value: 'custom', label: 'Blend', icon: '✨' }
	] as const;

	const GENDERS = [
		{ value: 'neutral', label: 'Neutral', icon: '⚪' },
		{ value: 'female', label: 'Feminine', icon: '♀️' },
		{ value: 'male', label: 'Masculine', icon: '♂️' }
	] as const;

	const STYLES = [
		{ value: 'regal', label: 'Regal', icon: '👑' },
		{ value: 'mysterious', label: 'Mysterious', icon: '🌙' },
		{ value: 'edgy', label: 'Edgy', icon: '⚡' },
		{ value: 'playful', label: 'Playful', icon: '🎭' },
		{ value: 'classic', label: 'Classic', icon: '📜' }
	] as const;

	type GeneratedName = {
		name: string;
		origin: string;
		meaning: string;
	};

	let selected_genre = $state('fantasy');
	let selected_origin = $state('western');
	let selected_gender = $state('neutral');
	let selected_style = $state('mysterious');
	let include_traits = $state('');
	let results_requested = $state(6);
	let generated_names: GeneratedName[] = $state([]);
	let generating_names = $state(false);
	let error_message = $state('');
	let copied_index = $state<number | null>(null);

	async function generate_names() {
		if (generating_names) return;
		generating_names = true;
		error_message = '';
		generated_names = [];

		try {
			const response = await client.api.marketing['generate-character-names'].$post({
				json: {
					genre: selected_genre,
					origin: selected_origin,
					gender: selected_gender,
					style: selected_style,
					traits: include_traits || undefined,
					count: Number(results_requested)
				}
			});

			if (!response.ok) {
				const error_text = await response.text();
				let error_data;
				try {
					error_data = JSON.parse(error_text);
				} catch {
					error_data = { error: error_text };
				}
				throw new Error(error_data.error || 'Failed to generate names');
			}

			const data = await response.json();
			generated_names = data.names ?? [];
		} catch (error) {
			console.error('Error generating names:', error);
			error_message =
				error instanceof Error ? error.message : 'Failed to generate names. Please try again.';
		} finally {
			generating_names = false;
		}
	}

	function copy_name(name: string, index: number) {
		navigator.clipboard.writeText(name).then(() => {
			copied_index = index;
			setTimeout(() => (copied_index = null), 2000);
		});
	}
</script>

<svelte:head>
	<title>Character Name Generator - Fantasy & Genre Names | Fictioneer</title>
	<meta
		name="description"
		content="Generate memorable character names for any genre. Blend origins, styles, and custom traits to craft unique hero, villain, or side character names instantly."
	/>
	<link rel="canonical" href="https://fictioneer.app/tools/character-name-generator" />
</svelte:head>

<main class="mx-auto max-w-6xl px-4 py-16 sm:px-6 lg:py-24">
	<!-- Hero Section -->
	<div class="animate-fade-in-up relative mb-12 text-center">
		<div
			class="aurora-blob-subtle absolute -top-16 left-1/3 h-48 w-48 rounded-full bg-emerald-500/20"
		></div>
		<div
			class="aurora-blob-subtle absolute -top-8 right-1/3 h-32 w-32 rounded-full bg-teal-500/20"
		></div>

		<div class="relative">
			<a
				href={resolve('/tools')}
				class="mb-6 inline-flex items-center gap-2 text-sm text-paper-text-muted transition-colors hover:text-paper-accent"
			>
				<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
					<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"
					></path>
				</svg>
				All Tools
			</a>

			<h1 class="mb-4 font-serif text-4xl tracking-tight text-paper-text sm:text-5xl lg:text-6xl">
				Character Name <span class="gradient-text">Generator</span>
			</h1>
			<p class="mx-auto max-w-2xl text-lg text-paper-text-light">
				Craft unforgettable character names with genre-aware origins, stylistic flourishes, and
				custom traits.
			</p>
		</div>
	</div>

	<!-- Name Generator Form -->
	<div class="animate-fade-in-up mb-16" style:animation-delay="0.1s">
		<form
			onsubmit={(e) => {
				e.preventDefault();
				generate_names();
			}}
			class="card-elevated overflow-hidden"
		>
			<!-- Genre Selection -->
			<div class="border-b border-paper-border p-6">
				<span class="mb-4 block text-sm font-medium text-paper-text-muted">Genre</span>
				<div class="flex flex-wrap gap-2">
					{#each GENRES as genre (genre.value)}
						<button
							type="button"
							onclick={() => (selected_genre = genre.value)}
							disabled={generating_names}
							class="group relative overflow-hidden rounded-xl px-4 py-2.5 text-sm font-medium transition-all duration-200 {selected_genre ===
							genre.value
								? 'bg-gradient-to-r from-emerald-500 to-teal-500 text-white shadow-md'
								: 'bg-paper-beige text-paper-text-light hover:bg-paper-gray hover:text-paper-text'}"
						>
							<span class="flex items-center gap-2">
								<span class="text-base">{genre.icon}</span>
								{genre.label}
							</span>
						</button>
					{/each}
				</div>
			</div>

			<!-- Origin and Gender -->
			<div class="grid border-b border-paper-border sm:grid-cols-2">
				<div class="border-b border-paper-border p-6 sm:border-r sm:border-b-0">
					<span class="mb-4 block text-sm font-medium text-paper-text-muted">Origin Style</span>
					<div class="flex flex-wrap gap-2">
						{#each ORIGINS as origin (origin.value)}
							<button
								type="button"
								onclick={() => (selected_origin = origin.value)}
								disabled={generating_names}
								class="flex items-center gap-1.5 rounded-lg px-3 py-2 text-sm transition-all duration-200 {selected_origin ===
								origin.value
									? 'bg-paper-accent/10 text-paper-accent ring-1 ring-paper-accent'
									: 'bg-paper-beige text-paper-text-light hover:bg-paper-gray'}"
							>
								<span>{origin.icon}</span>
								{origin.label}
							</button>
						{/each}
					</div>
				</div>

				<div class="p-6">
					<span class="mb-4 block text-sm font-medium text-paper-text-muted">Gender Expression</span
					>
					<div class="flex flex-wrap gap-2">
						{#each GENDERS as gender (gender.value)}
							<button
								type="button"
								onclick={() => (selected_gender = gender.value)}
								disabled={generating_names}
								class="flex items-center gap-1.5 rounded-lg px-3 py-2 text-sm transition-all duration-200 {selected_gender ===
								gender.value
									? 'bg-paper-accent/10 text-paper-accent ring-1 ring-paper-accent'
									: 'bg-paper-beige text-paper-text-light hover:bg-paper-gray'}"
							>
								<span>{gender.icon}</span>
								{gender.label}
							</button>
						{/each}
					</div>
				</div>
			</div>

			<!-- Style Selection -->
			<div class="border-b border-paper-border p-6">
				<span class="mb-4 block text-sm font-medium text-paper-text-muted">Name Style</span>
				<div class="flex flex-wrap gap-2">
					{#each STYLES as style (style.value)}
						<button
							type="button"
							onclick={() => (selected_style = style.value)}
							disabled={generating_names}
							class="rounded-full px-4 py-2 text-sm font-medium transition-all duration-200 {selected_style ===
							style.value
								? 'bg-paper-accent text-white'
								: 'bg-paper-beige text-paper-text-light hover:bg-paper-gray hover:text-paper-text'}"
						>
							<span class="flex items-center gap-1.5">
								<span>{style.icon}</span>
								{style.label}
							</span>
						</button>
					{/each}
				</div>
			</div>

			<!-- Count and Traits -->
			<div class="grid border-b border-paper-border sm:grid-cols-2">
				<div class="border-b border-paper-border p-6 sm:border-r sm:border-b-0">
					<label for="name-count" class="mb-4 block text-sm font-medium text-paper-text-muted">
						Number of Names: <span class="font-semibold text-paper-accent">{results_requested}</span
						>
					</label>
					<input
						id="name-count"
						type="range"
						min="3"
						max="12"
						step="3"
						bind:value={results_requested}
						disabled={generating_names}
						class="h-2 w-full cursor-pointer appearance-none rounded-lg bg-paper-beige accent-paper-accent"
					/>
					<div class="mt-2 flex justify-between text-xs text-paper-text-muted">
						<span>3</span>
						<span>6</span>
						<span>9</span>
						<span>12</span>
					</div>
				</div>

				<div class="p-6">
					<label for="traits" class="mb-4 block text-sm font-medium text-paper-text-muted">
						Character Traits <span class="font-normal text-paper-text-muted">(optional)</span>
					</label>
					<textarea
						id="traits"
						bind:value={include_traits}
						placeholder="brave, clever, mysterious, resilient..."
						disabled={generating_names}
						class="input min-h-20 resize-none text-sm"
					></textarea>
				</div>
			</div>

			<!-- Generate Button -->
			<div class="bg-paper-beige/30 p-6">
				<button
					type="submit"
					disabled={generating_names}
					class="btn-primary w-full py-4 text-base disabled:cursor-not-allowed disabled:opacity-60"
				>
					{#if generating_names}
						<span class="flex items-center justify-center gap-3">
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
							Crafting names...
						</span>
					{:else}
						<span class="flex items-center justify-center gap-2">
							<svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
								<path
									stroke-linecap="round"
									stroke-linejoin="round"
									stroke-width="2"
									d="M13 10V3L4 14h7v7l9-11h-7z"
								></path>
							</svg>
							Generate Names
						</span>
					{/if}
				</button>
			</div>
		</form>
	</div>

	<!-- Generated Names Display -->
	<div class="animate-fade-in-up" style:animation-delay="0.2s">
		{#if error_message}
			<div class="mb-6 rounded-2xl border border-red-200 bg-red-50 p-5 text-sm text-red-600">
				<div class="flex items-start gap-3">
					<svg class="mt-0.5 h-5 w-5 shrink-0" fill="currentColor" viewBox="0 0 20 20">
						<path
							fill-rule="evenodd"
							d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
							clip-rule="evenodd"
						></path>
					</svg>
					{error_message}
				</div>
			</div>
		{/if}

		{#if generated_names.length > 0}
			<div class="mb-6">
				<h2 class="mb-4 text-center font-serif text-xl font-semibold text-paper-text">
					Your Character Names
				</h2>
				<div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
					{#each generated_names as name, index (name.name)}
						<div class="card group relative overflow-hidden p-5 transition-all hover:shadow-lg">
							<!-- Copy button -->
							<button
								onclick={() => copy_name(name.name, index)}
								class="absolute top-3 right-3 rounded-lg p-2 text-paper-text-muted opacity-0 transition-all group-hover:opacity-100 hover:bg-paper-beige hover:text-paper-accent"
							>
								{#if copied_index === index}
									<svg
										class="h-4 w-4 text-paper-lime"
										fill="none"
										stroke="currentColor"
										viewBox="0 0 24 24"
									>
										<path
											stroke-linecap="round"
											stroke-linejoin="round"
											stroke-width="2"
											d="M5 13l4 4L19 7"
										></path>
									</svg>
								{:else}
									<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
										<path
											stroke-linecap="round"
											stroke-linejoin="round"
											stroke-width="2"
											d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z"
										></path>
									</svg>
								{/if}
							</button>

							<p class="mb-1 text-xs text-paper-text-muted">Name {index + 1}</p>
							<p class="mb-3 font-serif text-2xl font-semibold text-paper-text">
								{name.name}
							</p>
							<p class="text-sm leading-relaxed text-paper-text-light">
								{name.meaning}
							</p>
						</div>
					{/each}
				</div>
			</div>
		{:else if !generating_names}
			<!-- Empty State -->
			<div class="card py-20 text-center">
				<div class="mb-6 flex justify-center">
					<div
						class="flex h-20 w-20 items-center justify-center rounded-2xl bg-gradient-to-br from-emerald-100 to-teal-100 text-4xl"
					>
						👤
					</div>
				</div>
				<h3 class="mb-2 font-serif text-xl font-semibold text-paper-text">Your characters await</h3>
				<p class="mx-auto max-w-sm text-paper-text-muted">
					Configure your preferences and click "Generate Names" to create unique character names.
				</p>
			</div>
		{/if}
	</div>

	<!-- Features Section -->
	<div class="animate-fade-in-up mt-20" style:animation-delay="0.3s">
		<h2 class="mb-8 text-center font-serif text-2xl font-semibold text-paper-text">
			Why writers love this tool
		</h2>
		<div class="grid gap-5 sm:grid-cols-3">
			{#each [{ icon: '🌍', title: 'Cultural Depth', desc: 'Names blend curated phonetics with cultural origins for authentic, believable characters.', gradient: 'from-blue-500 to-cyan-500' }, { icon: '✨', title: 'Meaningful Names', desc: 'Each name comes with meaning and origin info to help inform your character development.', gradient: 'from-purple-500 to-pink-500' }, { icon: '🎯', title: 'Genre-Specific', desc: 'Fantasy names feel fantastical, sci-fi names feel futuristic. Perfect fit every time.', gradient: 'from-amber-500 to-orange-500' }] as feature (feature.title)}
				<div class="card group overflow-hidden p-6 transition-all hover:shadow-lg">
					<div
						class="mb-4 flex h-12 w-12 items-center justify-center rounded-xl bg-gradient-to-br text-xl transition-transform duration-300 group-hover:scale-110 {feature.gradient}"
					>
						{feature.icon}
					</div>
					<h3 class="mb-2 font-serif text-lg font-semibold text-paper-text">{feature.title}</h3>
					<p class="text-sm leading-relaxed text-paper-text-light">{feature.desc}</p>
				</div>
			{/each}
		</div>
	</div>

	<!-- CTA Section -->
	<div class="animate-fade-in-up mt-16" style:animation-delay="0.4s">
		<div class="card-elevated glow-accent overflow-hidden p-8 text-center lg:p-12">
			<h2 class="mb-4 font-serif text-2xl font-semibold text-paper-text">
				Ready to bring your characters to life?
			</h2>
			<p class="mx-auto mb-8 max-w-lg text-paper-text-light">
				Use these names in our AI Story Generator or download Fictioneer to start writing your next
				masterpiece.
			</p>
			<div class="flex flex-wrap justify-center gap-4">
				<a href={resolve('/tools/ai-story-generator')} class="btn-primary">
					<span class="flex items-center gap-2">
						<svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
							<path
								stroke-linecap="round"
								stroke-linejoin="round"
								stroke-width="2"
								d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z"
							/>
						</svg>
						Generate a Story
					</span>
				</a>
				<a href={resolve('/tools')} class="btn-ghost">Explore More Tools</a>
			</div>
		</div>
	</div>
</main>
