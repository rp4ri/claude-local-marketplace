#!/bin/bash
# Guardian: Block destructive bash commands
# Catches rm -rf, git reset --hard, git push --force, git checkout ., drop table, etc.

INPUT=$(cat /dev/stdin)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

[ -z "$COMMAND" ] && exit 0

# Normalize: lowercase, collapse whitespace
CMD_LOWER=$(echo "$COMMAND" | tr '[:upper:]' '[:lower:]' | tr -s ' ')

BLOCKED=""
REASON=""

# rm -rf (except safe targets like node_modules, .next, dist, __pycache__, .venv)
if echo "$CMD_LOWER" | grep -qE 'rm\s+-(r|f|rf|fr)\s' ; then
  SAFE_TARGETS='node_modules|\.next|dist|build|__pycache__|\.venv|\.turbo|\.svelte-kit|\.cache'
  if ! echo "$CMD_LOWER" | grep -qE "rm\s+-(r|f|rf|fr)\s+($SAFE_TARGETS)"; then
    BLOCKED="rm -rf"
    REASON="Destructive deletion detected. Specify the exact target or use a safer alternative."
  fi
fi

# git reset --hard
if echo "$CMD_LOWER" | grep -qE 'git\s+reset\s+--hard'; then
  BLOCKED="git reset --hard"
  REASON="This discards all uncommitted changes permanently. Use git stash or git checkout <file> instead."
fi

# git push --force (but allow --force-with-lease)
if echo "$CMD_LOWER" | grep -qE 'git\s+push\s+.*--force' && \
   ! echo "$CMD_LOWER" | grep -qE 'force-with-lease'; then
  BLOCKED="git push --force"
  REASON="Force push can destroy remote history. Use --force-with-lease for safer force pushes."
fi

# git checkout . / git restore .
if echo "$CMD_LOWER" | grep -qE 'git\s+(checkout|restore)\s+\.' ; then
  BLOCKED="git checkout/restore ."
  REASON="This discards all uncommitted changes. Be specific about which files to restore."
fi

# git clean -f
if echo "$CMD_LOWER" | grep -qE 'git\s+clean\s+.*-f'; then
  BLOCKED="git clean -f"
  REASON="This permanently deletes untracked files. Review with git clean -n first."
fi

# drop table / drop database
if echo "$CMD_LOWER" | grep -qE 'drop\s+(table|database|schema)'; then
  BLOCKED="DROP TABLE/DATABASE"
  REASON="Destructive database operation. Verify backup exists before proceeding."
fi

# truncate table
if echo "$CMD_LOWER" | grep -qE 'truncate\s+table'; then
  BLOCKED="TRUNCATE TABLE"
  REASON="This deletes all rows permanently. Verify this is intentional."
fi

if [ -n "$BLOCKED" ]; then
  jq -n --arg cmd "$BLOCKED" --arg reason "$REASON" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: ("Guardian blocked " + $cmd + ": " + $reason)
    }
  }'
  exit 0
fi

exit 0
