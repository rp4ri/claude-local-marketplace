---
description: "Structural regression gate — run sentrux to detect architectural regressions since last baseline."
argument-hint: "[--save | --check | --diff]"
allowed-tools: ["Read", "Write", "Bash", "Grep", "Glob"]
---

# /dev-gate

Architectural regression gate using sentrux.

## Usage

```
/dev-gate              # Compare against saved baseline (default: --check)
/dev-gate --save       # Save current state as baseline (run at start of session/feature)
/dev-gate --check      # Compare current state against baseline, report regressions
/dev-gate --diff       # Show what changed structurally since baseline
```

## How it works

### --save (save baseline)

```bash
sentrux gate --save .
```

This writes `.sentrux/baseline.json` with the current quality_signal and metrics.
Run this at the start of a feature branch or work session.

If `.sentrux/` doesn't exist, create it first:
```bash
mkdir -p .sentrux
```

Report the baseline metrics to the user:
```
Baseline saved:
  quality_signal: 7,234 / 10,000
  modularity: 0.72  acyclicity: 0.95  depth: 4  equality: 0.61
```

### --check (compare against baseline — default)

```bash
sentrux gate .
```

This compares current state against `.sentrux/baseline.json`.

**If no baseline exists:** Tell the user to run `/dev-gate --save` first and stop.

**If baseline exists, report:**

| Metric | Baseline | Current | Delta | Status |
|--------|----------|---------|-------|--------|
| quality_signal | 7,234 | 7,189 | -45 | ✅ OK (< 100) |
| modularity | 0.72 | 0.68 | -0.04 | ⚠ Regression |

**Verdict rules:**
- quality_signal drop > 200 → FAIL: "Significant structural regression. Review before merging."
- quality_signal drop 100-200 → WARN: "Minor regression. Consider reviewing."
- quality_signal drop < 100 or increase → PASS
- Any new dependency cycle → FAIL regardless of score

### --diff (structural diff)

```bash
sentrux check . --format json
```

Compare the output with the saved baseline. Show:
- New files not in baseline
- Files whose coupling (fan-in/fan-out) changed significantly
- New dependency cycles
- God files that grew larger

## Also run rule checks

Regardless of flag, always run:
```bash
sentrux check .
```

Report any rule violations from `.sentrux/rules.toml` (layer violations, naming conventions, etc.)

## Prerequisites

- `sentrux` must be in PATH. If not: "sentrux not found. Install from https://github.com/nicolo-mn/sentrux"
- For best results, create `.sentrux/rules.toml` with project-specific rules (layer boundaries, max complexity, etc.)
