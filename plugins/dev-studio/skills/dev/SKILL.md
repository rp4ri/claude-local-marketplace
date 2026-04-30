---
name: dev
description: >
  Development utilities — adversarial bug hunting with multi-agent pipeline
  (Recon, Hunter, Skeptic, Referee, Fixer). Finds, verifies, and auto-fixes
  real bugs. Use when user wants bug finding, security audits, PR reviews,
  dependency scanning, or code review focused on runtime behavior.
---

# Bug Hunt - Adversarial Bug Finding

Run a sequential-first adversarial bug hunt on your codebase. Use parallelism only for read-only triage and independent verification tasks.

## Table of Contents
- [Usage](#usage)
- [Target](#target)
- [Context Budget](#context-budget)
- [Execution Steps](#execution-steps)
- [Step 7: Present the Final Report](#step-7-present-the-final-report)
- [Self-Test Mode](#self-test-mode)
- [Error handling](#error-handling)

**Phase 1 — Find & Verify:**
```
Recon (map) --> Hunter (deep scan) --> Skeptic (challenge) --> Referee (final verdict)
                    ^                 (optional read-only dual-lens triage can run here)
                    |
             state + chunk checkpoints
```

**Phase 2 — Fix & Verify (default when bugs are confirmed):**
```
Baseline --> Git branch --> sequential Fixer (single writer) --> targeted verify --> full verify --> report
                    ^                                                              |
                    +------------------------ checkpoint commits + auto-revert -----+
```

For small scans (1-10 source files): runs single Hunter + single Skeptic (no parallelism overhead).
For large scans: process chunks sequentially with persistent state to avoid compaction drift.

## Usage

```
/bug-hunt                              # Scan entire project
/bug-hunt src/                         # Scan specific directory
/bug-hunt lib/auth.ts                  # Scan specific file
/bug-hunt -b feature-xyz              # Scan files changed in feature-xyz vs main
/bug-hunt -b feature-xyz --base dev   # Scan files changed in feature-xyz vs dev
/bug-hunt --pr                        # Easy alias for --pr current
/bug-hunt --pr current                # Review the current PR end to end
/bug-hunt --pr recent --scan-only     # Review the most recent PR without editing code
/bug-hunt --pr 123                    # Review a specific PR number
/bug-hunt --pr-security               # PR security review: PR scope + threat model + dependency scan
/bug-hunt --last-pr --review          # Easy mnemonic for “review the last PR”
/bug-hunt --review-pr                 # Alias for --pr current
/bug-hunt --staged                    # Scan staged files (pre-commit check)
/bug-hunt --scan-only src/            # Scan only, no code changes
/bug-hunt --review src/               # Easy alias for --scan-only
/bug-hunt --fix src/                   # Find bugs AND auto-fix them
/bug-hunt --plan-only src/             # Build fix strategy + plan, but do not edit files
/bug-hunt --plan src/                  # Easy alias for --plan-only
/bug-hunt --safe src/                  # Easy alias for --fix --approve
/bug-hunt --preview src/               # Easy alias for --fix --dry-run
/bug-hunt --autonomous src/            # Alias for no-intervention auto-fix run
/bug-hunt --fix -b feature-xyz        # Find + fix on branch diff
/bug-hunt --fix --approve src/        # Find + fix, but ask before each fix
/bug-hunt src/                         # Loops by default: audit + fix until all queued source files are covered
/bug-hunt --no-loop src/               # Single-pass only, no iterating
/bug-hunt --no-loop --scan-only src/   # Single-pass scan, no fixes, no loop
/bug-hunt --deps src/                 # Include dependency CVE scan
/bug-hunt --threat-model src/         # Generate/use STRIDE threat model
/bug-hunt --security-review src/      # Enterprise security workflow: threat model + CVEs + validation
/bug-hunt --validate-security src/    # Force vulnerability-validation for security findings
/bug-hunt --deps --threat-model src/  # Full security audit
/bug-hunt --fix --dry-run src/        # Preview fixes without editing files
```

## Target

The raw arguments are: $ARGUMENTS

**Parse the arguments as follows:**

0. Default `LOOP_MODE=true`. If arguments contain `--no-loop`: strip it from the arguments and set `LOOP_MODE=false`. The `--loop` flag is accepted for backwards compatibility but is a no-op (loop is already the default).

0b. Default `FIX_MODE=true`.
0c. If arguments contain `--scan-only`: strip it from the arguments and set `FIX_MODE=false`.
0d. If arguments contain `--fix`: strip it from the arguments and set `FIX_MODE=true`. The remaining arguments are parsed normally below.
0e. If arguments contain `--autonomous`: strip it from the arguments, set `AUTONOMOUS_MODE=true`, and force `FIX_MODE=true` (canary-first + confidence-gated).
0f. If arguments contain `--approve`: strip it from the arguments and set `APPROVE_MODE=true`. When this flag is set, Fixer agents run in `mode: "default"` (user reviews and approves each edit). When not set, `APPROVE_MODE=false` and Fixers run autonomously.
0g. If arguments contain `--deps`: strip it and set `DEP_SCAN=true`. Dependency scanning runs package manager audit tools and checks if vulnerable APIs are actually called in the codebase.
0h. If arguments contain `--threat-model`: strip it and set `THREAT_MODEL_MODE=true`. Generates a STRIDE threat model at `.bug-hunter/threat-model.md` if one doesn't exist, then feeds it to Recon + Hunter for targeted security analysis.
0i. If arguments contain `--dry-run`: strip it and set `DRY_RUN_MODE=true`. Forces `FIX_MODE=true`. In dry-run mode, Phase 2 builds the fix plan and the Fixer reads code and outputs planned changes as unified diff previews, but no file edits, git commits, or lock acquisition occur. Produces `fix-report.json` with `"dry_run": true`.
0j. If arguments contain `--preview`: strip it, set `DRY_RUN_MODE=true`, and force `FIX_MODE=true`. Treat it as a memorable alias for `--fix --dry-run`.
0k. If arguments contain `--plan-only`: strip it and set `PLAN_ONLY_MODE=true`. The pipeline still scans, verifies, and builds `fix-strategy.json` + `fix-plan.json`, but it stops before the Fixer edits code.
0l. If arguments contain `--plan`: strip it and set `PLAN_ONLY_MODE=true`. Treat it as a memorable alias for `--plan-only`.
0m. If arguments contain `--review-pr`: strip it and treat it as `--pr current`.
0n. If arguments contain `--pr` with no selector after it, treat it as `--pr current`.
0o. If arguments contain `--last-pr`: strip it and treat it as `--pr recent`.
0p. If arguments contain `--review`: strip it and set `FIX_MODE=false`. Treat it as a memorable alias for `--scan-only`.
0q. If arguments contain `--safe`: strip it, set `FIX_MODE=true`, and set `APPROVE_MODE=true`. Treat it as a memorable alias for `--fix --approve`.
0r. If arguments contain `--pr-security`: strip it, set `PR_SECURITY_MODE=true`, force `DEP_SCAN=true`, force `THREAT_MODEL_MODE=true`, force `FIX_MODE=false`, and if no explicit `--pr` selector was provided treat it as `--pr current`.
0s. If arguments contain `--security-review`: strip it, set `SECURITY_REVIEW_MODE=true`, force `DEP_SCAN=true`, force `THREAT_MODEL_MODE=true`, and force `FIX_MODE=false`.
0t. If arguments contain `--validate-security`: strip it and set `VALIDATE_SECURITY_MODE=true`.

1. If arguments contain `--pr <selector>`: this is **PR review mode**.
   - Valid selectors: `current`, `recent`, or a PR number like `123`.
   - If `--base <base-branch>` is present, pass it through for current-branch git fallback.
   - Run:
     ```bash
     node "${CLAUDE_PLUGIN_ROOT}/scripts/pr-scope.cjs" resolve "<selector>" --repo-root "$PWD" [--base <base-branch>]
     ```
   - If it fails, report the error to the user and stop.
   - Save the JSON result to `.bug-hunter/pr-scope.json` for later reporting.
   - Use `changedFiles` from the JSON output as the scan target (scan full file contents, not just the diff).

2. If arguments contain `--staged`: this is **staged file mode**.
   - Run `git diff --cached --name-only` using the Bash tool to get the list of staged files.
   - If the command fails, report the error to the user and stop.
   - If no files are staged, tell the user there are no staged changes to scan and stop.
   - The scan target is the list of staged files (scan their full contents, not just the diff).

3. If arguments contain `-b <branch>`: this is **branch diff mode**.
   - Extract the branch name after `-b`.
   - If `--base <base-branch>` is also present, use that as the base branch. Otherwise default to `main`.
   - Run `git diff --name-only <base>...<branch>` using the Bash tool to get the list of changed files.
   - If the command fails (e.g. branch not found), report the error to the user and stop.
   - If no files changed, tell the user there are no changes to scan and stop.
   - The scan target is the list of changed files (scan their full contents, not just the diff).

4. If arguments do NOT contain `--pr`, `-b`, or `--staged`: treat the entire argument string as a **path target** (file or directory). If empty, scan the current working directory.

**After resolving the file list (for modes 1, 2, and 3), filter out non-source files:**

Remove any files matching these patterns — they are not scannable source code:
- Docs/text: `*.md`, `*.txt`, `*.rst`, `*.adoc`
- Config: `*.json`, `*.yaml`, `*.yml`, `*.toml`, `*.ini`, `*.cfg`, `.env*`, `.gitignore`, `.editorconfig`, `.prettierrc*`, `.eslintrc*`, `tsconfig.json`, `jest.config.*`, `vitest.config.*`, `webpack.config.*`, `vite.config.*`, `next.config.*`, `tailwind.config.*`
- Lockfiles: `*.lock`, `*.sum`
- Minified/maps: `*.min.js`, `*.min.css`, `*.map`
- Assets: `*.svg`, `*.png`, `*.jpg`, `*.gif`, `*.ico`, `*.woff*`, `*.ttf`, `*.eot`
- Project meta: `LICENSE`, `CHANGELOG*`, `CONTRIBUTING*`, `CODE_OF_CONDUCT*`, `Makefile`, `Dockerfile`, `docker-compose*`, `Procfile`
- Vendor dirs: `node_modules/`, `vendor/`, `dist/`, `build/`, `.next/`, `__pycache__/`, `.venv/`

If after filtering there are zero source files left, tell the user: "No scannable source files found — only config/docs/assets were changed." and stop.

## Context Budget

**FILE_BUDGET is computed by the triage script (Step 1), not by Recon.** The triage script samples 30 files from the codebase, computes average line count, and derives:
```
avg_tokens_per_file = average_lines_per_file * 4
FILE_BUDGET = floor(150000 / avg_tokens_per_file)   # capped at 60, floored at 10
```

Triage also determines the strategy directly, so Step 3 just reads the triage output — no circular dependency.

Then determine partitioning:

| Total source files | Strategy | Hunters | Skeptics |
|--------------------|----------|---------|----------|
| 1 | Single-file mode | 1 general | 1 |
| 2-10 | Small mode | 1 general | 1 |
| 11 to FILE_BUDGET | Parallel mode (hybrid) | 1 deep Hunter (+ optional 2 read-only triage Hunters) | 1-2 by directory |
| FILE_BUDGET+1 to FILE_BUDGET*2 | Extended mode | Sequential chunked Hunters | 1-2 by directory |
| FILE_BUDGET*2+1 to FILE_BUDGET*3 | Scaled mode | Sequential chunked Hunters with resume state | 1-2 by directory |
| > FILE_BUDGET*3 | Large-codebase mode + Loop | Domain-scoped pipelines + boundary audits | Per-domain 1-2 |

If triage was not run (e.g., Recon was called directly without the orchestrator), use the default FILE_BUDGET of 40.

**File partitioning rules (Extended/Scaled modes):**
- **Service-aware partitioning (preferred)**: If Recon detected multiple service boundaries (monorepo), partition by service.
- **Risk-tier partitioning (fallback)**: process CRITICAL then HIGH then MEDIUM then LOW.
- Keep chunk size small (recommended 20-40 files) to avoid context compaction issues.
- Persist chunk progress in `.bug-hunter/state.json` so restarts do not re-scan done chunks.
- Test files (CONTEXT-ONLY) are included only when needed for intent.

If the triage output shows `needsLoop: true` and `LOOP_MODE=false` (user passed `--no-loop`), warn the user: "This codebase has [N] source files (FILE_BUDGET: [B]). Single-pass mode will only cover a subset. Loop mode is recommended for thorough coverage (remove `--no-loop` to enable). Large codebases use domain-scoped auditing — see `modes/large-codebase.md`."

## Execution Steps

### Step 0: Preflight checks

Before doing anything else, verify the environment:

1. **Resolve plugin directory**: Set `${CLAUDE_PLUGIN_ROOT} = ${CLAUDE_PLUGIN_ROOT}`. This is automatically resolved by the plugin system. Use this path for ALL Read tool calls and shell commands.

2. **Verify skill files exist**: Run `ls "${CLAUDE_PLUGIN_ROOT}/skills/dev/references/hunter.md"` via Bash. If this fails, stop and tell the user: "Bug Hunter skill files not found. Reinstall the skill and retry."

3. **Node.js available**: Run `node --version` via Bash. If it fails, stop and tell the user: "Node.js is required for doc verification. Please install Node.js to continue."

3b. **Create output directory**:
    ```bash
    mkdir -p .bug-hunter/payloads .bug-hunter/domains
    ```
    This directory stores all pipeline artifacts. Add `.bug-hunter/` to your project's `.gitignore`.

4. **Doc lookup availability**: Documentation verification uses Claude Code's native WebSearch and WebFetch tools, with Perplexity MCP as fallback. No external scripts or API keys needed. Set `DOC_LOOKUP_AVAILABLE=true`.

5. **Verify helper scripts exist**:
   ```bash
   ls "${CLAUDE_PLUGIN_ROOT}/scripts/run-bug-hunter.cjs" "${CLAUDE_PLUGIN_ROOT}/scripts/bug-hunter-state.cjs" "${CLAUDE_PLUGIN_ROOT}/scripts/fix-lock.cjs" "${CLAUDE_PLUGIN_ROOT}/scripts/triage.cjs" "${CLAUDE_PLUGIN_ROOT}/scripts/pr-scope.cjs"
   ```
   If any are missing, stop and tell the user the dev-studio plugin is corrupted.

6. **Execution mode**: This plugin always runs in `local-sequential` mode. Set `AGENT_BACKEND = "local-sequential"`. Read `${CLAUDE_PLUGIN_ROOT}/skills/dev/modes/local-sequential.md` for full instructions. You run all phases (Recon, Hunter, Skeptic, Referee) yourself, sequentially, within your own context window. Write phase outputs to `.bug-hunter/` files between phases.

### Step 1: Parse arguments, resolve target, and run triage

Follow the rules in the **Target** section above. If in PR review, branch diff, or staged mode, run the appropriate resolver command now, collect the file list, and apply the filter.

Report to the user:
- Mode (full project / directory / file / PR review / branch diff / staged)
- Number of source files to scan (after filtering)
- Number of files filtered out

**Then run triage (zero-token strategy decision):**

Run the triage script AFTER resolving the target. This is a pure Node.js filesystem scan — no tokens consumed, runs in <2 seconds even on 2,000+ file repos.

```bash
node "${CLAUDE_PLUGIN_ROOT}/scripts/triage.cjs" scan "<TARGET_PATH>" --output .bug-hunter/triage.json
```

Then read `.bug-hunter/triage.json`. It contains:
- `strategy`: which mode to use ("single-file", "small", "parallel", "extended", "scaled", "large-codebase")
- `modeFile`: which mode file to read
- `fileBudget`: computed from actual file sizes (sampled), not a guess
- `totalFiles` / `scannableFiles`: exact count
- `domains`: directory-level risk classification (CRITICAL/HIGH/MEDIUM/LOW/CONTEXT-ONLY)
- `riskMap`: file-level classification (only present when ≤200 files)
- `domainFileLists`: per-domain file lists (only present for large-codebase strategy)
- `scanOrder`: priority-ordered list for Hunters
- `tokenEstimate`: cost estimates for each pipeline phase
- `needsLoop`: whether loop mode is needed for full coverage (loop is on by default; this indicates `--no-loop` would cause incomplete coverage)

**Set these variables from the triage output:**
```
STRATEGY = triage.strategy
FILE_BUDGET = triage.fileBudget
TOTAL_FILES = triage.totalFiles
SCANNABLE_FILES = triage.scannableFiles
NEEDS_LOOP = triage.needsLoop
```

**Report to the user:**
```
Triage: [TOTAL_FILES] source files | FILE_BUDGET: [FILE_BUDGET] | Strategy: [STRATEGY]
Domains: [N] CRITICAL, [N] HIGH, [N] MEDIUM, [N] LOW
Token estimate: ~[N] tokens for full pipeline
```

**If triage says `needsLoop: true` and `LOOP_MODE=false`** (user passed `--no-loop`), warn:
```
⚠️ This codebase has [N] source files (FILE_BUDGET: [B]).
Single-pass mode will only cover a subset. Remove `--no-loop` to enable iterative coverage.
Proceeding with partial scan — highest-priority queued files only.
```

**Triage replaces Recon's FILE_BUDGET computation.** Recon still runs for tech stack identification and pattern-based analysis, but it no longer needs to count files or compute the context budget — triage already did that, for free.

### Step 1b: Generate threat model (if --threat-model)

If `THREAT_MODEL_MODE=true`:
1. Read the bundled local skill `${CLAUDE_PLUGIN_ROOT}/skills/dev/references/threat-model.md` before generating the threat model. This keeps the enterprise security pack end-to-end connected to the main Bug Hunter flow.
2. Use the bundled skill's Bug Hunter-native artifact conventions (`.bug-hunter/threat-model.md`, `.bug-hunter/security-config.json`).

3. Check if `.bug-hunter/threat-model.md` already exists.
   - If it exists and was modified within the last 90 days: use it as-is. Set `THREAT_MODEL_AVAILABLE=true`.
   - If it exists but is >90 days old: warn user ("Threat model is N days old — regenerating"), regenerate.
   - If it doesn't exist: generate it.
2. To generate:
   - Read `${CLAUDE_PLUGIN_ROOT}/skills/dev/references/threat-model.md`.
   - Dispatch the threat model generation agent (or execute locally if local-sequential).
   - Input: triage.json (if available) for file structure, or Glob-based discovery.
   - Wait for `.bug-hunter/threat-model.md` to be written.
3. Set `THREAT_MODEL_AVAILABLE=true`.

If `THREAT_MODEL_MODE=false` but `.bug-hunter/threat-model.md` exists:
- Load it anyway — free context. Set `THREAT_MODEL_AVAILABLE=true`.
- Report: "Existing threat model found — loading for enhanced security analysis."

### Step 1c: Dependency scan (if --deps)

If `DEP_SCAN=true` or `SECURITY_REVIEW_MODE=true` or `PR_SECURITY_MODE=true`:
- Read the bundled local skill `${CLAUDE_PLUGIN_ROOT}/skills/dev/references/security-review.md` when running the broader enterprise security workflow.

If `DEP_SCAN=true`: 
```bash
node "${CLAUDE_PLUGIN_ROOT}/scripts/dep-scan.cjs" --target "<TARGET_PATH>" --output .bug-hunter/dep-findings.json
```

Report to user:
```
Dependencies: [N] HIGH/CRITICAL CVEs found | [R] reachable, [P] potentially reachable, [U] not reachable
```

If `.bug-hunter/dep-findings.json` exists with REACHABLE findings, include them in Hunter context as "Known Vulnerable Dependencies" — Hunter should verify if vulnerable APIs are called in scanned source files.

### Step 2: Read prompt files on demand (context efficiency)

**Security-pack routing:**
- If `PR_SECURITY_MODE=true`, read `${CLAUDE_PLUGIN_ROOT}/skills/dev/references/commit-scan.md` before the normal PR-review scan.
- If `SECURITY_REVIEW_MODE=true`, read `${CLAUDE_PLUGIN_ROOT}/skills/dev/references/security-review.md` before the broader security audit flow.
- If `VALIDATE_SECURITY_MODE=true`, read `${CLAUDE_PLUGIN_ROOT}/skills/dev/references/vuln-validation.md` before finalizing confirmed security findings.

**MANDATORY**: You MUST read prompt files using the Read tool before passing them to subagents or executing them yourself. Do NOT skip this or act from memory. Use the absolute ${CLAUDE_PLUGIN_ROOT} path resolved in Step 0.

**Load only what you need for each phase — do NOT read all files upfront:**

| Phase | Read These Files |
|-------|-----------------|
| PR security review | `skills/dev/references/commit-scan.md` (if `PR_SECURITY_MODE=true` or the user asks for PR-focused security review) |
| Security review | `skills/dev/references/security-review.md` (if `SECURITY_REVIEW_MODE=true` or the user asks for an enterprise/full security audit) |
| Threat Model (Step 1b) | `skills/dev/references/threat-model.md` (only if THREAT_MODEL_MODE=true) |
| Recon (Step 4) | `skills/dev/references/recon.md` (skip for single-file mode) |
| Hunters (Step 5) | `skills/dev/references/hunter.md` + `skills/dev/examples/hunter-examples.md` |
| Security validation | `skills/dev/references/vuln-validation.md` (if `VALIDATE_SECURITY_MODE=true` or confirmed security findings need exploitability validation) |
| Skeptics (Step 6) | `skills/dev/references/skeptic.md` + `skills/dev/examples/skeptic-examples.md` |
| Referee (Step 7) | `skills/dev/references/referee.md` |
| Fixers (Phase 2) | `skills/dev/references/fixer.md` (only if FIX_MODE=true) |

**Concrete examples for each backend:**

#### Example A: local-sequential (most common)

```
# Phase B — launching Hunter yourself
# 1. Read the skill file:
read({ path: "${CLAUDE_PLUGIN_ROOT}/skills/dev/references/hunter.md" })

# 2. You now have the Hunter's full instructions. Execute them yourself:
#    - Read each file in risk-map order using the Read tool
#    - Apply the security checklist sweep
#    - Write each finding in BUG-N format

# 3. Write your canonical findings artifact to disk:
write({ path: ".bug-hunter/findings.json", content: "<your findings json>" })
```

After reading each reference file, execute the phase instructions yourself within your context window. Write phase outputs to `.bug-hunter/` files between phases.

**Context pruning between phases:** When passing bug lists to Skeptic, Fixer, or Referee phases, only include the bugs relevant to that phase — not the full merged list. For each bug, include: BUG-ID, severity, file, lines, claim, evidence, runtime trigger, cross-references. Omit: the Hunter's internal reasoning, scan coverage stats, and any "FILES SCANNED/SKIPPED" metadata.

### Step 3: Determine execution mode

**Use the triage output from Step 1** — the strategy and FILE_BUDGET are already computed. Do NOT wait for Recon to determine the mode.

Read the corresponding mode file using `STRATEGY` from the triage JSON:
- `single-file`: `${CLAUDE_PLUGIN_ROOT}/skills/dev/modes/single-file.md`
- `small`: `${CLAUDE_PLUGIN_ROOT}/skills/dev/modes/small.md`
- `parallel`: `${CLAUDE_PLUGIN_ROOT}/skills/dev/modes/parallel.md`
- `extended`: `${CLAUDE_PLUGIN_ROOT}/skills/dev/modes/extended.md`
- `scaled`: `${CLAUDE_PLUGIN_ROOT}/skills/dev/modes/scaled.md`
- `large-codebase`: force `LOOP_MODE=true` and read `${CLAUDE_PLUGIN_ROOT}/skills/dev/modes/large-codebase.md` then `${CLAUDE_PLUGIN_ROOT}/skills/dev/modes/loop.md`

**Backend override for local-sequential:** If `AGENT_BACKEND = "local-sequential"`, read `${CLAUDE_PLUGIN_ROOT}/skills/dev/modes/local-sequential.md` instead of the size-based mode file. The local-sequential mode handles all sizes internally with its own chunking logic.

If LOOP_MODE=true, also read (loop.md includes experiment tracking with iteration caps, stop-file safety, and auto-resume):
- `${CLAUDE_PLUGIN_ROOT}/skills/dev/modes/fix-loop.md` when FIX_MODE=true
- `${CLAUDE_PLUGIN_ROOT}/skills/dev/modes/loop.md` otherwise

**CRITICAL — experiment tracking initialization:** When `LOOP_MODE=true`, initialize experiment tracking BEFORE the first pipeline iteration by running:
```bash
node "${CLAUDE_PLUGIN_ROOT}/scripts/experiment-loop.cjs" init \
  .bug-hunter/experiment.jsonl \
  "bug-hunt-$(date +%Y%m%d)" \
  bugs_confirmed \
  higher \
  count \
  --max-iterations "$MAX_LOOP_ITERATIONS"
```
Then before each iteration, call `check-continue`:
```bash
node "${CLAUDE_PLUGIN_ROOT}/scripts/experiment-loop.cjs" check-continue \
  .bug-hunter/experiment.jsonl \
  --stop-file .bug-hunter/experiment.stop
```
If `continue` is false, stop the loop immediately. After each iteration, log the result with `log`. This is active by default — no `--experiment` flag needed.


Report the chosen mode to the user.

**Then follow the steps in the loaded mode file.** Each mode file contains the specific steps for running Recon, Hunters, Skeptics, and Referee for that mode. Each mode also references `modes/_dispatch.md` for backend-specific dispatch patterns. Execute them in order.

**Branch-diff and staged optimization:** For `-b` and `--staged` modes, if the file count ≤ FILE_BUDGET, always use `small` or `parallel` mode regardless of total codebase size. The triage script already handles this since it only scans the provided target files.

For `extended` and `scaled` modes, initialize state before chunk execution:
```
node "${CLAUDE_PLUGIN_ROOT}/scripts/bug-hunter-state.cjs" init ".bug-hunter/state.json" "<mode>" "<files-json-path>" 30
```
Then apply hash-based skip filtering before each chunk:
```
node "${CLAUDE_PLUGIN_ROOT}/scripts/bug-hunter-state.cjs" hash-filter ".bug-hunter/state.json" "<chunk-files-json-path>"
```

For full autonomous chunk orchestration with timeouts, retries, and journaling, extended/scaled modes can use:
```
node "${CLAUDE_PLUGIN_ROOT}/scripts/run-bug-hunter.cjs" run --skill-dir "$${CLAUDE_PLUGIN_ROOT}" --files-json "<files-json-path>" --mode "<mode>"
```
See `run-bug-hunter.cjs --help` for all options (delta-mode, canary-size, expand-on-low-confidence, etc.).

---

## Step 7: Present the Final Report

After the mode-specific steps complete, display the final report:

### 1. Scan metadata
- Mode (single-file / small / parallel-hybrid / extended / scaled / loop)
- Files scanned: N source files (N filtered out)
- Architecture: [summary from Recon]
- Tech stack: [framework, auth, DB from Recon]

### 2. Pipeline summary
```
Triage:    [N] source files | FILE_BUDGET: [B] | Strategy: [STRATEGY]
Recon:     mapped N files -> CRITICAL: X | HIGH: Y | MEDIUM: Z | Tests: T
Hunters:   [deep scan findings: W | optional triage findings: T | merged: U unique]
Gap-fill:  [N files re-scanned, M additional findings] (or "not needed")
Skeptics:  [challenged X | disproved: D, accepted: A]
Referee:   confirmed N real bugs -> Critical: X | Medium: Y | Low: Z
```

### 3. Confirmed bugs table
(sorted by severity — from Referee output)

### 4. Low-confidence items
Flagged for manual review.
- Include an **Auto-fix eligibility** field per bug:
  - `ELIGIBLE`: Referee confidence >= 75%
  - `MANUAL_REVIEW`: confidence < 75% or missing confidence
- If low-confidence items exist, expand scan scope from delta mode using trust-boundary overlays before finalizing report.

### 5. Dismissed findings
In a collapsed `<details>` section (for transparency).

### 6. Agent accuracy stats
- Deep Hunter accuracy: X/Y confirmed (Z%)
- Optional triage value: N triage-only findings promoted to deep scan
- Skeptic accuracy: X/Y correct challenges (Z%)

### 7. Coverage assessment
- If ALL queued scannable source files scanned: "Full queued coverage achieved."
- If any missed: list them with note about `--loop` mode.

### 7b. Coverage enforcement (mandatory)

If the coverage assessment shows ANY queued scannable source files were not scanned, the pipeline is NOT complete:


2. If `LOOP_MODE=false` (`--no-loop` was specified) AND missed files exist:
   - If total files ≤ FILE_BUDGET × 3: Output the report with a WARNING:
     ```
     ⚠️ PARTIAL COVERAGE: [N] queued source files were not scanned.
     Run `/bug-hunt [path]` for complete coverage (loop is on by default).
     Unscanned files: [list them]
     ```
   - If total files > FILE_BUDGET × 3: The report MUST include:
     ```
     🚨 LARGE CODEBASE: [N] source files (FILE_BUDGET: [B]).
     Single-pass audit covered [X]% of queued source files.
     Use `/bug-hunt [path]` for full coverage (loop is on by default).
     ```

3. Do NOT claim "audit complete" or "full coverage achieved" unless ALL queued scannable source files have status DONE. A partial audit is still valuable — report what you found honestly.

4. Autonomous runs must keep descending through the remaining priority queue after the current prioritized chunk is done:
   - Finish current CRITICAL/HIGH work first.
   - Immediately continue with remaining MEDIUM files.
   - Then continue with remaining LOW files.
   - Only stop when the queue is exhausted, the user interrupts, or a hard blocker prevents safe progress.

If zero bugs were confirmed, say so clearly — a clean report is a good result.

**Routing after report:**
- If there are confirmed security findings AND (`VALIDATE_SECURITY_MODE=true` OR `PR_SECURITY_MODE=true` OR `SECURITY_REVIEW_MODE=true`):
  - Read `${CLAUDE_PLUGIN_ROOT}/skills/dev/references/vuln-validation.md`.
  - Re-check reachability, exploitability, PoC quality, and CVSS details for the confirmed security findings before finalizing the security summary.
- If confirmed bugs > 0 AND `PLAN_ONLY_MODE=true`:
  - Build `fix-strategy.json` and `fix-plan.json`.
  - Present the strategy clusters (safe autofix vs manual review vs larger refactor vs architectural remediation).
  - Stop before the Fixer edits code.
- If confirmed bugs > 0 AND `FIX_MODE=true`:
  - Build and present `fix-strategy.json` first.
  - Auto-fix only `ELIGIBLE` bugs.
  - Apply canary-first rollout: fix top critical eligible subset first, verify, then continue remaining eligible fixes.
  - Keep `MANUAL_REVIEW` bugs in report only (do not auto-edit).
  - Run final global consistency pass over merged findings before applying fixes.
  - Read `${CLAUDE_PLUGIN_ROOT}/skills/dev/modes/fix-pipeline.md` and execute Phase 2 on eligible subset.
- If confirmed bugs > 0 AND `FIX_MODE=false`: stop after report (scan-only mode).
- If zero bugs confirmed: stop here. The report is the final output.

### 8. JSON output (always generated)

After the markdown report, write a machine-readable findings file to `.bug-hunter/findings.json`:

```json
{
  "version": "3.0.0",
  "scan_id": "scan-YYYY-MM-DD-HHmmss",
  "scan_date": "<ISO 8601>",
  "mode": "<strategy>",
  "target": "<target path>",
  "files_scanned": 0,
  "threat_model_loaded": false,
  "confirmed": [
    {
      "id": "BUG-1",
      "severity": "CRITICAL",
      "category": "security",
      "stride": "Tampering",
      "cwe": "CWE-89",
      "file": "src/api/users.ts",
      "lines": "45-49",
      "claim": "SQL injection via unsanitized query parameter",
      "reachability": "EXTERNAL",
      "exploitability": "EASY",
      "cvss_vector": "CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:N",
      "cvss_score": 9.1,
      "poc": { "payload": "...", "request": "...", "expected": "...", "actual": "..." }
    }
  ],
  "dismissed": [
    { "id": "BUG-3", "severity": "Medium", "category": "logic", "file": "...", "claim": "...", "reason": "..." }
  ],
  "dependencies": [],
  "summary": {
    "total_reported": 0, "confirmed": 0, "dismissed": 0,
    "by_severity": { "CRITICAL": 0, "HIGH": 0, "MEDIUM": 0, "LOW": 0 },
    "by_stride": { "Tampering": 0, "InfoDisclosure": 0, "ElevationOfPrivilege": 0, "Spoofing": 0, "DoS": 0, "Repudiation": 0, "N/A": 0 },
    "by_category": { "security": 0, "logic": 0, "error-handling": 0 }
  }
}
```

Rules for JSON output:
- Non-security findings: `stride: "N/A"`, `cwe: "N/A"`, omit reachability/CVSS/PoC fields.
- Security findings without CRITICAL/HIGH severity: omit CVSS and PoC fields.
- `dependencies` array: populated only if `--deps` was used and `.bug-hunter/dep-findings.json` exists.
- This JSON enables CI/CD gating, dashboard ingestion, and downstream patch generation.

Also write the final markdown report to `.bug-hunter/report.md` as the
canonical human-readable output. Generate it from the JSON artifacts with:

```bash
node "${CLAUDE_PLUGIN_ROOT}/scripts/render-report.cjs" report ".bug-hunter/findings.json" ".bug-hunter/referee.json" > ".bug-hunter/report.md"
```

---

## Self-Test Mode

To validate the pipeline works end-to-end, run `/bug-hunt ${CLAUDE_PLUGIN_ROOT}/test-fixture/` on the included test fixture. This directory contains a small Express app with 6 intentionally planted bugs (2 Critical, 3 Medium, 1 Low). Expected results:
- Recon should classify 3 files as CRITICAL, 1 as HIGH
- Hunters should find all 6 bugs (possibly more false positives)
- Skeptic should challenge at least 1 false positive
- Referee should confirm all 6 planted bugs

If the pipeline finds fewer than 5 of the 6 planted bugs, the prompts need tuning. If it reports more than 3 false positives that survive to the Referee, the Skeptic prompt needs tightening.

The test fixture is available at the upstream bug-hunter repo (https://github.com/codexstar69/bug-hunter).

---

## Error handling

| Step | Failure | Fallback |
|------|---------|----------|
| Triage | script error | Skip triage, Recon does full classification with FILE_BUDGET=40 default |
| Recon | timeout/error | Skip Recon, Hunters use triage scanOrder (or Glob-based discovery if no triage) |
| Optional scout pass | timeout/error | Disable scout, continue with deep Hunter |
| Deep Hunter | timeout/error | Retry once on narrowed chunk, otherwise report partial coverage |
| Gap-fill Hunter | timeout/error | Note missed files, continue |
| Chunk orchestrator | timeout/error | Retry with exponential backoff, then mark chunk failed |
| Skeptic | timeout/error | Use single Skeptic or accept all findings as-is |
| Referee | timeout/error | Use Skeptic's accepted list as final result |
| Git safety (Step 8a) | not a git repo | Warn user, skip branching |
| Git safety (Step 8a) | stash/branch fails | Warn, continue without safety net |
| Fix lock | lock held | Stop Phase 2, report concurrent fixer run |
| Test baseline (Step 8c) | timeout/not found | Set BASELINE=null, skip test verification |
| Fixer | timeout/error | Mark unfixed bugs as SKIPPED |
| Post-fix tests | new failures | Auto-revert failed fix commit, mark FIX_REVERTED |
| Post-fix re-scan | timeout/error | Skip re-scan, note "fixer output not re-verified" |
| Fix lock release | release fails | Warn user to clear `.bug-hunter/fix.lock` manually |
