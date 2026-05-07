---
name: migrate
description: >
  Structured technology migration — from inventory to execution. Handles framework
  upgrades, ORM swaps, CSS migrations, API versioning, dependency replacements.
  Use when user wants to migrate between technologies safely with rollback points.
---

# dev-migrate — Structured Technology Migration

Five-phase pipeline: Inventory → Compatibility → Plan → Execution → Validation.
Each phase produces a persisted artifact. Execution is gated per-phase with rollback.

## Table of Contents
- [Usage](#usage)
- [Arguments](#arguments)
- [Phase 1: Inventory](#phase-1-inventory)
- [Phase 2: Compatibility Analysis](#phase-2-compatibility-analysis)
- [Phase 3: Migration Plan](#phase-3-migration-plan)
- [Phase 4: Execution](#phase-4-execution)
- [Phase 5: Validation](#phase-5-validation)
- [Common Migrations](#common-migrations)
- [Error Handling](#error-handling)

---

## Usage

```
/dev-migrate tailwind v3 to v4
/dev-migrate stores to runes --plan-only
/dev-migrate prisma to drizzle --execute
/dev-migrate express to sveltekit --dry-run
/dev-migrate react to svelte 5 --path src/components/
/dev-migrate class components to runes --plan-only
```

---

## Arguments

The raw arguments are: $ARGUMENTS

**Parse the arguments as follows:**

1. **`<from> to <to>`** — required. Everything before ` to ` is `FROM`, everything after (before any flags) is `TO`. Examples:
   - `"tailwind v3 to v4"` → FROM=`tailwind v3`, TO=`v4`
   - `"stores to runes"` → FROM=`stores`, TO=`runes`
   - `"prisma to drizzle"` → FROM=`prisma`, TO=`drizzle`
   - `"react to svelte 5"` → FROM=`react`, TO=`svelte 5`
   - If ` to ` is not present in the arguments, stop and tell the user: "Usage: /dev-migrate <from> to <to> [--plan-only | --execute | --dry-run]"

2. **`--plan-only`** — produce the plan (Phases 1–3) but do not execute. Default when `--execute` is not passed.

3. **`--execute`** — run Phases 1–4 (asks confirmation per phase unless `--autonomous` is also set).

4. **`--dry-run`** — show what would change per phase without writing source files. Runs all 5 phases but diffs are printed, not applied. Still writes artifacts to `.dev-studio/migration/`.

5. **`--path <dir>`** — limit migration scope to a specific directory. Default: current working directory.

6. **`--autonomous`** — skip per-phase confirmation prompts when used with `--execute`. Auto-commits each phase.

**Set these variables:**
```
FROM        = parsed from arguments
TO          = parsed from arguments
PLAN_ONLY   = true if --execute not present (default)
EXECUTE     = true if --execute present
DRY_RUN     = true if --dry-run present
SCOPE_PATH  = value after --path, or "." if not present
AUTONOMOUS  = true if --autonomous present
```

If `DRY_RUN=true`, force `EXECUTE=true` and `PLAN_ONLY=false` — dry-run implies execution intent.

---

## Preflight

Before running any phase:

1. **Create output directory**:
   ```bash
   mkdir -p .dev-studio/migration
   ```

2. **Verify git repo** (required for rollback in Phase 4):
   ```bash
   git rev-parse --is-inside-work-tree
   ```
   If not a git repo and `EXECUTE=true` and `DRY_RUN=false`:
   warn the user — "No git repo detected. Execution mode requires git for rollback safety. Use --plan-only or initialize git first."
   Stop if user does not confirm.

3. **Report parsed arguments** to the user:
   ```
   Migration: [FROM] → [TO]
   Scope: [SCOPE_PATH]
   Mode: [plan-only | execute | dry-run]
   Output: .dev-studio/migration/
   ```

---

## Phase 1: Inventory

**Goal**: Find every usage of `FROM` technology in the codebase.

### 1a. Scan for usages

Use Grep and Glob to find all files containing patterns related to `FROM`. Cast a wide net — search for:
- Import statements (`import`, `require`, `from`, `use`)
- Config file names (e.g., `tailwind.config.*`, `prisma/schema.prisma`)
- API calls and identifiers specific to `FROM`
- Type annotations referencing `FROM`

For well-known migrations, use the pattern tables in [Common Migrations](#common-migrations) to seed your search terms.

### 1b. Categorize findings by complexity

For each file and usage found, classify:

| Complexity | Criteria |
|------------|----------|
| **trivial** | 1:1 mechanical replacement — no logic change (e.g., rename a class, update an import path) |
| **moderate** | Requires restructuring within the file — same intent, different API (e.g., `writable()` → `$state` class) |
| **complex** | Architectural change — touches multiple files, changes data flow, or requires new abstractions |

### 1c. Write inventory artifact

Write `.dev-studio/migration/inventory.json`:

```json
{
  "from": "<FROM>",
  "to": "<TO>",
  "scope": "<SCOPE_PATH>",
  "scanned_at": "<ISO 8601>",
  "summary": {
    "total_files": 0,
    "total_instances": 0,
    "trivial": 0,
    "moderate": 0,
    "complex": 0
  },
  "files": [
    {
      "path": "src/lib/store.ts",
      "instances": 4,
      "complexity": "moderate",
      "patterns": ["writable(", "derived(", "$store"],
      "notes": "3 writable stores, 1 derived — all local component state"
    }
  ],
  "config_files": ["tailwind.config.js"],
  "entry_points": ["src/app.css", "src/routes/+layout.svelte"]
}
```

### 1d. Report to user

```
Phase 1 — Inventory complete
  Files affected: N
  Total instances: N
  Complexity: N trivial | N moderate | N complex
  Config files: [list]
  Artifact: .dev-studio/migration/inventory.json
```

If zero files found: "No usages of [FROM] found in [SCOPE_PATH]. Nothing to migrate."
Stop.

---

## Phase 2: Compatibility Analysis

**Goal**: Understand what changes are breaking, what tools exist, and what blockers are present.

### 2a. Research breaking changes

Use WebSearch to find:
- Official migration guide for `FROM` → `TO`
- Breaking changes between versions
- Community-reported gotchas not in official docs

Search queries to try:
- `"[FROM] to [TO] migration guide"`
- `"[FROM] [TO] breaking changes"`
- `"[FROM] [TO] codemods"`

For migrations in the [Common Migrations](#common-migrations) table, use the built-in knowledge first, then supplement with WebSearch for version-specific details.

### 2b. Identify blockers

Blockers are patterns in the inventory that:
- Have **no equivalent** in `TO` (requires rearchitecting)
- Depend on **packages that don't support `TO`** yet
- Are **too entangled** to migrate in isolation

Flag each blocker with: file, pattern, reason, suggested workaround.

### 2c. Identify helpers

- Codemods: official or community scripts that automate parts of the migration
- Migration tools: e.g., `svelte-migrate`, `@tailwindcss/upgrade`
- Official guides with step-by-step instructions

### 2d. Write compatibility artifact

Write `.dev-studio/migration/compatibility.md`:

```markdown
# Compatibility Analysis: [FROM] → [TO]

## Breaking Changes
- [list of breaking changes relevant to this codebase's patterns]

## Blockers
| File | Pattern | Reason | Workaround |
|------|---------|--------|------------|
| ...  | ...     | ...    | ...        |

## Helpers
- **Codemod**: `npx [tool]` — automates [what]
- **Guide**: [URL]

## Dependency Status
| Package | Current | Supports [TO]? | Action |
|---------|---------|----------------|--------|
| ...     | ...     | Yes/No/Partial  | ...    |
```

### 2e. Report to user

```
Phase 2 — Compatibility Analysis complete
  Breaking changes: N relevant to this codebase
  Blockers: N (require manual attention)
  Helpers found: [codemod names if any]
  Artifact: .dev-studio/migration/compatibility.md
```

---

## Phase 3: Migration Plan

**Goal**: Group changes into ordered phases, each safe to execute and roll back independently.

### 3a. Build phase sequence

Order phases by dependency — foundational changes first:
1. Config / build tool changes (must come first — affects everything downstream)
2. Dependency installs / removals
3. Entry points and global files
4. Shared utilities and lib files
5. Feature modules (can often parallelize across modules)
6. Tests and fixtures
7. Cleanup (remove old config, dead imports)

Each phase must be:
- **Self-contained**: files in the phase don't depend on a later phase being done first
- **Verifiable**: clear success criteria (tests pass, types check, page loads)
- **Rollbackable**: `git checkout <files>` is sufficient to undo

### 3b. Write plan artifact

Write `.dev-studio/migration/plan.md`:

```markdown
# Migration Plan: [FROM] → [TO]
Generated: [date]
Total phases: N | Estimated effort: [X trivial + Y moderate + Z complex]

## Phase 1 — [Name]
**Description**: [what this phase does]
**Files**: [list]
**Complexity**: trivial | moderate | complex
**Rollback**: `git checkout -- [files]`
**Verify after**:
- [ ] `tsc --noEmit` passes
- [ ] `vitest run` passes (or relevant test command)
- [ ] [specific thing to check for this migration]

## Phase 2 — [Name]
...

## Manual work required
[List any complex/blocked items that need human judgment]

## Skipped (no equivalent)
[Patterns with no [TO] equivalent — document the trade-off]
```

### 3c. Report to user

```
Phase 3 — Migration Plan complete
  Phases: N
  Automated: N phases (trivial/moderate)
  Manual review: N items
  Artifact: .dev-studio/migration/plan.md
```

If `PLAN_ONLY=true`: stop here and display the plan. Tell the user:
"Run `/dev-migrate [FROM] to [TO] --execute` to execute the plan."

---

## Phase 4: Execution

**Runs only when `EXECUTE=true`.**

For each phase in the plan (in order):

### 4a. Confirm (unless --autonomous)

If `AUTONOMOUS=false`, ask the user before each phase:
```
Ready to execute Phase N — [name]?
Files: [list]
Complexity: [level]
[y/n]
```
If user says no: skip this phase, mark it SKIPPED in the report.

### 4b. Execute the phase

Apply changes using Edit/Write tools. For well-known migrations, follow the pattern tables in [Common Migrations](#common-migrations) exactly.

If `DRY_RUN=true`: instead of applying edits, print a unified diff of what would change:
```diff
--- src/lib/store.ts (before)
+++ src/lib/store.ts (after)
@@ -1,5 +1,5 @@
-import { writable } from 'svelte/store';
+// reactive class replaces writable store
```
Do not write source files. Continue to next phase.

### 4c. Verify the phase

After each phase (skip if `DRY_RUN=true`):

1. **Type check**:
   ```bash
   npx tsc --noEmit 2>&1 | head -50
   ```
   Or if using `ty`: `ty check 2>&1 | head -50`

2. **Run tests** (if test command detected):
   ```bash
   npx vitest run 2>&1 | tail -20
   ```
   Or `pytest -q` for Python projects.

3. **Check for obvious regressions**: grep for common error patterns in the changed files.

If verification fails:
- Roll back: `git checkout -- <changed files from this phase>`
- Report what failed and why
- Mark phase as FAILED in the report
- Ask user whether to continue with remaining phases or stop

### 4d. Commit the phase

If verification passes and `DRY_RUN=false`:
```bash
git add <changed files>
git commit -m "migrate(phase-N): [phase name]"
```

Report: "Phase N complete — committed as [hash]"

---

## Phase 5: Validation

**Goal**: Confirm the migration is complete and nothing regressed.

### 5a. Full test suite

```bash
# Detect and run the project's test command
npx vitest run     # or pytest, jest, etc.
```

### 5b. Full type check

```bash
npx tsc --noEmit --strict
```

Report any new errors not present before the migration.

### 5c. Regression check

Re-scan the codebase for any remaining `FROM` patterns using the same Grep patterns from Phase 1. Anything still present = incomplete migration item.

### 5d. Write final report

Write `.dev-studio/migration/report.md`:

```markdown
# Migration Report: [FROM] → [TO]
Completed: [date]

## Stats
- Files migrated: N
- Instances replaced: N
- Phases completed: N / N
- Phases failed: N
- Phases skipped: N
- Commits created: N

## Remaining manual work
[List any items that need human attention]

## Residual [FROM] patterns
[Any usages that couldn't be migrated automatically]

## Test results
- Before: [baseline if captured]
- After: [N passing, N failing]

## Type check
- Errors before: N
- Errors after: N
```

### 5e. Final report to user

Display the report and highlight:
- What was migrated automatically
- What still needs manual attention
- Any regressions introduced

---

## Common Migrations

Built-in pattern knowledge for these migrations. Used in Phase 1 (search terms) and Phase 4 (transformation rules).

### Svelte 4 → Svelte 5 (stores → runes)

| Before | After | Complexity |
|--------|-------|------------|
| `export let prop = ...` | `let { prop } = $props()` | trivial |
| `on:click={handler}` | `onclick={handler}` | trivial |
| `on:submit\|preventDefault` | `onsubmit={(e) => { e.preventDefault(); handler(e) }}` | moderate |
| `<slot>` | `{#snippet children()}{/snippet}` + `{@render children()}` | moderate |
| `$$slots.default` | `{#if children}` with snippet prop | moderate |
| `$: value = expr` | `let value = $derived(expr)` | trivial |
| `$: { sideEffect() }` | `$effect(() => { sideEffect() })` | trivial |
| `writable(init)` (local) | `let x = $state(init)` | trivial |
| `writable(init)` (shared) | `class Store { value = $state(init) }` singleton | moderate |
| `derived(store, fn)` | `$derived(fn())` or `$derived.by(() => fn())` | moderate |
| `get $store` in component | direct property access | trivial |
| `import { get } from 'svelte/store'` | remove — use direct access | trivial |

Search terms for Phase 1: `export let`, `on:`, `<slot`, `$:`, `writable(`, `derived(`, `readable(`, `$app/stores`

### Tailwind v3 → v4

| Before | After | Complexity |
|--------|-------|------------|
| `tailwind.config.js` content array | `@source` directives in CSS | moderate |
| `theme.extend.colors` | `@theme { --color-*: ... }` in CSS | moderate |
| `theme.extend.spacing` | `@theme { --spacing-*: ... }` in CSS | moderate |
| `@apply` with custom utilities | direct CSS or `@utility` | moderate |
| `theme()` in CSS | `var(--color-*)` CSS variables | moderate |
| `darkMode: 'class'` config | `@variant dark (&:where(.dark, .dark *))` | complex |
| Arbitrary values `[#fff]` | same — still supported | trivial |
| Plugin `addUtilities` | `@plugin` with updated API | complex |
| `npx tailwindcss -i` CLI | `npx @tailwindcss/cli` | trivial |

Search terms for Phase 1: `tailwind.config`, `@apply`, `theme(`, `className=`, `class=`

### Prisma → Drizzle

| Before | After | Complexity |
|--------|-------|------------|
| `schema.prisma` model definitions | `schema.ts` with `pgTable`/`sqliteTable` | complex |
| `PrismaClient` instantiation | `drizzle(connection)` | moderate |
| `prisma.model.findMany(where)` | `db.select().from(table).where(eq(...))` | moderate |
| `prisma.model.create(data)` | `db.insert(table).values(data)` | moderate |
| `prisma.model.update(where, data)` | `db.update(table).set(data).where(eq(...))` | moderate |
| `prisma.model.delete(where)` | `db.delete(table).where(eq(...))` | moderate |
| `include: { relation: true }` | explicit join with `leftJoin` | complex |
| `prisma.$transaction([...])` | `db.transaction(async (tx) => {...})` | moderate |
| `npx prisma migrate dev` | `npx drizzle-kit push` | trivial |

Search terms for Phase 1: `PrismaClient`, `prisma.`, `from '@prisma/client'`, `schema.prisma`

### Express/Fastify → SvelteKit

| Before | After | Complexity |
|--------|-------|------------|
| `app.get('/path', handler)` | `src/routes/path/+server.ts` with `GET` export | moderate |
| `req.body` | `await request.json()` or `await request.formData()` | trivial |
| `res.json(data)` | `return json(data)` from `@sveltejs/kit` | trivial |
| Middleware `app.use(fn)` | `hooks.server.ts` handle function | complex |
| Session middleware | `locals` in hooks + `event.locals` | complex |
| Auth middleware | `handle` hook in `hooks.server.ts` | complex |
| `req.params.id` | `params.id` from route function arg | trivial |
| Error handler `(err, req, res, next)` | `handleError` in `hooks.server.ts` | moderate |
| Static file serving | SvelteKit handles via `static/` dir | trivial |

Search terms for Phase 1: `app.get(`, `app.post(`, `app.use(`, `express()`, `fastify()`, `req.body`, `res.json`

### React → Svelte 5

| Before | After | Complexity |
|--------|-------|------------|
| `useState(init)` | `let x = $state(init)` | trivial |
| `useEffect(() => {}, [deps])` | `$effect(() => {})` (deps auto-tracked) | moderate |
| `useMemo(() => expr, [deps])` | `let x = $derived(expr)` | trivial |
| `useCallback(fn, [deps])` | plain function (Svelte tracks refs) | trivial |
| `useRef(null)` | `let el: HTMLElement` + `bind:this={el}` | moderate |
| `useContext(Ctx)` | module-level `$state` or Svelte context API | complex |
| `React.createContext` | `setContext`/`getContext` from `svelte` | complex |
| JSX `className=` | `class=` | trivial |
| JSX `{condition && <El />}` | `{#if condition}<El />{/if}` | trivial |
| JSX `{list.map(item => <El />)}` | `{#each list as item}<El />{/each}` | trivial |
| `children` prop | `{#snippet children()}{/snippet}` | moderate |
| `React.FC<Props>` types | `interface Props {}` + `let { ... } = $props()` | moderate |

Search terms for Phase 1: `useState`, `useEffect`, `useMemo`, `useCallback`, `useRef`, `useContext`, `import React`, `.jsx`, `.tsx`

### Svelte stores → Runes (within Svelte 5 project)

| Before | After | Complexity |
|--------|-------|------------|
| `import { writable } from 'svelte/store'` | remove import | trivial |
| `const store = writable(init)` (local) | `let x = $state(init)` | trivial |
| `const store = writable(init)` (shared module) | `export class Store { value = $state(init) }` | moderate |
| `store.subscribe(cb)` | `$effect(() => { cb(value) })` | moderate |
| `store.set(val)` | `value = val` | trivial |
| `store.update(fn)` | `value = fn(value)` | trivial |
| `$store` in template | `store.value` (if class) or direct ref | trivial |
| `derived(a, fn)` | `$derived(fn(a))` | trivial |
| `readable(init, set)` | `$state` + `$effect` for setup/teardown | moderate |
| `get(store)` | direct property read | trivial |

Search terms for Phase 1: `from 'svelte/store'`, `writable(`, `readable(`, `derived(`, `get(`, `$store`

---

## Error Handling

| Phase | Failure | Fallback |
|-------|---------|----------|
| Phase 1 (Inventory) | Grep/Glob error | Report error, continue with partial inventory |
| Phase 2 (Compatibility) | WebSearch unavailable | Use built-in knowledge only, note limitation |
| Phase 2 (Compatibility) | No official migration guide found | Document what was found, flag as needs-manual-research |
| Phase 3 (Plan) | Circular phase dependency | Flatten into single complex phase, flag for manual review |
| Phase 4 (Execution) | Type check fails after phase | Rollback with `git checkout`, mark FAILED, continue or stop |
| Phase 4 (Execution) | Tests fail after phase | Rollback with `git checkout`, report failures, ask user |
| Phase 4 (Execution) | No git repo | Skip commit step, warn that rollback is not available |
| Phase 5 (Validation) | Residual FROM patterns found | List them in report as "incomplete — manual work required" |
| Any phase | Unknown FROM/TO pair | Proceed with generic search + WebSearch for patterns |
