#!/usr/bin/env bash
set -euo pipefail
INPUT=$(cat)
if command -v jq >/dev/null 2>&1; then
  FILE=$(jq -r '.tool_input.file_path // ""' <<<"$INPUT" 2>/dev/null || true)
else
  FILE=$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))' <<<"$INPUT" 2>/dev/null || true)
fi
[[ "$FILE" != *"draft.tex" ]] && exit 0
STATE="$CLAUDE_PROJECT_DIR/.arc/state/pipeline-status.json"
AGENT=""
if [ -f "$STATE" ]; then
  if command -v jq >/dev/null 2>&1; then
    AGENT=$(jq -r '.active_agent // ""' "$STATE" 2>/dev/null || true)
  else
    AGENT=$(python3 - <<'PY' "$STATE"
import json,sys
try:
    print(json.load(open(sys.argv[1])).get('active_agent',''))
except Exception:
    print('')
PY
)
  fi
fi
REVIEWER_AGENTS="idea-validator novelty-checker literature-reviewer logic-checker stat-auditor figure-auditor citation-verifier integrity-checker peer-reviewer-1 peer-reviewer-2 devils-advocate multi-agent-debate final-reviewer"
if echo "$REVIEWER_AGENTS" | grep -qw "$AGENT"; then
  echo '{"decision":"block","reason":"Reviewer agents cannot write draft.tex; write review output to .arc/state/review-*.json"}'
  exit 2
fi
exit 0
