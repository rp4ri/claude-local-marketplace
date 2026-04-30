#!/bin/bash
# Guardian: Validate file depth and check for existing files before Write
# Blocks writes deeper than MAX_DEPTH levels from project root

MAX_DEPTH=8

INPUT=$(cat /dev/stdin)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

[ -z "$FILE_PATH" ] && exit 0
[ -z "$CWD" ] && exit 0

# Calculate depth relative to project root
REL_PATH="${FILE_PATH#$CWD/}"
DEPTH=$(echo "$REL_PATH" | tr '/' '\n' | wc -l)

if [ "$DEPTH" -gt "$MAX_DEPTH" ]; then
  jq -n --arg file "$REL_PATH" --argjson depth "$DEPTH" --argjson max "$MAX_DEPTH" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: ("Guardian: File path " + $file + " is " + ($depth|tostring) + " levels deep (max " + ($max|tostring) + "). Restructure to a flatter path.")
    }
  }'
  exit 0
fi

# If file already exists, warn (Write overwrites completely)
if [ -f "$FILE_PATH" ]; then
  TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty')
  WAS_READ=false
  if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
    if grep -q "\"file_path\":\"${FILE_PATH}\"" "$TRANSCRIPT" 2>/dev/null; then
      WAS_READ=true
    fi
  fi

  if [ "$WAS_READ" = false ]; then
    jq -n --arg file "$FILE_PATH" '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: ("Guardian: " + $file + " already exists. You must Read it before overwriting with Write. Use Edit for partial changes.")
      }
    }'
    exit 0
  fi
fi

exit 0
