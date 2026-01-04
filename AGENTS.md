# AGENTS.md

This file provides guidance to AI Coding Agents when working with code in this repository.

## Project Overview

Fictioneer is a distraction-free, AI-assisted desktop writing application for fiction writers. It's a Bun monorepo with three apps:

- **apps/fictioneer**: SvelteKit + Tauri desktop app (main writing interface)
- **apps/intelligence**: Bun + Hono API server (AI writing assistance via OpenRouter)
- **apps/landing-page**: SvelteKit marketing website

## Commands

### Root (workspace)
```bash
bun dev           # Start all apps in dev mode
bun build         # Build all apps
bun run format    # Format all apps
bun run lint      # Lint all apps
bun run check     # Type check all apps
```

### Desktop App (apps/fictioneer)
```bash
cd apps/fictioneer
bun run dev       # Start Tauri + Vite dev server
bun run build     # Build desktop app
bun run check     # Svelte + TypeScript check
bun run lint      # ESLint + Prettier check
```

### Intelligence API (apps/intelligence)
```bash
cd apps/intelligence
bun run dev       # Start server with watch mode
bun run build     # Build to ./build
bun run start     # Run built server
```

### Landing Page (apps/landing-page)
```bash
cd apps/landing-page
bun run dev       # Start Vite dev server
bun run build     # Build for production
bun run start     # Run built server
```

## Architecture

### Desktop App Structure (apps/fictioneer)
- `src/lib/services/` - Core business logic
  - `projects.svelte.ts` - Project CRUD, file I/O (.fictioneer format)
  - `file.svelte.ts` - File system operations
  - `ai_writing_backend.ts` - AI continuation/rephrasing
  - `export/` - RTF/TXT export functionality
- `src/lib/state/` - Svelte 5 rune-based global state stores
  - `projects.svelte.ts` - Active project state
  - `settings.svelte.ts` - User preferences
  - `progress.svelte.ts` - Writing progress tracking
- `src/lib/components/` - UI components
- `src-tauri/` - Rust backend for native desktop features

### Intelligence API Structure (apps/intelligence)
- `server.ts` - Hono app entry point with health check at `/health`
- `production_api.ts` - Production AI endpoints (continuation, rephrasing)
- `marketing_api.ts` - Marketing/trial endpoints
- `validation.ts` - Request validation
- `client.ts` - Type-safe Hono client exported as `@fictioneer/intelligence/client`

### Cross-App Integration
The desktop app imports the intelligence client via workspace package:
```typescript
import { create_client } from '@fictioneer/intelligence/client';
```

## Code Style Rules

- **Use snake_case** for variables, functions, and file names
- **Use PascalCase** for types/interfaces
- **Never use `any`** - use `unknown` or proper types
- **Svelte 5 runes only** - use `$state`, `$derived`, etc. (no legacy `$:` reactivity)
- **Native event handlers** - use `onclick` not `on:click`
- **Use `$app/state`** not `$app/stores`
- **No `:global`** in Svelte style blocks
- **Use bits-ui** for UI components (see https://bits-ui.com/llms.txt)
- **Use Svelte MCP** for Svelte development assistance

## UI Component Library

bits-ui is used for accessible UI primitives. Reference: https://bits-ui.com/llms.txt

## File Format

Projects are stored as single `.fictioneer` files containing:
- Chapters and scenes hierarchy
- Metadata (word counts, timestamps)
- Notes and character information
