---
description: "Adversarial bug hunting — multi-agent pipeline finds, verifies, and auto-fixes bugs. Supports PR review, security audits, dependency scanning."
argument-hint: "[path | --pr | --scan-only | --fix | --deps | --security-review]"
allowed-tools: ["Read", "Write", "Edit", "Bash", "Grep", "Glob", "Agent", "WebFetch"]
---

Run the bug-hunt pipeline. Read the skill at ${CLAUDE_PLUGIN_ROOT}/skills/dev/SKILL.md and execute it with the provided arguments.
