# AGENTS

This guide is for agentic coding tasks in the Fictioneer monorepo.

## Repo layout
- `apps/fictioneer`: SvelteKit + Tauri desktop app.
- `apps/landing-page`: SvelteKit marketing site.
- `apps/intelligence`: Bun + Hono API server.
- Root uses Bun workspaces with `workspace-utils`.

## Tooling and runtime
- Use Bun (`bun`), version 1.3.1 per `package.json` engines.
- ESM is standard (`type: module` in packages).
- TypeScript is strict in all apps.
- Prettier + ESLint are the primary formatting/lint tools.

## Install
- From repo root: `bun install` (installs all workspaces).
- For Tauri app only: you can also run `bun install` in `apps/fictioneer`.

## Root commands (run from repo root)
- Dev: `bun run dev` (workspace-utils runs each app's dev script).
- Build: `bun run build`.
- Format: `bun run format`.
- Lint: `bun run lint`.
- Type check: `bun run check`.

## apps/fictioneer commands
- Dev (Tauri): `bun run dev`.
- Build (Tauri): `bun run build`.
- Vite-only: `bun run vite:dev`, `bun run vite:build`, `bun run vite:preview`.
- Format: `bun run format`.
- Lint: `bun run lint`.
- Type check: `bun run check` or `bun run check:watch`.
- Tests: `bun run test`, `bun run test:watch`, `bun run test:coverage`.

## apps/landing-page commands
- Dev: `bun run dev`.
- Build: `bun run build`.
- Preview: `bun run preview`.
- Format: `bun run format`.
- Lint: `bun run lint`.
- Type check: `bun run check` or `bun run check:watch`.

## apps/intelligence commands
- Dev: `bun run dev` (watch mode).
- Build: `bun run build`.
- Start: `bun run start`.
- Format: `bun run format`.
- Lint: `bun run lint` (Prettier check only).

## Running a single test
- Tests live in `apps/fictioneer` and use Bun's test runner.
- From `apps/fictioneer`: `bun test src/lib/services/text_analysis/word_analysis.test.ts`.
- You can pass any specific test file path the same way.

## Formatting rules (Prettier)
- Tabs for indentation (`useTabs: true`).
- Single quotes for strings.
- No trailing commas.
- `printWidth` is 100 in app packages.
- Svelte + Tailwind Prettier plugins are enabled in UI apps.

## ESLint and linting
- ESLint is configured for Svelte + TypeScript in `apps/fictioneer` and `apps/landing-page`.
- `no-undef` is disabled for TypeScript.
- Svelte lint rules are mostly defaults with a few local overrides.

## Imports and module style
- Use ESM `import` syntax everywhere.
- Keep `.js` extensions in TS imports for runtime ESM (see `*.ts` files).
- Prefer `import type` for type-only imports.
- Order imports: external packages, then local modules.

## Naming conventions
- Functions, methods, and variables: `snake_case` (e.g., `generate_id`).
- Classes, interfaces, types: `PascalCase`.
- Constants: `SCREAMING_SNAKE_CASE`.
- Files and folders: `snake_case`.
- Test files: `*.test.ts` next to the module under test.

## TypeScript conventions
- `strict: true` across apps; keep types explicit.
- Prefer `interface` for object shapes and `type` for unions.
- Use `satisfies` to validate config objects without widening types.
- Avoid `any`; use generics or explicit unions instead.

## Svelte and UI conventions
- SvelteKit routes follow `+page.svelte`, `+page.ts`, `+layout.svelte` patterns.
- Use Svelte 5 runes where existing code does (`$state`, etc.).
- State/services that rely on runes live in `.svelte.ts` modules.
- Keep Tailwind class order stable (Prettier plugin handles ordering).
- Reuse existing UI components from `src/lib/components` when possible.

## Error handling
- Prefer early returns with `null`/`false` when the value is optional.
- For async IO or API calls, wrap with `try/catch` and add context.
- Server errors should be logged/tracked (see `apps/intelligence/server.ts`).
- Return structured error objects rather than raw strings when possible.

## Testing conventions
- Bun test runner with `describe`, `it`, `expect`.
- Test names are descriptive and cover edge cases and empty input.
- Keep test data inline and readable.

## CI signals
- GitHub Actions `diagnostics` runs `bun run lint` and `bun run check`.
- Publish workflow builds the Tauri app from `apps/fictioneer`.
- `PUBLIC_INTELLIGENCE_SERVER_URL` is expected in CI for diagnostics.

## Workspace etiquette for agents
- Do not introduce new tooling unless required.
- Keep changes scoped to the relevant app.
- Match existing naming and formatting conventions.
- Avoid large refactors unless explicitly requested.

## Cursor/Copilot rules
- No `.cursor/rules`, `.cursorrules`, or `.github/copilot-instructions.md` were found.

## Quick file pointers
- UI app routes: `apps/fictioneer/src/routes`, `apps/landing-page/src/routes`.
- UI components: `apps/fictioneer/src/lib/components`, `apps/landing-page/src/lib/components`.
- Intelligence server entry: `apps/intelligence/server.ts`.
- Tauri config and Rust code: `apps/fictioneer/src-tauri`.

## Notes on Rust/Tauri
- Tauri build/dev commands are driven by the `apps/fictioneer` scripts.
- Rust dependencies are managed via Cargo in `apps/fictioneer/src-tauri`.
- Use `tauri dev`/`tauri build` via `bun run dev`/`bun run build`.

## Suggested workflow for changes
- Format: `bun run format` in the target app.
- Lint: `bun run lint` in the target app.
- Type check: `bun run check` in the target app.
- Tests (if relevant): `bun run test` in `apps/fictioneer`.

## Single test examples
- `bun test src/lib/services/file.test.ts`.
- `bun test src/lib/services/text_analysis/readability.test.ts`.

## Environment
- Default dev server ports are set in the app-specific Vite configs.
- `apps/landing-page` Vite server runs on port 5187.
- `apps/intelligence` defaults to port 3001.

## Misc
- Keep documentation updates concise and code-focused.
- Only add comments when the code is not obvious.
- Use ASCII in new files unless non-ASCII is already required.
