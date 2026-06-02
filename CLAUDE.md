# Claude Local Marketplace

Personal plugin marketplace for Claude Code. Plugins here are adapted from upstream open-source repos, rebranded and customized for local use.

## Plugin: design-studio

- **Upstream**: https://github.com/Adityaraj0421/naksha-studio
- **Local path**: `plugins/design-studio/`
- **Branding**: All upstream "naksha/Naksha" references are replaced with "design-studio/Design Studio"
- **Project memory dir**: `.design-studio/` (not `.naksha/`)
- **Renamed commands**: `naksha-init` → `studio-init`, `naksha-status` → `studio-status`, `naksha-doctor` → `studio-doctor`, `naksha-help` → `studio-help`

### How to update design-studio from upstream

1. Pull latest from upstream:
   ```bash
   cd ~/others/naksha-studio && git pull
   ```

2. Check what changed:
   ```bash
   git log --oneline <last-synced-commit>..HEAD
   ```

3. Sync to local marketplace (excluding irrelevant files):
   ```bash
   cd ~/others/naksha-studio && rsync -av \
     --exclude='.git' \
     --exclude='.github/' \
     --exclude='.cursor/' \
     --exclude='.windsurfrules' \
     --exclude='.gitignore' \
     --exclude='GEMINI.md' \
     --exclude='CODE_OF_CONDUCT.md' \
     --exclude='SECURITY.md' \
     --exclude='CONTRIBUTING.md' \
     --exclude='CHANGELOG.md' \
     --exclude='install.sh' \
     --exclude='meta/' \
     --exclude='evals/' \
     --exclude='docs/' \
     --exclude='assets/' \
     --exclude='scripts/behavioral-smoke.sh' \
     --exclude='scripts/validate-structure.js' \
     --exclude='scripts/quality-check.sh' \
     --exclude='scripts/verify-metadata.sh' \
     --exclude='scripts/guard-legacy-branding.sh' \
     --exclude='scripts/sync-labels.sh' \
     --exclude='scripts/run-evals.sh' \
     ./ ~/others/claude-local-marketplace/plugins/design-studio/
   ```

4. Re-apply local modifications:
   - **Rebrand**: Replace all `naksha`/`Naksha` with `design-studio`/`Design Studio` (protect upstream URLs)
   - **Rename commands**: `naksha-*` → `studio-*` (files and all internal references)
   - **plugin.json**: Keep `"name": "design-studio"`
   - **hooks.json**: Remove Stop hook (causes JSON validation error), remove PreToolUse Write hook (unnecessary latency for SvelteKit workflows)
   - **Verify**: `grep -r "naksha\|Naksha" plugins/design-studio/` — only upstream URLs should remain

5. Update this file's "Last synced" below and commit.

### Sync history

| Date | Upstream version | Upstream commit | Notes |
|------|-----------------|-----------------|-------|
| 2026-03-18 | v4.8.0 | 3e69215 | Full replacement from v3.3.0, rebranded, hooks fixed, prompts improved |

### What NOT to sync

These upstream files are irrelevant for local use:
- `.github/` — CI workflows, issue templates, labels (upstream repo management)
- `.cursor/`, `.windsurfrules`, `GEMINI.md` — platform adapters for other IDEs
- `evals/`, `meta/`, `scripts/*-smoke*`, `scripts/validate-*`, `scripts/quality-*`, `scripts/verify-*`, `scripts/guard-*`, `scripts/sync-*` — upstream CI/QA infrastructure
- `docs/` — upstream submission docs
- `assets/` — upstream social previews
- `CODE_OF_CONDUCT.md`, `SECURITY.md`, `CONTRIBUTING.md`, `CHANGELOG.md`, `install.sh` — upstream community docs

### Tauri v2 mobile references (added locally)

7 reference files integrated from project-local skills into the centralized marketplace:
- `references/tauri-android.md` — safe area insets, keyboard/IME handling, CORS, CSP, WebView debugging, horizontal overflow
- `references/tauri-oauth.md` — OAuth with better-auth in WebView (third-party cookie workaround, 302 redirect, Bearer tokens)
- `references/tauri-webview-gotchas.md` — dark mode (Tailwind v4), textarea cursor, Svelte 5 reactivity, mobile-web parity
- `references/tauri-build.md` — APK/AAB build, signing, ADB install, icon generation, build troubleshooting
- `references/tauri-ipc.md` — Rust commands, events, channels, capabilities/permissions
- `references/tauri-plugins.md` — 20 official + 9 community plugins with APIs
- `references/tauri-dev-setup.md` — ARM64 EC2 setup (SnowNF NDK, qemu, ADB tunnel, binary patching)

Auto-detection: `detect-design-context.sh` detects `src-tauri/` and warns to read Tauri references before mobile UI changes.

### Local prompt improvements

