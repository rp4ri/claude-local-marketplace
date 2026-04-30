---
description: "Initialize dev-studio configuration for this project"
allowed-tools: ["Read", "Write", "Bash"]
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
4. Report: files classified, risk breakdown, recommended first scan command
