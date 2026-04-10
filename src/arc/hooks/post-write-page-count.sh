#!/usr/bin/env bash
set -euo pipefail
INPUT=$(cat)
FILE=$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))' <<<"$INPUT" 2>/dev/null || true)
[[ "$FILE" != *"draft.tex" ]] && exit 0
DRAFT="$CLAUDE_PROJECT_DIR/draft.tex"
STATE="$CLAUDE_PROJECT_DIR/.arc/state/pipeline-status.json"
PT="$CLAUDE_PROJECT_DIR/.arc/paper-type.json"

if [ ! -f "$DRAFT" ]; then
  exit 0
fi

# Read page_limit from paper-type.json, default 9
if [ -f "$PT" ]; then
  if command -v jq >/dev/null 2>&1; then
    PAGE_LIMIT=$(jq -r '.page_limit // 9' "$PT" 2>/dev/null || echo "9")
  else
    PAGE_LIMIT=$(python3 -c "import json; d=json.load(open('$PT')); print(d.get('page_limit',9))" 2>/dev/null || echo "9")
  fi
else
  PAGE_LIMIT="9"
fi

# Try to compile and count pages
TEX_DIR=$(dirname "$DRAFT")
BASENAME=$(basename "$DRAFT" .tex)

cd "$TEX_DIR" 2>/dev/null || exit 0

# Quick compile: pdflatex -> bibtex -> pdflatex -> pdflatex (minimal)
PAGES=""
if command -v pdflatex >/dev/null 2>&1; then
  pdflatex -interaction=batchmode "$BASENAME" >/dev/null 2>&1 || true
  if [ -f "$BASENAME.pdf" ] && command -v pdfinfo >/dev/null 2>&1; then
    PAGES=$(pdfinfo "$BASENAME.pdf" 2>/dev/null | grep "^Pages:" | awk '{print $2}' || echo "")
  fi
fi

if [ -n "$PAGES" ]; then
  # Update pipeline-status
  python3 - <<PY "$STATE" "$PAGES"
import json, sys, datetime
path = sys.argv[1]
pages = int(sys.argv[2])
try:
    data = json.load(open(path))
except Exception:
    data = {}
data['page_count'] = pages
data['last_updated'] = datetime.datetime.utcnow().replace(microsecond=0).isoformat() + "Z"
with open(path, 'w') as f:
    json.dump(data, f, indent=2)
PY

  # Check page limit
  LIMIT_LOW=$((PAGE_LIMIT * 70 / 100))  # 70% threshold
  if [ "$PAGES" -gt "$PAGE_LIMIT" ]; then
    echo "⚠ Page count $PAGES exceeds limit $PAGE_LIMIT" >&2
    echo "{\"decision\":\"block\",\"reason\":\"Page count $PAGES exceeds page_limit $PAGE_LIMIT\"}"
    exit 2
  elif [ "$PAGES" -lt "$LIMIT_LOW" ]; then
    echo "⚠ Page count $PAGES may be insufficient (expected ≥$LIMIT_LOW for limit $PAGE_LIMIT)" >&2
  fi
fi

# If pdflatex not available, skip (post-write-latex-check.sh handles errors)
exit 0