The following command files have been improved beyond upstream based on real usage patterns:
- `commands/design.md` — added file-reading instructions, existing functionality preservation, stack awareness
- `commands/design-review.md` — added end-user perspective enforcement, local file reading over URL fetching
- `commands/design-system.md` — added Tailwind v4 @theme awareness

## Plugin: dev-studio

- **Upstream**: https://github.com/codexstar69/bug-hunter
- **Local path**: `plugins/dev-studio/`
- **Relationship to upstream**: Absorbed bug-hunter pipeline into a plugin. All scripts, schemas, skills, and modes copied and adapted. Not a fork — restructured into plugin architecture.
- **Project output dir**: `.bug-hunter/` (scan results), `.dev-studio/` (project config)

### Commands

- `/bug-hunt` — Adversarial pipeline (Recon→Hunter→Skeptic→Referee→Fixer)
- `/bug-hunt --pr current` — Review current PR
- `/bug-hunt --fix` — Find + auto-fix confirmed bugs
- `/bug-hunt --security-review` — Full security workflow
- `/dev audit` — Systematic 20-check audit (N+1, dead code, perf, security). Output: `.dev-studio/audit-report.md`
- `/dev audit --quick` — Skip Layer 2 verification (faster)
- `/dev audit --fix` — Auto-fix LOW/MEDIUM findings
- `/dev review` — 4-phase structured code review (context→architecture→line-by-line→verdict)
- `/dev review --pr current` — Review current PR with severity labels
- `/dev perf` — Performance analysis (load waterfalls, blocking I/O, bundle size)
- `/dev perf --routes` — SvelteKit load function waterfall analysis
- `/dev perf --bundle` — Bundle size + tree-shaking issues
- `/dev migrate <from> to <to>` — Technology migration workflow (inventory→plan→execute→validate)
- `/dev migrate --plan-only` — Produce plan without executing
- `/dev-init` — Initialize dev-studio config + first triage
- `/dev-status` — Show last report, coverage, triage data
- `/dev-help` — List all commands with "when to use what" guide

### When to use what

| I want to... | Use |
|---|---|
| Find unknown bugs adversarially | `/bug-hunt` |
| Check code quality systematically | `/dev audit` |
| Review before merging | `/dev review` |
| Find why something is slow | `/dev perf` |
| Switch from tech A to tech B | `/dev migrate` |

### Adaptations from upstream

- Stripped YAML frontmatter from all skill files, replaced `$SKILL_DIR` with `${CLAUDE_PLUGIN_ROOT}`
- Removed subagent/teams/interactive_shell backends — forced local-sequential mode
- Removed ralph-loop, worktree-harvest, payload-guard references
- Renamed `/bug-hunter` → `/bug-hunt` in all usage examples
- All 14 scripts are zero-dependency CommonJS (Node.js stdlib only)

### New skills (v2.0 — added 2026-05-05)

Based on analysis of levnikolaevich/claude-code-skills (audit workers), awesome-skills/code-review-skill (4-phase review), and original work (migrate, perf):

- `skills/audit/SKILL.md` (628 lines) — 4 workers: query-efficiency (6 checks, Drizzle-adapted), dead-code (4), runtime-perf (5), security-smells (5). Layer 2 verification. Codegraph MCP integration.
- `skills/review/SKILL.md` (201 lines) — 4-phase review with severity labels ([blocking]/[important]/[nit]/[suggestion]/[praise]). Svelte 5 anti-pattern checks built in.
- `skills/migrate/SKILL.md` (561 lines) — 5-phase migration: inventory→compatibility→plan→execute→validate. 6 common migrations pre-loaded (Svelte 4→5, Tailwind v3→v4, Prisma→Drizzle, etc.)
- `skills/perf/SKILL.md` (297 lines) — Load waterfalls, blocking sync, client reactivity issues, bundle analysis. SvelteKit streaming pattern suggestions.

### Codegraph MCP integration

Codegraph (~/others/codegraph/) is configured as a global user MCP server. It provides:
- `codegraph_impact` — blast radius analysis (what breaks if I change X)
- `codegraph_callers` / `codegraph_callees` — call chain tracing
- `codegraph_search` — FTS5 symbol search
- `codegraph_context` / `codegraph_explore` — contextual code retrieval

The audit and perf skills use codegraph when available for hot-path detection and blast radius, falling back to grep silently when not indexed.

To index a new project: `cd <project> && codegraph analyze`

### Structure

- 8 commands, 5 skills, 10 reference docs, 9 execution modes, 2 examples
- 14 scripts (~6,400 lines), 10 JSON schemas
- 1 agent (bug-triage), 1 SessionStart hook (detect-dev-context.sh)
- ~65 files total, ~5,000 lines of skill content

## Plugin: sales-studio

- **Upstream inspiration**: https://github.com/msitarzewski/agency-agents (sales/ folder — role identities) + https://github.com/zubair-trabzada/ai-sales-team-claude (frameworks, scoring, templates)
- **Local path**: `plugins/sales-studio/`
- **Relationship to upstream**: Original creation, NOT a fork. Used upstream repos as knowledge input only
- **Project memory dir**: `.sales-studio/`

