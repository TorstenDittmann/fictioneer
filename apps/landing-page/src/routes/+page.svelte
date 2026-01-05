<script lang="ts">
	import HeroSection from '$lib/components/hero_section.svelte';
	import FeaturesSection from '$lib/components/features_section.svelte';
	import SocialProofSection from '$lib/components/social_proof_section.svelte';
	import FinalCtaSection from '$lib/components/final_cta_section.svelte';
</script>

<svelte:head>
	<!-- Primary Meta Tags -->
	<title>Fictioneer - next generation writing software</title>
	<meta name="title" content="Fictioneer - next generation writing software" />
	<meta
		name="description"
		content="Download Fictioneer for free. Distraction-free writing software for novelists with AI-powered assistance, progress tracking, and a beautiful minimalist interface. Available for Windows, Mac, and Linux."
	/>
	<meta
		name="keywords"
		content="writing app, novel writing software, distraction free writing, fiction writing tool, author software, manuscript editor, creative writing app, AI writing assistant, book writing software, novelist tools"
	/>
	<meta name="author" content="Creator of OmniaWrite" />
	<meta name="robots" content="index, follow" />
	<meta name="language" content="English" />
	<link rel="canonical" href="https://fictioneer.app" />

	<!-- PWA Manifest -->
	<link rel="manifest" href="/manifest.json" />

	<!-- Open Graph / Facebook -->
	<meta property="og:type" content="website" />
	<meta property="og:url" content="https://fictioneer.app" />
	<meta property="og:title" content="Fictioneer - Where Stories Come to Life" />
	<meta
		property="og:description"
		content="Download Fictioneer for free. Distraction-free writing software designed for novelists. Available for Windows, Mac, and Linux."
	/>
	<meta property="og:image" content="https://fictioneer.app/og.png" />
	<meta property="og:image:width" content="1200" />
	<meta property="og:image:height" content="630" />
	<meta property="og:image:alt" content="Fictioneer - Distraction-Free Writing Software" />
	<meta property="og:site_name" content="Fictioneer" />
	<meta property="og:locale" content="en_US" />

	<!-- Twitter -->
	<meta property="twitter:card" content="summary_large_image" />
	<meta property="twitter:url" content="https://fictioneer.app" />
	<meta property="twitter:title" content="Fictioneer - Where Stories Come to Life" />
	<meta
		property="twitter:description"
		content="Download Fictioneer for free. Distraction-free writing software designed for novelists. Available for Windows, Mac, and Linux."
	/>
	<meta property="twitter:image" content="https://fictioneer.app/og.png" />
	<meta property="twitter:image:alt" content="Fictioneer - Distraction-Free Writing Software" />

	<!-- Additional Meta Tags -->
	<meta name="viewport" content="width=device-width, initial-scale=1.0" />
	<meta name="theme-color" content="#6366f1" />
	<meta name="apple-mobile-web-app-capable" content="yes" />
	<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent" />
	<meta name="apple-mobile-web-app-title" content="Fictioneer" />
</svelte:head>

<HeroSection />
<FeaturesSection />
<SocialProofSection />
<FinalCtaSection />
