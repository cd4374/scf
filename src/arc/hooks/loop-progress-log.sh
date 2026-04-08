#!/usr/bin/env bash
set -euo pipefail
INPUT=$(cat)
FILE=$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))' <<<"$INPUT" 2>/dev/null || true)
[[ "$FILE" != *"draft.tex" && "$FILE" != *"review"* && "$FILE" != *".bib" ]] && exit 0
STAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
if [[ "$FILE" == *".bib" ]]; then
  mkdir -p "$CLAUDE_PROJECT_DIR/.arc/loop-logs/citation-rounds"
  printf '{"timestamp":"%s","file":"%s"}\n' "$STAMP" "$FILE" >> "$CLAUDE_PROJECT_DIR/.arc/loop-logs/citation-rounds/progress.log"
else
  mkdir -p "$CLAUDE_PROJECT_DIR/.arc/loop-logs/review-rounds"
  printf '{"timestamp":"%s","file":"%s"}\n' "$STAMP" "$FILE" >> "$CLAUDE_PROJECT_DIR/.arc/loop-logs/review-rounds/progress.log"
fi
exit 0
