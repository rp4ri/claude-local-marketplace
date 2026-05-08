---
description: "Initialize dev-studio configuration for this project — detect stack, index codegraph, save sentrux baseline."
allowed-tools: ["Read", "Write", "Bash", "Grep", "Glob"]
---

# /dev-init

Initialize dev-studio for this project:

1. Create `.dev-studio/config.json` with detected project context:
   - framework (detect from package.json or pyproject.toml)
   - language (TypeScript, Python, Go, Rust)
   - test runner (vitest, jest, pytest)
   - package manager (pnpm, yarn, npm, uv)
   - ORM (drizzle, prisma, sqlalchemy)
2. Create `.bug-hunter/` output directory
3. Run initial triage: `node ${CLAUDE_PLUGIN_ROOT}/scripts/triage.cjs scan src/ --output .bug-hunter/triage.json`

4. **Index codegraph** (if available):
   ```bash
   which codegraph >/dev/null 2>&1 && codegraph analyze
   ```
   If codegraph is installed, index the project. This creates `.codegraph/codegraph.db`.
   If not installed, skip and note: "codegraph not found — `/dev audit` and `/dev perf` will use grep fallback. Install: `npm install -g @colbymchenry/codegraph`"

5. **Save sentrux baseline** (if available):
   ```bash
   which sentrux >/dev/null 2>&1 && mkdir -p .sentrux && sentrux gate --save .
   ```
   If sentrux is installed, save the structural health baseline. This creates `.sentrux/baseline.json`.
   If not installed, skip and note: "sentrux not found — `/dev audit` Worker 0 and `/dev gate` will be unavailable."

6. Report: files classified, risk breakdown, codegraph index status, sentrux baseline metrics, recommended first scan command.
