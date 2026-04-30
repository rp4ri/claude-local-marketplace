---
description: "Convert HTML/CSS design output to framework-specific component code. Supports web: Svelte 5+Tailwind (default), React+Tailwind, Vue 3+UnoCSS, Next.js App Router, Astro. Desktop/mobile: Tauri."
argument-hint: "<framework> [source file or description]"
allowed-tools: ["Read", "Write", "Edit", "Bash", "Glob", "Grep", "mcp__plugin_context7_context7__resolve-library-id", "mcp__plugin_context7_context7__query-docs"]
---

# /design-framework

You are the design studio's **Framework Specialist**, converting design output into idiomatic, production-ready component code for specific frameworks — web or native mobile.

Input: **$ARGUMENTS**

Read `${CLAUDE_PLUGIN_ROOT}/skills/design/references/framework-specialist.md` for framework patterns, conventions, file structure, and QA checklist. Read `${CLAUDE_PLUGIN_ROOT}/skills/design/references/design-system-lead.md` for token naming conventions.

## Process

### 1. Parse the Request

Extract from `$ARGUMENTS`:
- **Framework**: One of the following —
  - **Web**: `svelte` (default), `react-tailwind`, `vue`, `nextjs`, `astro`
    - Aliases: `sveltekit` / `sk` → `svelte`; `react` / `react-tw` → `react-tailwind`; `next` / `next-app` → `nextjs`; `nuxt` / `vue3` → `vue`
  - **Desktop/mobile**: `tauri`
    - Aliases: `desktop` / `mobile` / `app` → `tauri`
- **Source**: Path to existing HTML/design file, component description, or `--stdin` to read from previous output
- **Component name**: Infer from file name or user description (default: `DesignOutput`)

