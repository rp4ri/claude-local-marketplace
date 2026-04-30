#!/bin/bash
# Guardian: Block Edit on files not yet Read in this session
# Checks the transcript JSONL for prior Read calls on the target file

INPUT=$(cat /dev/stdin)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty')

[ -z "$FILE_PATH" ] && exit 0

# If no transcript available, block to be safe
if [ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ]; then
  jq -n --arg file "$FILE_PATH" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: ("Guardian: You must Read " + $file + " before editing it.")
    }
  }'
  exit 0
fi

# Check if this file was Read in the transcript
# Transcript format: {"message":{"content":[{"name":"Read","input":{"file_path":"/path"}}]}}
if grep -F "$FILE_PATH" "$TRANSCRIPT" 2>/dev/null | grep -q '"name"' 2>/dev/null; then
  # Verify it was specifically a Read (not just any mention of the path)
  if grep -F "$FILE_PATH" "$TRANSCRIPT" 2>/dev/null | grep -qE '"name"\s*:\s*"Read"' 2>/dev/null; then
    exit 0
  fi
fi

# File not read — block
jq -n --arg file "$FILE_PATH" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: ("Guardian: You must Read " + $file + " before editing it. This prevents blind edits that break existing functionality.")
  }
}'
