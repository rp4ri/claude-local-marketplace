---
name: audit
description: >
  Unified codebase audit — runs 4 workers in sequence (query-efficiency,
  dead-code, runtime-perf, security-smells) and outputs a single prioritized
  report. Adapted for SvelteKit + Drizzle + TypeScript + Tauri stack.
---

# Dev Audit — Unified Codebase Audit

Single-command audit pipeline that finds actionable issues across 4 dimensions:
query efficiency, dead code, runtime performance, and security smells.

## Table of Contents
- [Usage](#usage)
- [Arguments](#arguments)
- [Execution Flow](#execution-flow)
- [Worker 1: Query Efficiency](#worker-1-query-efficiency)
- [Worker 2: Dead Code](#worker-2-dead-code)
- [Worker 3: Runtime Performance](#worker-3-runtime-performance)
- [Worker 4: Security Smells](#worker-4-security-smells)
- [Layer 2 Verification](#layer-2-verification)
- [Output Format](#output-format)
- [Worker 0: Sentrux Structural Health](#worker-0-sentrux-structural-health)
- [Codegraph Integration](#codegraph-integration)
- [Error Handling](#error-handling)

---

## Usage

```
/dev-audit                   # Audit src/ (default)
/dev-audit src/lib/          # Audit specific directory
/dev-audit --staged          # Audit only git-staged files
/dev-audit --fix             # Audit + auto-fix LOW/MEDIUM findings
/dev-audit --quick           # Skip Layer 2 verification (faster, more noise)
/dev-audit src/ --fix        # Scoped audit with auto-fix
```

---

## Arguments

| Argument | Default | Description |
|----------|---------|-------------|
| `path`   | `src/`  | Directory or file to audit |
| `--staged` | off   | Resolve target from `git diff --cached --name-only` |
| `--fix`  | off     | Auto-fix LOW and MEDIUM findings; commit per worker |
| `--quick` | off   | Skip Layer 2 verification (skip false-positive checks) |

---

## Execution Flow

```
Resolve target
     |
     v
Worker 0: Sentrux Health    -->  quality_signal, coupling, cycles
     |
     v
Worker 1: Query Efficiency  -->  findings[]
     |
     v
Worker 2: Dead Code         -->  findings[]
     |
     v
Worker 3: Runtime Perf      -->  findings[]
     |
     v
Worker 4: Security Smells   -->  findings[]
     |
     v
Layer 2 Verification (unless --quick)
     |
     v
Merge + deduplicate findings
     |
     v
Write .dev-studio/audit-report.md
     |
     v
If --fix: apply LOW/MEDIUM fixes, git commit per worker
```

Run workers sequentially. Do not parallelize workers — each worker reads
findings state so order is deterministic and context windows stay bounded.

---

## Pre-flight: Resolve Target

**If `--staged`:**
```bash
git diff --cached --name-only
```
Filter to `.ts`, `.svelte`, `.js` files only.

**If path argument:** Use as-is.

**Default:** `src/`

---

## Worker 0: Sentrux Structural Health

**Prerequisite:** `sentrux` must be in PATH. If not found, skip this worker and note in report.

Run sentrux to get the architectural health baseline before code-level analysis:

```bash
sentrux check . --format json 2>/dev/null
```

If the command succeeds, parse the JSON output and extract:

| Metric | What it means | Action threshold |
|--------|--------------|-----------------|
| `quality_signal` | 0–10000 composite score | < 5000 = flag as CRITICAL structural issue |
| `modularity` | How well code is decomposed | < 0.4 = monolithic, recommend splitting |
| `acyclicity` | Absence of dependency cycles | < 0.8 = cycles present, list them |
| `depth` | Module hierarchy depth | > 8 = too deep, flatten |
| `equality` | Even distribution of size | < 0.3 = god files present |

If sentrux finds **rule violations** (from `.sentrux/rules.toml`), include them as findings:
- Layer violations → Severity: HIGH
- Dependency cycles → Severity: HIGH
- God files (> threshold) → Severity: MEDIUM

**Also run gate comparison if baseline exists:**

```bash
sentrux gate . 2>/dev/null
```

If a `.sentrux/baseline.json` exists, this reports **regressions** since the last gate save.
Include any regression (quality_signal decrease > 100 points) as a MEDIUM finding.

If sentrux is not installed or fails, silently skip and proceed to Worker 1.

**Output:** Add a "Structural Health" section at the top of the audit report with the metrics table and any violations.

---

## Worker 1: Query Efficiency

**Scope:** Files matching `**/*.ts`, `**/*.svelte`, `**/+page.server.ts`,
`**/+server.ts`, `**/+layout.server.ts` within target path.

**Context:** Drizzle ORM patterns. Drizzle uses `db.query.*`, `db.select()`,
`db.insert()`, `db.update()`, `db.delete()`. Relations are declared via
`relations()` in schema files and queried via `with: { relation: true }`.

### Check W1-1: N+1 in Loops

Pattern: `db.query.*findMany` or `db.select()` inside `for`, `.map(`, `.forEach(`

```bash
grep -rn "db\.query\.\|db\.select(" <target> --include="*.ts" --include="*.svelte"
```

For each hit, check if the call is lexically inside a loop construct
(`for (`, `for await (`, `.map(`, `.forEach(`, `.filter(`, `.reduce(`).

**Severity:**
- CRITICAL if in `+page.server.ts`, `+server.ts`, `+layout.server.ts`
- HIGH elsewhere

**Suggested fix:** Extract the inner query, collect IDs, use a single
`db.query.*.findMany({ where: inArray(table.id, ids) })` outside the loop.

---

### Check W1-2: Sequential Independent Queries

Pattern: Two or more consecutive `await db.` statements where neither result
is passed to the next call.

Look for blocks like:
```ts
const a = await db.select()...
const b = await db.select()...   // b doesn't depend on a
```

**Severity:** MEDIUM

**Suggested fix:** Wrap in `Promise.all([query1, query2])`.

---

### Check W1-3: Missing `with` Relations

Pattern: `db.query.*.findMany()` (or `findFirst()`) followed within 10 lines
by another `db.query.*` or `db.select()` that fetches a related table.

```bash
grep -n "findMany\|findFirst" <file>
```

For each hit, scan the next 10 lines for another db call targeting a table
that is likely related (shares a naming root or a foreign key reference).

**Severity:** HIGH

**Suggested fix:** Collapse into a single query using Drizzle's
`with: { relationName: true }` option. Check the schema relations() definition.

---

### Check W1-4: Over-fetching in List Endpoints

Pattern: `db.select()` without `.columns(` or `db.query.*.findMany()` without
`columns:` restriction, called from a load function that returns a list.

Heuristic: file is in `src/routes/`, function is `load` or `GET`, and the
return value includes a list (`return { items }` / `return { rows }`).

**Severity:** LOW (only flag tables that have >8 columns; check schema file
for column count)

**Suggested fix:** Add `.columns({ id: true, name: true, ... })` to select
only the fields used by the component.

---

### Check W1-5: Missing Bulk Insert

Pattern: `db.insert(table).values(singleItem)` inside a loop.

```bash
grep -n "db\.insert" <file>
```

For each hit, check if it is inside a loop construct.

**Severity:** MEDIUM

**Suggested fix:** Collect items into an array, call `db.insert(table).values(itemArray)` once outside the loop.

---

### Check W1-6: Unindexed Filter

Pattern: `.where(eq(table.field, value))` or `.where(like(table.field, ...))`.

For each field used in `.where()`, check the corresponding schema file for
`index()` or `uniqueIndex()` declarations on that field.

```bash
grep -n "\.where(" <target> --include="*.ts" -r
grep -n "index(" <target>/db/schema* --include="*.ts" -r
```

**Severity:** MEDIUM if field has no index in schema.

**Suggested fix:** Add `index('idx_name').on(table.field)` to the schema.

---

## Worker 2: Dead Code

**Scope:** `src/` (always full project for dead code — path scoping misses
cross-file references).

### Check W2-1: Unused Exports

Find exported symbols not imported anywhere:

```bash
grep -rn "^export " src/ --include="*.ts" --include="*.svelte"
```

For each exported name, verify it is imported somewhere:
```bash
grep -rn "{ ExportName }" src/ --include="*.ts" --include="*.svelte"
grep -rn "import.*ExportName" src/ --include="*.ts" --include="*.svelte"
```

**Severity:** MEDIUM

Skip: `+page.ts`, `+page.server.ts`, `+layout.ts`, `+layout.server.ts`,
`+server.ts` — SvelteKit exports (`load`, `GET`, `POST`, etc.) are consumed
by the framework, not imported.

---

### Check W2-2: Dead Routes

Find routes in `src/routes/` that have no navigation pointing to them.

```bash
find src/routes -name "+page.svelte" | sed 's|src/routes||;s|/+page.svelte||'
```

For each route path, check if it appears in any `href`, `goto(`, `redirect(`,
or `<a` tag across the project.

**Severity:** LOW

Note: Skip routes with `[param]` segments — they may be reached dynamically.

---

### Check W2-3: Commented-out Code Blocks

Pattern: contiguous comment blocks >5 lines that contain code syntax:
`{`, `}`, `;`, `function`, `const`, `=>`, `return`.

```bash
grep -n "^[[:space:]]*//" src/ -r --include="*.ts" --include="*.svelte"
```

Group consecutive hits by line proximity (<3 lines apart). Flag groups >5
lines that match code syntax heuristic.

**Severity:** LOW

---

### Check W2-4: Unused Dependencies

For each package in `package.json` `dependencies` (not `devDependencies`):
```bash
grep -r "from ['\"]<pkg>" src/ --include="*.ts" --include="*.svelte" -l
grep -r "require(['\"]<pkg>)" src/ --include="*.ts" -l
```

**Severity:** LOW

Skip: framework packages that inject at runtime (`@sveltejs/kit`, `svelte`,
`vite`, `tailwindcss`, `drizzle-kit`, `typescript`).

---

## Worker 3: Runtime Performance

**Scope:** Server-side files: `+page.server.ts`, `+server.ts`,
`+layout.server.ts`, `hooks.server.ts`, `src/lib/server/**`.

### Check W3-1: Blocking Sync Calls in Async Context

Patterns:
- `fs.readFileSync(`
- `fs.writeFileSync(`
- `execSync(`
- `spawnSync(`
- `crypto.pbkdf2Sync(` / `crypto.scryptSync(`

```bash
grep -rn "readFileSync\|writeFileSync\|execSync\|spawnSync\|pbkdf2Sync\|scryptSync" \
  src/ --include="*.server.ts" --include="hooks.server.ts"
```

**Severity:** HIGH

**Suggested fix:** Replace with async equivalents: `fs.promises.readFile`,
`util.promisify(exec)`, `crypto.pbkdf2` (promisified).

---

### Check W3-2: Missing Promise.all for Independent Awaits

Pattern: two or more sequential `await` calls where the second does not
reference the result of the first.

Scan load functions and route handlers. Look for:
```ts
const x = await fetchA()
const y = await fetchB()   // y doesn't depend on x
```

**Severity:** MEDIUM

**Suggested fix:** `const [x, y] = await Promise.all([fetchA(), fetchB()])`.

---

### Check W3-3: Unbatched SSE / WebSocket Sends

Pattern: `controller.enqueue(` or `ws.send(` inside a `for` or `while` loop
without a batch accumulator.

```bash
grep -rn "controller\.enqueue\|\.send(" src/ --include="*.ts" -n
```

For each hit, check if it is inside a loop.

**Severity:** MEDIUM

**Suggested fix:** Accumulate items in an array, send as a single JSON array,
or use a flush interval.

---

### Check W3-4: Large Object Serialization in Load Functions

Pattern: `load` functions that return objects with >50 top-level keys, or
arrays of objects where each item has >20 keys, without any field filtering.

Heuristic: look for `return {` in load functions where the returned value
contains a spread of a large query result (`...rows`, `data: rows`).

**Severity:** LOW

**Suggested fix:** Select only the columns the component uses, or add a
mapping step before return.

---

### Check W3-5: Missing SvelteKit Streaming for Large Fetches

Pattern: `load` function with a single large `await` (fetching a list >100
items, or a slow external API call) that blocks the entire page render.

Heuristic: `await fetch(`, `await db.query.*.findMany(` in `load` without
a `deferred` / `{ promise }` streaming return pattern.

**Severity:** LOW

**Suggested fix:** Return `{ streamed: { items: fetchItems() } }` (no await)
and use `{#await data.streamed.items}` in the component.

---

## Worker 4: Security Smells

**Scope:** Entire project (`src/`, config files, `.env*` if readable).

### Check W4-1: Hardcoded Secrets

Patterns (regex, case-insensitive):
```
(api[_-]?key|apikey|secret|password|passwd|token|auth[_-]?token|bearer|private[_-]?key|access[_-]?key|connection[_-]?string)\s*[:=]\s*['"][A-Za-z0-9+/=_\-]{8,}['"]
```

Also flag: hardcoded `postgres://`, `mysql://`, `mongodb://` connection strings
with credentials embedded.

```bash
grep -rniE "(api_key|apikey|secret|password|token)\s*[:=]\s*['\"][A-Za-z0-9]{8,}['\"]" \
  src/ --include="*.ts" --include="*.svelte" --include="*.js"
```

**Severity:** CRITICAL

Exclude: `$env/` imports, `process.env.`, `import.meta.env.` — these are safe.

---

### Check W4-2: Missing Auth Check in Server Endpoints

For each file matching `+server.ts` or `+page.server.ts`:
- Check if it exports `GET`, `POST`, `PUT`, `DELETE`, `PATCH`, or `load`
- Check if the function body references `requireAuth`, `getSession`,
  `locals.user`, `locals.session`, `auth.api`, or any auth middleware call

```bash
grep -rln "export.*GET\|export.*POST\|export.*load" src/routes/ --include="*.ts"
```

For each file found, check for auth patterns:
```bash
grep -n "requireAuth\|getSession\|locals\.user\|locals\.session\|auth\.api" <file>
```

**Severity:** HIGH if no auth reference found.

Skip: files in `src/routes/(auth)/`, `src/routes/login`, `src/routes/register`
— public endpoints by convention.

---

### Check W4-3: SQL Injection via Raw Template Literals

Pattern: `sql\`` (Drizzle raw SQL) or `db.execute(sql\``) with interpolated
variables (`${variable}` inside the template literal).

```bash
grep -rn "sql\`" src/ --include="*.ts" --include="*.svelte"
```

For each hit, check if the template literal contains `${` interpolation that
is not a Drizzle `sql` helper call (i.e., raw string concatenation).

**Severity:** CRITICAL

Safe pattern: `sql\`SELECT * FROM ${table}\`` using Drizzle's table references
is safe. Flag only string variable interpolation: `sql\`WHERE name = '${userInput}'\``.

---

### Check W4-4: XSS via Unguarded `{@html}`

Pattern: `{@html ` in `.svelte` files where the variable has not been
sanitized.

```bash
grep -rn "{@html " src/ --include="*.svelte"
```

For each hit, check the preceding 20 lines for `sanitize(`, `DOMPurify.`,
`marked(` with sanitizer option, or similar sanitization calls.

**Severity:** HIGH if no sanitization found within scope.

**Suggested fix:** Wrap with `DOMPurify.sanitize()` or use a trusted sanitizer.
If the content is fully server-controlled, document why it is safe.

---

### Check W4-5: Private Env in Client Components

Pattern: `import.*from.*\$env/(static|dynamic)/private` in client-side files.

```bash
grep -rn "from.*\\\$env.*/private" src/ --include="*.svelte" --include="*.ts"
```

Flag if the importing file is:
- `+page.svelte`, `+layout.svelte` (no `.server`)
- Any file under `src/lib/` that is NOT in `src/lib/server/`

**Severity:** CRITICAL

**Suggested fix:** Move the logic using the private env to a `.server.ts` file
and expose only what the client needs via a server load function.

---

## Layer 2 Verification

**Skip entirely if `--quick` is passed.**

Before finalizing each finding, run one verification step to reduce false
positives:

### V1: N+1 Confirmation
Confirm the query call is inside a loop at runtime, not just lexically. Check
if the enclosing function is called from a loop at its call sites:
```bash
grep -rn "<functionName>(" src/ --include="*.ts" --include="*.svelte"
```
Drop the finding if the function is called only once.

### V2: Dead Export Confirmation
Confirm the export is not used dynamically:
```bash
grep -rn "import(" src/ --include="*.ts"          # dynamic import
grep -rn "require(" src/ --include="*.ts"           # CJS dynamic
grep -rn "['\"]ExportName['\"]" src/ --include="*.ts"  # string reference
```
Drop the finding if any dynamic reference exists.

### V3: Security Reachability
Confirm the flagged code path is reachable from a public endpoint. If the
file is only imported by other server-internal modules with no route entry
point, downgrade severity by one level (CRITICAL→HIGH, HIGH→MEDIUM).

---

## Codegraph Integration

At the start of the audit, check if `codegraph_search` is available as an MCP tool.

**If codegraph is available, PREFER it over grep for these checks:**

| Check | Without codegraph | With codegraph |
|-------|------------------|----------------|
| W1-1 N+1 verification | Grep for loop context | `codegraph_callers(fn)` — trace full call chain to confirm loop |
| W2-1 Unused exports | `grep -rn "import.*Name"` | `codegraph_references(symbol)` — precise, no false negatives |
| W3-1 Blocking in async | Grep for `readFileSync` | `codegraph_callers(fn)` — confirm it's in a hot path from a route |
| V3 Reachability | Manual trace | `codegraph_callers(fn, depth=5)` — automated route reachability |
| Auto-fix blast radius | Skip | `codegraph_impact(symbol)` — list all affected files before editing |

**If codegraph is NOT indexed for this project**, emit a warning at the top of the report:
```
⚠ Codegraph not indexed. Run `codegraph analyze` in this project for deeper analysis.
   Falling back to grep-based verification (higher false positive rate).
```

Then fall back to the grep-based patterns described in each worker. Do not error.

---

## Output Format

### Console summary (during execution)

After each worker completes, print a one-line status:
```
Worker 1 (query-efficiency): 3 CRITICAL, 1 HIGH, 2 MEDIUM, 0 LOW
Worker 2 (dead-code): 0 CRITICAL, 0 HIGH, 4 MEDIUM, 6 LOW
Worker 3 (runtime-perf): 0 CRITICAL, 2 HIGH, 1 MEDIUM, 2 LOW
Worker 4 (security-smells): 2 CRITICAL, 3 HIGH, 0 MEDIUM, 0 LOW
```

### Report file: `.dev-studio/audit-report.md`

```markdown
# Audit Report — <date> <time>

**Target:** <path>  **Mode:** <normal|quick|staged>  **Fix:** <yes|no>

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | N |
| HIGH     | N |
| MEDIUM   | N |
| LOW      | N |
| **Total**| N |

## Findings

### CRITICAL

| # | File:Line | Check | Description | Suggested Fix |
|---|-----------|-------|-------------|---------------|
| 1 | src/routes/+page.server.ts:42 | W1-1 N+1 in loop | db.query.users.findMany inside .map() | Extract IDs, use inArray() |
| 2 | src/lib/config.ts:7 | W4-1 Hardcoded secret | API_KEY = "sk-..." | Move to $env/static/private |

### HIGH
...

### MEDIUM
...

### LOW
...

## Auto-fix Log
<!-- Only present if --fix was passed -->
- Worker 1: fixed 2 of 2 MEDIUM findings (git commit: abc1234)
- Worker 3: fixed 1 of 1 MEDIUM findings (git commit: def5678)
- Worker 4: no auto-fixable findings (CRITICAL findings require manual review)
```

---

## Auto-fix Rules (--fix mode)

Apply fixes only for LOW and MEDIUM severity findings. Never auto-fix CRITICAL
or HIGH — these require human review.

**Fixable automatically:**
- W1-2 Sequential queries → wrap in `Promise.all`
- W1-4 Over-fetching → add `.columns()` with fields visible in component
- W1-5 Bulk insert → refactor loop to array accumulator + single insert
- W2-3 Commented-out blocks → delete the comment block
- W3-2 Sequential awaits → wrap in `Promise.all`

**Not auto-fixable (flag only):**
- W1-1 N+1 (requires understanding query shape and relations)
- W1-3 Missing `with` (requires schema knowledge)
- W1-6 Unindexed filter (schema migration required)
- W2-1 Unused exports (may break public API surface)
- W2-2 Dead routes (may be intentionally unlisted)
- W4-* All security findings (require human judgment)

After each worker's fixes, create a commit:
```bash
git add -p   # stage only changed files
git commit -m "fix(audit): <worker-name> auto-fix — <N> findings resolved"
```

---

## Error Handling

- If `src/` does not exist and no path was given: abort with
  `"No src/ directory found. Run from project root or pass an explicit path."`
- If `--staged` is passed but `git diff --cached --name-only` returns empty:
  print `"No staged files. Nothing to audit."` and exit cleanly.
- If a worker produces 0 findings: print `"Worker N: clean"` and continue.
- If a grep command fails (e.g., no matches): treat as 0 findings, not an error.
- If `.dev-studio/` does not exist: create it before writing the report.
- If `--fix` is passed but the working tree is dirty (uncommitted changes):
  warn and continue in read-only mode:
  `"Warning: working tree is dirty. --fix skipped to avoid mixing changes."`
