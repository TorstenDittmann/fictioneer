// See https://svelte.dev/docs/kit/types#app.d.ts
// for information about these interfaces
declare global {
	namespace App {
		// interface Error {}
		// interface Locals {}
		// interface PageData {}
		// interface PageState {}
		// interface Platform {}
	}

	interface ImportMetaEnv {
		readonly PUBLIC_INTELLIGENCE_SERVER_URL: string;
	}

	interface ImportMeta {
		readonly env: ImportMetaEnv;
	}
}

export {};