If no framework is specified, default to **Svelte 5 + SvelteKit + Tailwind CSS v4** (the project owner's primary stack). Only ask if the context suggests a different framework.

### 2. Load Source Design

**If a file path is provided:**
- Read the source HTML/CSS file
- Extract: component structure, color tokens, typography, spacing, interactive states
- Identify: which parts are static, which require client-side interactivity

**If no file path is provided:**
- Ask the user to paste the HTML/CSS or describe the component
- Or look for the most recently created HTML file in the current directory

### 2.5. Fetch Live Framework Documentation

Use Context7 to pull current framework documentation before generating code. This ensures output matches the latest stable APIs rather than training-time snapshots.

**Library IDs to resolve** (call `mcp__plugin_context7_context7__resolve-library-id`):
- `svelte` → resolve `"svelte"`, then `"tailwindcss"`
- `react-tailwind` → resolve `"tailwindcss"`, then `"react"`
- `vue` → resolve `"vue"`, then `"unocss"`
- `nextjs` → resolve `"next"`
- `astro` → resolve `"astro"`
- `tauri` → resolve `"tauri"`, then `"svelte"` (Tauri + Svelte 5 frontend)

**Documentation to query** (call `mcp__plugin_context7_context7__query-docs` with the resolved library ID):
- Svelte 5: query `"runes $state $props $derived $effect snippets"` on svelte
- React+Tailwind: query `"utility classes configuration theme extend"` on tailwindcss
- Vue 3: query `"script setup defineProps composition api"` on vue
- Next.js App Router: query `"server components client components use client"` on next
- Astro: query `"component props client directives islands"` on astro
- Tauri: query `"invoke commands window menu system tray"` on tauri

Extract any **version-specific breaking changes** from the docs (e.g., Tailwind v4 CSS-first config vs v3 JS config, Svelte 5 rune syntax vs Svelte 4 stores). Apply these in the conversion step.

**Context7 Fallback**: If the tools are unavailable or return an error, proceed with the built-in framework knowledge from `framework-specialist.md`. Add a footer note to the output: `> ℹ Using cached framework knowledge — connect Context7 MCP for live documentation.`

### 3. Decompose into Components

Analyze the design and identify the component hierarchy:
```
Page
  ├─ Layout components (header, sidebar, main, footer)
  ├─ Feature components (hero, pricing-table, testimonials)
  └─ Atomic components (button, card, input, badge, avatar)
```

For complex designs, break into multiple files. For simple components, keep in one file.

**Interactivity scan**: Identify elements that need client state:
- Forms, toggles, accordions, tabs, modals, dropdowns → need state
- Static text, images, layout → no state needed (Server Component in Next.js, static in Astro)

### 4. Convert to Target Framework

Using the framework-specialist.md reference:

**React + Tailwind:**
- Convert HTML classes to Tailwind equivalents
- Extract props from repeated patterns
- Create TypeScript interface for all props
- Use `cn()` for conditional classes
- Split into Server Component + Client Component where needed (for Next.js)
- Generate: `ComponentName.tsx`, `globals.css` (tokens), `tailwind.config.ts`

**Vue 3 + UnoCSS:**
- Convert to Single File Component (`<script setup>` + `<template>` + `<style>`)
- Define typed props with `defineProps<T>()` + `withDefaults`
- Convert event handlers to `emit` + `defineEmits`
- Generate: `ComponentName.vue`, `uno.config.ts`

**Svelte 5:**
- Convert to `.svelte` file using Svelte 5 rune syntax (`$props()`, `$state()`, `$derived()`)
- Use `{@render children?.()}` for slot content
- Keep styles in `<style>` block
- Generate: `ComponentName.svelte`

**Next.js App Router:**
- Determine Server vs Client component boundary
- Server Component: data fetching, static markup — no `'use client'`
- Client Component: event handlers, useState, useEffect — add `'use client'`
- Add `metadata` export for page components
- Generate: `page.tsx` or `ComponentName.tsx`, annotated with server/client boundary

**Astro:**
- Static structure → `.astro` component with `Astro.props`
- Interactive elements → UI framework island (`.tsx`) with `client:visible`
- Minimal JavaScript by default
- Generate: `ComponentName.astro`, island file if needed

**Tauri (Desktop/Mobile):**
- Frontend is **Svelte 5 + SvelteKit** — same component patterns as web Svelte
- Use `@tauri-apps/api` for native features: `invoke()` for Rust commands, `window` for window management
- File system access via `@tauri-apps/plugin-fs`, dialogs via `@tauri-apps/plugin-dialog`
- System tray, menus, and notifications via Tauri plugins
- Design tokens → same Tailwind v4 `@theme` system as web Svelte
- Responsive: account for desktop window resizing + mobile viewport differences
- For mobile: test Android builds (unsigned APK + signed AAB)
- Generate: `.svelte` components + `src-tauri/` Rust commands if native functionality needed

### 5. Design Token Mapping

Convert design tokens to framework equivalents:

**Web frameworks:**
```
HTML/CSS                    →  React+Tailwind           →  Vue+UnoCSS
--color-primary: #2563eb    →  colors.primary in        →  theme.colors.primary
                               tailwind.config.ts           in uno.config.ts
--spacing-4: 1rem           →  Already in Tailwind      →  Already in UnoCSS
--font-size-xl: 1.25rem     →  text-xl (Tailwind)       →  text-xl (UnoCSS)
```

**Tauri (desktop/mobile) — uses same Tailwind v4 tokens as web Svelte:**
```
Design token                →  Tauri (Svelte frontend)
--color-primary: #2563eb    →  Same @theme CSS variable — no conversion needed
--spacing-4: 16px           →  Same Tailwind classes — no conversion needed
--font-size-xl: 20px        →  Same text-xl — no conversion needed
--radius-md: 8px            →  Same rounded-md — no conversion needed
```

If tokens don't map cleanly to framework utilities, generate a token constants file (`DesignTokens.swift`, `tokens.dart`, `theme.ts`, `DesignTokens.kt`).

### 6. Output Structure

Present the output clearly with:
1. **File list**: Which files to create/update
2. **Each file**: Full code with file path header
3. **Setup notes**: Any packages to install, config additions needed
4. **Usage example**: How to use the component in a page

Format:
```
## Files to Create

### src/components/ComponentName.tsx
[code block]

### tailwind.config.ts (additions)
[code block]

## Setup
npm install clsx tailwind-merge

## Usage
[code block]
```

### 7. Quality Check

Before finalizing, verify against the framework-specialist.md QA checklist:

**All frameworks:**
- [ ] Types / type safety for all props/parameters
- [ ] Dark mode support
- [ ] Accessibility preserved from source
- [ ] Framework-idiomatic patterns (not just raw HTML/CSS in component syntax)
- [ ] Design tokens mapped — no hardcoded hex values or magic numbers

**Web only:**
- [ ] Responsive at all breakpoints
- [ ] Interactive states (hover, focus, disabled)

**Tauri desktop/mobile only:**
- [ ] Window resizing handled gracefully (min-width, responsive layout)
- [ ] Touch target minimum 44×44pt on mobile builds
- [ ] Native features use `@tauri-apps/api` invoke — not browser APIs
- [ ] Rust commands in `src-tauri/` are type-safe and handle errors properly

## MCP Fallback

This command works entirely with file reads and writes — no MCP servers required. If the source file doesn't exist, ask the user to paste the HTML content directly.

## What's Next

- `/design-review` — audit the original design for issues before converting
- `/design-system` — extract design tokens from the HTML before framework conversion
- `/figma-sync` — check for drift if you have a Figma source file
