---
name: review
description: >
  Structured 4-phase code review with severity labeling. Produces actionable
  feedback, not vague suggestions. Works on staged changes, PRs, or file paths.
  Optimized for SvelteKit + Drizzle + TypeScript stacks.
---

# Dev Review — Structured 4-Phase Code Review

## Table of Contents
- [Usage](#usage)
- [Target Resolution](#target-resolution)
- [Phase 1: Context](#phase-1-context)
- [Phase 2: Architecture](#phase-2-architecture)
- [Phase 3: Line-by-Line](#phase-3-line-by-line)
- [Phase 4: Verdict](#phase-4-verdict)
- [Severity Labels](#severity-labels)
- [Output Format](#output-format)
- [Error Handling](#error-handling)

## Usage

```
/dev-review                    # Review staged files (errors if nothing staged)
/dev-review --staged           # Explicit staged review
/dev-review --pr current       # Review the open PR on current branch
/dev-review --pr 123           # Review a specific PR by number
/dev-review src/               # Review all source files under path
/dev-review src/lib/auth.ts    # Review a single file
```

## Target Resolution

Resolve the target before starting any phase:

1. **`--staged`** or no args: run `git diff --cached --name-only` to get staged files.
   - If nothing is staged and no args provided: stop with error — "Nothing staged. Pass a path, --pr, or stage files first."
   - Read each file in full + `git diff --cached -- <file>` for the diff context.

2. **`--pr current`**: run `gh pr view --json number` to get the PR number, then `gh pr diff` for the full diff.
   - If no open PR: stop with error — "No open PR on this branch. Use --pr <number> or pass a path."

3. **`--pr 123`**: run `gh pr diff 123` for the diff and `gh pr view 123 --json title,body,files` for metadata.

4. **`<path>`**: collect all source files under path using Glob (`**/*.ts`, `**/*.svelte`, `**/*.js`).
   - Exclude: `node_modules/`, `.svelte-kit/`, `dist/`, `build/`, `*.d.ts`, `*.min.js`.
   - Read each file in full. No diff available — review the full file content.

---

## Phase 1: Context (fast — read, don't analyze yet)

**Goal**: understand scope before forming any opinions.

1. Read the diff or files identified in target resolution.
2. Identify and note:
   - What changed (new feature, bug fix, refactor, schema change, route addition)?
   - Which modules are touched (routes, lib/server, lib/components, drizzle schema, API)?
   - What is the apparent intent of the change?
3. **Size check**: if the diff is >400 lines changed (additions + deletions), print a single warning:
   > "Large diff (N lines). Consider splitting into smaller PRs for safer review."
   Then continue — do not abort.
4. **Stack detection**: note which parts of the stack are involved:
   - SvelteKit routes (`+page.svelte`, `+page.server.ts`, `+layout.*`)?
   - Drizzle schema (`schema.ts`, `migrations/`)?
   - Tauri commands (`src-tauri/`, `invoke()`)?
   - API endpoints (`/api/` routes)?
   - Shared lib (`$lib/`, `lib/server/`)?

Output from Phase 1: a brief 3-5 line internal summary (not shown to user). Feed this into Phases 2–3.

---

## Phase 2: Architecture (high-level patterns)

**Goal**: find structural problems before reading individual lines.

Check each point that applies to the diff:

1. **Pattern consistency**: does the change follow the conventions already present in the codebase?
   - Check 2-3 similar existing files to establish the baseline pattern.
   - Flag deviations (e.g., direct DB calls in `+page.svelte` when `+page.server.ts` exists next to it).

2. **File placement**: are new files in the correct location?
   - Server-only logic: `lib/server/` or `*.server.ts` — never in `lib/` or `.svelte` files directly.
   - Reusable components: `lib/components/`.
   - Route-specific logic: co-located with the route.
   - Drizzle schema: `lib/server/db/schema.ts` or equivalent central location.

3. **Server/client boundary**: is there proper separation?
   - `+page.server.ts` handles data fetching, auth, mutations.
   - `.svelte` files only receive typed `data` from `load()` — no raw DB/env imports.
   - Private env vars (`$env/static/private`) never appear in `.svelte` or `*.ts` client files.

4. **Coupling**: does this change require unrelated modules to change? If yes, flag as `[important]`.

5. **Drizzle schema changes** (if any):
   - Are migrations generated (check for new file in `drizzle/` or `migrations/`)?
   - Are relations in `schema.ts` consistent with the new columns/tables?
   - Are nullable columns intentional or an oversight?

---

## Phase 3: Line-by-Line

**Goal**: catch concrete bugs and anti-patterns. Be specific — cite file and line number.

For each changed file, check all applicable categories:

### Correctness
- Unhandled `null` / `undefined` — especially after DB queries that may return `undefined`
- Type narrowing gaps — `as Type` without a guard, unchecked array access
- Race conditions — two `await`s that could interleave if called concurrently
- Off-by-one errors in loops, slice, pagination offsets
- Missing `return` in early-exit branches

### Svelte 5 Patterns
- `$effect` used for a value that could be `$derived` — flag as `[important]`
- `$state` on a large API response object that's only reassigned — suggest `$state.raw`
- `on:click` / `on:submit` syntax (Svelte 4) instead of `onclick` / `onsubmit` — flag as `[nit]`
- `<slot>` instead of `{#snippet}` + `{@render}` — flag as `[nit]`
- `export let` instead of `$props()` — flag as `[nit]`
- Stores (`writable`, `readable`, `derived` from `svelte/store`) when a class with `$state` fields is more appropriate
- `$app/stores` instead of `$app/state` — flag as `[important]` (deprecated)

### Security
- Missing auth/session check on a `+page.server.ts` load or action that handles sensitive data
- `{@html ...}` without explicit sanitization — flag as `[blocking]`
- Private env var (`SECRET_*`, `DATABASE_URL`, etc.) referenced in a client-accessible file — flag as `[blocking]`
- User-supplied input passed directly to Drizzle raw SQL (`sql` template tag) without parameterization — flag as `[blocking]`
- CORS headers set too broadly on API routes

### Performance
- N+1 pattern: Drizzle query inside a loop — suggest using `with` (eager load relations) or a single query with `inArray`
- Sequential `await` calls that are independent — suggest `Promise.all`
- Missing `Promise.all` for parallel data fetching in `load()` functions
- Blocking synchronous operations inside an `async` route handler
- Large objects passed as props that trigger unnecessary re-renders

### TypeScript
- `any` — flag as `[important]` unless it's a narrow, justified cast
- `@ts-ignore` — flag as `[important]`, suggest `@ts-expect-error` with a comment instead
- Missing return type on exported server functions
- Incorrect or missing generics on Drizzle queries

---

## Phase 4: Verdict

Produce the structured review output. Use this exact format:

```
## Review: [brief descriptive title]

**Decision:** ✅ Approve | 💬 Comment | 🔄 Request Changes

> [One sentence summary of the overall change and its quality.]

### Findings

| # | Severity | Location | Issue | Suggested Fix |
|---|----------|----------|-------|---------------|
| 1 | [blocking] | src/routes/+page.server.ts:42 | N+1 query in loop over users | Use `.with({ posts: true })` relation |
| 2 | [important] | src/lib/components/Form.svelte:18 | `$effect` recomputes derived value | Replace with `$derived(form.value * 2)` |
| 3 | [nit] | src/routes/+page.svelte:7 | `on:click` Svelte 4 syntax | Change to `onclick={...}` |

### What's Good
- [List concrete positives — clean abstractions, good error handling, thorough types, etc.]

### Summary
[1-2 sentences. Overall quality verdict. What the reviewer should focus on before merging.]
```

**Decision rules:**
- `✅ Approve` — zero `[blocking]` or `[important]` findings
- `💬 Comment` — only `[nit]` or `[suggestion]` findings; no action required
- `🔄 Request Changes` — one or more `[blocking]` or `[important]` findings present

---

## Severity Labels

| Label | Meaning |
|-------|---------|
| `[blocking]` | Must fix before merge. Correctness bug, security hole, or data integrity risk. |
| `[important]` | Should fix. Will cause problems at scale or in edge cases, but won't break immediately. |
| `[nit]` | Style or minor preference. Acceptable to leave, but cleaner if fixed. |
| `[suggestion]` | Alternative approach worth considering. No action required. |
| `[praise]` | Positive callout — good pattern, clean abstraction, thorough handling. |

---

## Error Handling

- **Nothing staged + no args**: print "Nothing staged. Pass a path, --pr, or stage files first." and stop.
- **`--pr current` with no open PR**: print "No open PR on this branch. Use --pr <number> or pass a path." and stop.
- **`gh` not available**: print "gh CLI not found. Install it or pass a path instead of --pr." and stop.
- **Path not found**: print "Path not found: <path>. Check the path and try again." and stop.
- **Empty diff (PR with no changes)**: print "PR has no file changes to review." and stop.
- **Binary files in diff**: skip them silently. Note in the summary if images/assets were excluded.
