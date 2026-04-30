---
description: "Show dev-studio project status — last bug-hunt report, triage data, coverage"
allowed-tools: ["Read", "Bash", "Glob"]
---

# /dev-status

Show the current dev-studio state for this project:

1. Check if `.bug-hunter/` exists — if yes, show:
   - Last report: read `.bug-hunter/report.md` (first 50 lines)
   - Triage: read `.bug-hunter/triage.json` and summarize file counts by risk tier
   - Coverage: read `.bug-hunter/coverage.json` if exists
   - State: read `.bug-hunter/state.json` if exists (show chunk progress)
2. Check if `.dev-studio/` exists — if yes, show config
3. If neither exists, say "No dev-studio data. Run /bug-hunt to start."
