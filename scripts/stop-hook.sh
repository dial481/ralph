#!/bin/bash
set -euo pipefail

HOOK_INPUT=$(cat)

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
RALPH_STATE="$PROJECT_DIR/.claude/ralph-loop.local.md"

if [[ ! -f "$RALPH_STATE" ]]; then
  exit 0
fi

ITERATION=$(sed -n 's/^iteration: *//p' "$RALPH_STATE" | head -1)
MAX_ITER=$(sed -n 's/^max_iterations: *//p' "$RALPH_STATE" | head -1)
PROMISE=$(sed -n 's/^completion_promise: *//p' "$RALPH_STATE" | head -1 | tr -d '"')

[[ "$ITERATION" =~ ^[0-9]+$ ]] || ITERATION=1
[[ "$MAX_ITER" =~ ^[0-9]+$ ]] || MAX_ITER=30

if [[ $ITERATION -ge $MAX_ITER ]]; then
  rm -f "$RALPH_STATE"
  exit 0
fi

# Check for promise - but ONLY in assistant messages, not in the hook's own output
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path // ""')
if [[ -n "$TRANSCRIPT_PATH" ]] && [[ -f "$TRANSCRIPT_PATH" ]] && [[ -n "$PROMISE" ]]; then
  # Only check lines that are actual assistant content, not hook injection
  # The promise should appear WITHOUT "output:" before it (that's our instruction)
  if grep -v "output:.*<promise>" "$TRANSCRIPT_PATH" | grep -q "<promise>$PROMISE</promise>" 2>/dev/null; then
    rm -f "$RALPH_STATE"
    exit 0
  fi
fi

NEXT_ITER=$((ITERATION + 1))
if [[ "$(uname)" == "Darwin" ]]; then
  sed -i '' "s/^iteration: .*/iteration: $NEXT_ITER/" "$RALPH_STATE"
else
  sed -i "s/^iteration: .*/iteration: $NEXT_ITER/" "$RALPH_STATE"
fi

TASK=$(awk 'BEGIN{p=0} /^---$/{p++; next} p>=2{print}' "$RALPH_STATE")

# DON'T include the <promise> tags in the reason - that's what broke it!
REASON="🔄 Ralph loop iteration $NEXT_ITER of $MAX_ITER

Continue working on your task. Signal completion by outputting the completion promise with tags.

Task: $TASK"

jq -n --arg reason "$REASON" '{
  "decision": "block",
  "reason": $reason
}'
