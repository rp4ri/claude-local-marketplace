---
name: perf
description: >
  Runtime performance analysis for SvelteKit apps. Finds blocking I/O,
  sequential awaits, load waterfalls, memory leaks, and bundle bloat.
  Use when user wants to speed up page load, reduce server latency, fix
  reactive overkill in Svelte 5, or shrink client bundle size.
---

# Dev Perf — Runtime Performance Analysis

Analyze a SvelteKit project for runtime performance issues. Run analysis
sequentially: gather context first, then scan each layer, then write the report.

## Table of Contents
- [Usage](#usage)
- [Arguments](#arguments)
- [Step 1: Resolve Target](#step-1-resolve-target)
- [Step 2: Load Function Waterfalls](#step-2-load-function-waterfalls---routes)
- [Step 3: Server Performance](#step-3-server-performance---server)
- [Step 4: Client Performance](#step-4-client-performance---client)
- [Step 5: Bundle Analysis](#step-5-bundle-analysis---bundle)
- [Step 6: Write Report](#step-6-write-report)
- [Priority Levels](#priority-levels)
- [Error Handling](#error-handling)

## Usage

```
/dev-perf                        # Default: --routes + --server
/dev-perf src/routes/dashboard/  # Analyze specific path
/dev-perf --routes               # All SvelteKit load function waterfalls
/dev-perf --server               # Server-side code only
/dev-perf --client               # Client-side code only
/dev-perf --bundle               # Bundle size and tree-shaking
/dev-perf --routes --client      # Combine flags
```

## Arguments

The raw arguments are: $ARGUMENTS

Parse them:
- If a plain path is given (no `--` prefix): scope all analysis to that path.
- `--routes`: analyze load function waterfalls in `+page.server.ts` / `+page.ts`.
- `--server`: analyze server-side code (`+server.ts`, `hooks.server.ts`, `lib/server/`).
- `--client`: analyze client-side code (`+page.svelte`, `+layout.svelte`, `lib/components/`).
- `--bundle`: analyze `package.json` imports, dynamic import usage, code splitting.
- No args or unrecognized args: default to `--routes --server`.

## Step 1: Resolve Target

1. Read `package.json` to confirm this is a SvelteKit project and note key dependencies.
2. Check `svelte.config.js` for adapter and any custom aliases.
3. If a path argument was given, verify it exists. If not found, abort with a clear message.
4. Build the file list for each active flag:
   - `--routes`: `glob('src/routes/**/{+page.server.ts,+page.ts}')`
   - `--server`: `glob('src/**/{+server.ts,hooks.server.ts}')` + `glob('src/lib/server/**/*.ts')`
   - `--client`: `glob('src/routes/**/{+page.svelte,+layout.svelte}')` + `glob('src/lib/components/**/*.svelte')`
   - `--bundle`: only needs `package.json` + `glob('src/**/*.{ts,svelte}')` for import scanning

If the file list for a flag is empty, skip that step and note it in the report.

## Step 2: Load Function Waterfalls (`--routes`)

For each `+page.server.ts` and `+page.ts` in scope:

### 2a. Sequential await detection

Read the file. For each `load()` function, extract all top-level `await` expressions.
Flag as **P0** when:
- Two or more `await` calls are on independent resources (no data dependency between them).
- Fix: wrap in `Promise.all([...])` or `Promise.allSettled([...])`.

Example pattern to flag:
```ts
// BAD — sequential, adds latency of both round-trips
const user = await fetchUser(id);
const posts = await fetchPosts(id);

// GOOD — parallel
const [user, posts] = await Promise.all([fetchUser(id), fetchPosts(id)]);
```

### 2b. Parent→child waterfall

Check if a parent `+page.server.ts` fetches data that a child `+page.server.ts` in the
same route segment also fetches independently. Flag as **P1**.

### 2c. Missing `depends()`

If a load function fetches from a URL or key but never calls `depends('key')`,
flag as **P2**. Missing `depends` causes SvelteKit to not invalidate the cache
when you call `invalidate('key')`, leading to stale data or unnecessary full reloads.

### 2d. Streaming opportunity

Flag as **P2** when a load function awaits a slow external fetch that is not
needed to render above-the-fold content. Suggest streaming pattern:

```ts
// Stream the slow part — SvelteKit will render the page before it resolves
return {
  critical: await fastFetch(),
  slow: slowFetch(),          // no await — returns a Promise, not data
};
```

## Step 3: Server Performance (`--server`)

Scan each server file in scope for the following patterns.

### 3a. Blocking sync calls in async context (P0)

Grep for: `readFileSync`, `writeFileSync`, `execSync`, `spawnSync`,
`crypto.randomBytes` (without callback), `Atomics.wait`.

These block the Node.js event loop for the entire duration, stalling all
concurrent requests on that server process.

### 3b. Per-request DB connection (P0)

Look for DB client initialization inside a `load()`, `POST()`, `GET()`, or
`RequestHandler`. A new connection per request wastes 20–100ms each.
Fix: initialize the client at module scope or use a pool imported from `lib/server/db.ts`.

For Drizzle + Neon/PostgreSQL specifically:
- Missing `neon()` or `drizzle()` at module scope (re-created per request).
- Missing `.prepare()` on queries that run on every request (re-parses SQL each time).
- No connection pool limit set (`max` option) — can exhaust Neon's connection quota.

### 3c. Missing memoization / cache (P1)

Identify expensive computations (heavy regex, recursive traversals, external HTTP
calls) inside request handlers with no caching layer. Flag when:
- The same external URL is fetched on every request with no `Cache-Control` or in-memory cache.
- A heavy computation result never stored in a module-level `Map` or LRU cache.

### 3d. Event listener leaks in SSE/WebSocket (P1)

In `+server.ts` files using `ReadableStream` or `EventSource`: check that
`cancel()` / `close()` handlers remove all listeners added during the stream's
lifetime. Unlceared listeners accumulate with each client connection.

## Step 4: Client Performance (`--client`)

Scan each `.svelte` file in scope.

### 4a. `$effect` that should be `$derived` (P1)

Flag `$effect` blocks whose only purpose is to compute a value from reactive
state and assign it to another `$state` variable. `$derived` is cheaper —
it's lazy and doesn't schedule a microtask.

```svelte
// BAD
let doubled = $state(0);
$effect(() => { doubled = count * 2; });

// GOOD
let doubled = $derived(count * 2);
```

### 4b. Large objects as `$state` (P2)

Flag `$state({...})` where the object literal has more than 20 properties or
contains nested arrays/objects. These are deeply proxied by Svelte 5's reactivity
system. If the object is only ever replaced wholesale (API response), use:

```ts
let data = $state.raw(null);   // no deep proxy, cheaper for large payloads
```

### 4c. Missing `$effect` cleanup (P1)

Flag `$effect` blocks that call `addEventListener`, `setInterval`, or
`setTimeout` without a `return () => { ... }` cleanup function. Leaked listeners
accumulate on each component mount (especially in SSR + hydration scenarios).

### 4d. Over-subscribed reactive dependency (P2)

Flag patterns where a reactive expression or `$derived` depends on an entire
large object when only one field is accessed. Svelte 5 tracks field-level
access through the proxy, but object spread (`{ ...obj }`) forces full
dependency. Flag `$derived({ ...largeObj })` patterns.

### 4e. Heavy static imports (P1)

Grep for direct default imports of known large packages at the top of `.svelte`
files: `lodash`, `moment`, `rxjs`, `xlsx`, `pdfmake`, `chart.js` (non-ESM build),
`@fullcalendar/*`. These inflate the initial bundle if the component is on a
critical path. Suggest dynamic import:

```ts
const { default: Chart } = await import('chart.js/auto');
```

## Step 5: Bundle Analysis (`--bundle`)

### 5a. Estimate dependency sizes (P1)

Read `package.json` `dependencies` + `devDependencies`. For each package check
if it is a known heavy dependency. Known large packages and rough minified sizes:
- `moment` ~300KB → suggest `date-fns` (tree-shakeable)
- `lodash` ~70KB → suggest `lodash-es` or per-method imports
- `rxjs` ~200KB full → suggest specific operator imports
- `@aws-sdk/client-*` ~400KB+ → already modular, ensure only used client imported
- `xlsx` ~800KB → no tree-shaking; consider `exceljs` with dynamic import
- `chart.js` (non-auto) ~200KB → use specific chart registration
- `@sentry/browser` ~100KB → check `tracesSampleRate` is not 1.0 in prod

### 5b. Missing dynamic imports (P1)

Find components imported statically in `+layout.svelte` or `+page.svelte` that
are clearly below-fold or interaction-gated (modals, drawers, heavy charts,
rich text editors). Suggest:

```ts
const HeavyChart = await import('$lib/components/HeavyChart.svelte');
```

SvelteKit will automatically code-split at route boundaries; intra-route
components need manual `import()`.

### 5c. Duplicate date/utility libraries (P2)

Detect multiple packages providing equivalent functionality:
- Date: `moment` + `date-fns` + `dayjs` — keep one
- HTTP: `axios` + `node-fetch` + native `fetch` polyfill — consolidate
- Validation: `zod` + `yup` + `joi` — keep one (prefer `zod` for SvelteKit + Superforms)

### 5d. Missing route-level code splitting (P2)

If multiple routes import the same large shared lib statically, verify that
`vite.config.ts` has `build.rollupOptions.output.manualChunks` configured or
that Vite is left to auto-split. Flag explicit `noSplit` or `inlineDynamicImports`
settings that defeat code splitting.

## Step 6: Write Report

Write `.dev-studio/perf-report.md`. Create `.dev-studio/` if it does not exist.

Structure the report as follows:

```markdown
# Performance Report — <date>

## Summary

| Priority | Count | Description |
|----------|-------|-------------|
| P0 | N | Blocking — fix before next deploy |
| P1 | N | Should fix — measurable impact |
| P2 | N | Nice to have — small gains |

## Findings

### [P0-001] <Short title> — <file>:<line>
**What**: <one sentence>
**Impact**: ~<Xms saved> or ~<XKB reduced>
**Fix**:
\`\`\`ts
// before / after snippet
\`\`\`

### [P1-001] ...

## Skipped
- `--bundle`: no package.json found (not a Node project)
```

After writing, print the summary table to the chat so the user sees results
immediately without opening the file.

## Priority Levels

| Level | Meaning | Examples |
|-------|---------|---------|
| P0 | Blocks event loop or adds >100ms to every request | Sync I/O in handlers, per-request DB init |
| P1 | Measurable latency or bundle regression | Sequential awaits, missing cleanup, heavy static imports |
| P2 | Minor / cumulative | Missing `depends()`, `$state.raw`, duplicate packages |

## Codegraph + Sentrux Integration

**Codegraph** — if `codegraph_callers` is available as MCP tool, use it to determine
whether a flagged slow function is in a hot path:
- Hot path: called from a route load function → P0 or P1 (user-facing)
- Cold path: called only from scripts, migrations, or cron jobs → downgrade one level
- Query codegraph for P0 candidates only to keep analysis time bounded
- If not available, emit: "⚠ Codegraph not indexed. Run `codegraph analyze` for hot-path detection."

**Sentrux** — if `sentrux` is in PATH, run at the end of the analysis:
```bash
sentrux check . --format json 2>/dev/null
```
Extract `equality` metric. If < 0.3, add a P1 finding: "God files detected — large files
concentrate complexity and are harder to optimize. Consider decomposing." List the files
with highest fan-in from sentrux output.

## Error Handling

- File not readable: note in report under "Skipped", continue scan.
- No SvelteKit routes found: skip `--routes` with a note; still run `--server` / `--client` if requested.
- `package.json` missing: skip `--bundle` entirely.
- Partial results are better than no results — always write what was found.
