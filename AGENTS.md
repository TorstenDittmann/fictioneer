# Repository Guidelines

## Project Structure & Modules
- apps/fictioneer: SvelteKit + Tauri desktop app (UI, exports, tooling). Example routes: `src/routes/+page.svelte`.
- apps/landing-page: SvelteKit marketing site. Built with Vite and Tailwind.
- apps/intelligence: Bun + Hono API for text generation. Entrypoint: `index.ts`.
- Root: Workspace manager, shared config (`.prettierrc`, `.github/workflows/*`). Use Bun with workspaces.

## Build, Test, and Development
- Root dev: `bun run dev` — runs workspaces in watch/dev mode via `workspace-utils`.
- Root build: `bun run build` — builds all apps.
- Lint: `bun run lint` — Prettier check (+ ESLint in Svelte apps).
- Type check: `bun run check` — Svelte type checks.
- Format: `bun run format` — Prettier write.
- App-specific:
  - Fictioneer: `bun run dev` / `bun run build` in `apps/fictioneer` (Tauri; requires Rust toolchain).
  - Landing Page: `bun run dev` / `bun run build` in `apps/landing-page`.
  - Intelligence: `bun run dev` (API server), `bun run build` in `apps/intelligence`.

## Coding Style & Naming
- Languages/tools: Bun, TypeScript, Svelte 5 runes.
- Prettier: tabs, single quotes, no trailing commas.
- Naming: snake_case for variables/functions/files/folders; PascalCase for types/interfaces.
- Type safety: never use `any`; prefer `const`; no underscore prefixes for private members.
- Svelte: use runes (`$state`, `$derived`), avoid legacy `$:`; prefer native DOM events (e.g., `onclick`) over `on:click`; avoid `:global` in styles; prefer `$app/state` over `$app/stores`.
- Structure: one component per file; keep components focused; extract logic to stores/helpers.

## Testing Guidelines
- Use `bun run check` (types/Svelte) and `bun run lint` (format/lint) locally.
- Intelligence service health check: `GET http://localhost:3001/health`.
- When adding logic-heavy code, include tests under `apps/<name>/tests`.

## Commit & Pull Requests
- Commits: concise, imperative (e.g., “Add EPUB export”, “Fix RTF escaping”). Scope optional.
- PRs: include summary, linked issues, and screenshots for UI changes. Note env/setup steps if relevant.
- CI must pass `lint` and `check`. For Tauri releases, do not commit secrets; CI uses GitHub secrets for signing.

## Security & Configuration
- Env: copy `.env.example` to `.env` per app. Required: `apps/intelligence` needs `GROQ_API_KEY`; `apps/fictioneer` needs `PUBLIC_INTELLIGENCE_SERVER_URL`.
- Never commit `.env` or credentials. Review `.github/workflows` before changing release/signing.

## Agent Notes (Automation)
- Do not start long-running dev servers in CI/automation.
- Follow the rules in `.rules` for style and Svelte usage; prefer Bun commands.
