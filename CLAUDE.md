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

### Local prompt improvements

The following command files have been improved beyond upstream based on real usage patterns:
- `commands/design.md` — added file-reading instructions, existing functionality preservation, stack awareness
- `commands/design-review.md` — added end-user perspective enforcement, local file reading over URL fetching
- `commands/design-system.md` — added Tailwind v4 @theme awareness