### What was taken from each source

**From agency-agents** (5 of 8 roles):
- Role identities and core competencies for: Outbound Strategist, Deal Strategist, Proposal Writer, Discovery Coach, Pipeline Tracker
- Expanded 3-5x from ~150 lines to ~450 lines each

**From ai-sales-team-claude** (frameworks, templates, scoring):
- Email Writing Rules + jargon blacklist (sales-outreach)
- BANT+MEDDIC signal detection tables with point values (sales-qualify)
- Revenue estimation methodologies — 4 formulas (sales-research)
- Ghost Recovery sequence — 3 pattern-interrupt emails (sales-followup)
- Cheat Sheet format for meeting prep (sales-prep)
- 15 universal objections with "What it really means" (sales-objections)
- Good-Better-Best pricing psychology (sales-proposal)
- 6 messaging frameworks with decision tree (sales-strategy agent)
- Negative ICP — 10 disqualification criteria (sales-icp)
- `analyze_prospect.py` zero-dependency web scraper (scripts/)

**Original content** (3 roles + all architecture):
- Pricing Strategist, Sales Copywriter, Closing Advisor — no upstream equivalent
- All 12 commands, SKILL.md routing, 2 agents, 3 pipelines, plugin architecture
- Multi-business-model support (SaaS/consulting/agency/freelance/e-commerce)
- Cross-references with design-studio and marketing-studio

### Structure

- 8 roles, 12 commands, 2 agents (haiku), 3 pipelines, 1 Python script
- ~7,600 lines total (30 files)
- Commands: sales-init, sales, sales-status, prospect, outbound, cold-email, deal-review, discovery-prep, proposal, pricing-audit, pipeline-review, objection-bank
- Agents: deal-scorer (quick BANT), email-grader (cold email quality)
- Pipelines: first-sale, deal-cycle, monthly-review

## pi packages (cross-tool port)

The four studios are also packaged for [**pi**](https://github.com/earendil-works/pi) (earendil-works coding agent) in a **separate sibling repo**: `~/others/pi-studios/` (own git repo, distributed via `pi install git:github.com/rp4ri/pi-studios`). The Claude Code plugins in `plugins/` remain the source of truth; the pi repo is **generated**, not hand-maintained.

Kept separate (not a subdir here) because pi expects a package's `package.json` at the repo root, and bundling it inside the Claude marketplace would double the repo with duplicated content. `marketplace.json` only references `./plugins/*`, so the pi port never affects Claude plugin installs.

### Regenerate

```bash
node scripts/convert-to-pi.cjs   # idempotent; writes to ../pi-studios/
```

The script does NOT touch the hand-written `../pi-studios/<studio>/extensions/index.ts` or `../pi-studios/README.md`.

### Conversion mapping

| Claude Code | pi | Transform |
|---|---|---|
| `commands/*.md` | `prompts/*.md` (`/name`) | Drop `allowed-tools` from frontmatter. `description`/`argument-hint` and `$ARGUMENTS`/`$1`/`$@` are identical in pi — body unchanged. |
| `skills/<n>/SKILL.md` | `skills/<n>/SKILL.md` (`/skill:n`) | Verbatim — pi uses the same Agent Skills standard. |
| `agents/*.md` | `skills/<n>/SKILL.md` | Frontmatter normalized to `name` + short `description` (<900 chars, examples stripped); body preserved. |
| `hooks/hooks.json` | `extensions/index.ts` | Hand-written TS using pi events `session_start`, `before_agent_start`, `tool_call`. Only design-studio + dev-studio have hooks. |
| `scripts/`, `schemas/`, `data/` | copied verbatim | — |
| `.claude-plugin/plugin.json` (×4) | single root `package.json` (`pi` manifest) | One aggregating manifest at `../pi-studios/package.json` with explicit per-studio paths, so one `pi install git:` loads all four. |

### Non-portable pieces (handled in extensions)

- **dev-studio read-before-edit guardian**: the original `guardian-pre-edit.sh`/`guardian-pre-write.sh` depend on Claude's `transcript_path`. Reimplemented natively in the pi extension by tracking the `read` tool in a Set. `guardian-pre-bash.sh` is still invoked (only needs `tool_input.command`).
- **MCP** (figma, playwright, stitch, perplexity, codegraph): not auto-wired in pi — documented in `../pi-studios/README.md` for `pi-mcp-adapter` setup.

### Generated structure (one repo, one package)

| Studio dir | Prompts | Skills | Extension |
|---|---|---|---|
| `design-studio` | 60 | 8 | SessionStart context |
| `dev-studio` | 9 | 6 | SessionStart + bash guardian + read-before-edit |
| `marketing-studio` | 11 | 3 | — |
| `sales-studio` | 12 | 3 | — |
