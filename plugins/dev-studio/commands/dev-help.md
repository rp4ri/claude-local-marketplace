---
description: "List all dev-studio commands and usage examples"
allowed-tools: []
---

# Dev Studio — Commands

## Bug Hunting
- `/bug-hunt` — Full adversarial scan (Recon→Hunter→Skeptic→Referee→Fixer)
- `/bug-hunt src/` — Scan specific directory
- `/bug-hunt --pr current` — Review current PR
- `/bug-hunt --pr 123` — Review specific PR
- `/bug-hunt --scan-only` — Report only, no fixes
- `/bug-hunt --fix` — Find + auto-fix confirmed bugs
- `/bug-hunt --deps` — Include dependency CVE scan
- `/bug-hunt --security-review` — Full security workflow (threat model + CVEs + code)
- `/bug-hunt --staged` — Pre-commit check on staged files

## Project Management
- `/dev-init` — Initialize dev-studio config + first triage
- `/dev-status` — Show last report, coverage, triage data
- `/dev-help` — This help

## Examples
```
/bug-hunt src/lib/server/       # Scan server-side code
/bug-hunt --pr current --fix    # Review + fix current PR
/bug-hunt -b feat/auth          # Scan branch diff vs main
/bug-hunt --deps --threat-model # Full security audit
```
