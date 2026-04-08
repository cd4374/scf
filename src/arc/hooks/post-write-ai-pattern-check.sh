#!/usr/bin/env bash
set -euo pipefail
INPUT=$(cat)
FILE=$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))' <<<"$INPUT" 2>/dev/null || true)
[[ "$FILE" != *"draft.tex" ]] && exit 0
DRAFT="$CLAUDE_PROJECT_DIR/draft.tex"
[ ! -f "$DRAFT" ] && exit 0
if grep -Eqi 'delve|pivotal|groundbreaking|it is worth noting|importantly|notably' "$DRAFT"; then
  echo "⚠ potential AI-writing patterns detected" >&2
fi
exit 0
