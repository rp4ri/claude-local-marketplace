---
description: "List all dev-studio commands and usage examples"
allowed-tools: []
---

# Dev Studio — Commands

## Bug Hunting (adversarial — finds, verifies, fixes)
- `/bug-hunt` — Full adversarial scan (Recon→Hunter→Skeptic→Referee→Fixer)
- `/bug-hunt src/` — Scan specific directory
- `/bug-hunt --pr current` — Review current PR
- `/bug-hunt --staged` — Pre-commit check on staged files
- `/bug-hunt --fix` — Find + auto-fix confirmed bugs
- `/bug-hunt --deps` — Include dependency CVE scan
- `/bug-hunt --security-review` — Full security workflow

## Code Audit (systematic — checklist-driven, no adversarial pipeline)
- `/dev audit` — Full audit: N+1, dead code, perf, security (20 checks)
- `/dev audit src/lib/server/` — Audit specific path
- `/dev audit --staged` — Audit staged files only
- `/dev audit --quick` — Skip Layer 2 verification (faster)
- `/dev audit --fix` — Auto-fix LOW/MEDIUM findings

## Code Review (structured 4-phase)
- `/dev review` — Review staged changes
- `/dev review --pr current` — Review current PR
- `/dev review --pr 123` — Review specific PR
- `/dev review src/routes/` — Review specific path

## Performance Analysis
- `/dev perf` — Analyze routes + server (default)
- `/dev perf --routes` — Load function waterfalls only
- `/dev perf --server` — Server-side perf issues only
- `/dev perf --client` — Client reactivity + re-render issues
- `/dev perf --bundle` — Bundle size + tree-shaking analysis

## Migration Workflow
- `/dev migrate tailwind v3 to v4` — Migrate Tailwind
- `/dev migrate stores to runes` — Svelte stores → runes
- `/dev migrate prisma to drizzle --plan-only` — Plan without executing
- `/dev migrate react to svelte 5 --execute` — Execute with rollback per phase

## Structural Health (sentrux)
- `/dev gate --save` — Save architectural baseline (start of feature/session)
- `/dev gate` — Check for structural regressions against baseline
- `/dev gate --diff` — Show what changed structurally

## Project Management
- `/dev-init` — Initialize config + index codegraph + save sentrux baseline
- `/dev-status` — Show last report, coverage, triage data
- `/dev-help` — This help

## When to use what

| I want to... | Use |
|---|---|
| Find bugs I don't know about | `/bug-hunt` |
| Check code quality systematically | `/dev audit` |
| Review before merging | `/dev review` |
| Find why something is slow | `/dev perf` |
| Switch from tech A to tech B | `/dev migrate` |
| Check if I broke the architecture | `/dev gate` |
