#!/bin/bash
# Guardian: CLAUDE.md health check at session start
# Reads CLAUDE.md, checks length, validates sections have enough detail

INPUT=$(cat /dev/stdin)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
[ -z "$CWD" ] && exit 0

CLAUDE_MD="$CWD/CLAUDE.md"
if [ ! -f "$CLAUDE_MD" ]; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "SessionStart",
      additionalContext: "WARNING: No CLAUDE.md found in project root. Consider creating one with: project name, key files, directory structure, and rules."
    }
  }'
  exit 0
fi

CONTENT=$(cat "$CLAUDE_MD")
CHAR_COUNT=${#CONTENT}
LINE_COUNT=$(echo "$CONTENT" | wc -l)

WARNINGS=""
SECTIONS=""
EMPTY_SECTIONS=""
THIN_SECTIONS=""

# Character count checks
if [ "$CHAR_COUNT" -gt 8000 ]; then
  WARNINGS="${WARNINGS}CRITICAL: CLAUDE.md has ${CHAR_COUNT} chars (>8000). This wastes context window. Trim to essentials.\n"
elif [ "$CHAR_COUNT" -gt 5000 ]; then
  WARNINGS="${WARNINGS}WARNING: CLAUDE.md has ${CHAR_COUNT} chars (>5000). Consider trimming low-value sections.\n"
elif [ "$CHAR_COUNT" -lt 200 ]; then
  WARNINGS="${WARNINGS}WARNING: CLAUDE.md has only ${CHAR_COUNT} chars. Too sparse — add key files, structure, and rules.\n"
fi

# Extract sections (## and ### headings)
SECTION_LINES=$(echo "$CONTENT" | grep -n '^##\+ ' | head -30)
SECTION_COUNT=$(echo "$SECTION_LINES" | grep -c '^' 2>/dev/null)

if [ "$SECTION_COUNT" -lt 2 ]; then
  WARNINGS="${WARNINGS}WARNING: Only ${SECTION_COUNT} sections found. A healthy CLAUDE.md needs at least: Stack, Key Files, Rules.\n"
fi

# Check each section has content (not just a heading with <2 lines before next heading)
PREV_LINE=0
PREV_TITLE=""
while IFS=: read -r LINE_NUM TITLE; do
  [ -z "$LINE_NUM" ] && continue
  if [ "$PREV_LINE" -gt 0 ]; then
    CONTENT_LINES=$((LINE_NUM - PREV_LINE - 1))
    if [ "$CONTENT_LINES" -lt 2 ]; then
      THIN_SECTIONS="${THIN_SECTIONS}  - '${PREV_TITLE}' (${CONTENT_LINES} lines of content)\n"
    fi
  fi
  SECTIONS="${SECTIONS}  - ${TITLE}\n"
  PREV_LINE=$LINE_NUM
  PREV_TITLE=$(echo "$TITLE" | sed 's/^##* //')
done <<< "$SECTION_LINES"

# Check last section (from last heading to end of file)
if [ "$PREV_LINE" -gt 0 ]; then
  CONTENT_LINES=$((LINE_COUNT - PREV_LINE))
  if [ "$CONTENT_LINES" -lt 2 ]; then
    THIN_SECTIONS="${THIN_SECTIONS}  - '${PREV_TITLE}' (${CONTENT_LINES} lines of content)\n"
  fi
fi

if [ -n "$THIN_SECTIONS" ]; then
  WARNINGS="${WARNINGS}WARNING: These sections are too thin (< 2 lines of content):\n${THIN_SECTIONS}"
fi

# Check for recommended sections (case-insensitive)
HAS_STACK=$(echo "$CONTENT" | grep -ic 'stack\|framework\|tech')
HAS_FILES=$(echo "$CONTENT" | grep -ic 'key file\|important file\|archivos\|estructura\|structure')
HAS_RULES=$(echo "$CONTENT" | grep -ic 'rule\|never\|always\|do not\|don.t\|no tocar\|regla')

MISSING=""
[ "$HAS_STACK" -eq 0 ] && MISSING="${MISSING}  - Stack/framework definition\n"
[ "$HAS_FILES" -eq 0 ] && MISSING="${MISSING}  - Key files or directory structure\n"
[ "$HAS_RULES" -eq 0 ] && MISSING="${MISSING}  - Rules or constraints\n"

if [ -n "$MISSING" ]; then
  WARNINGS="${WARNINGS}SUGGESTED: CLAUDE.md is missing these recommended topics:\n${MISSING}"
fi

# Build output
REPORT="CLAUDE.md audit (${CHAR_COUNT} chars, ${LINE_COUNT} lines, ${SECTION_COUNT} sections)"
if [ -n "$WARNINGS" ]; then
  REPORT="${REPORT}\n\n${WARNINGS}"
fi

jq -n --arg report "$REPORT" '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: $report
  }
}'
