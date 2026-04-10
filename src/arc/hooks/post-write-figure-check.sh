#!/usr/bin/env bash
set -euo pipefail
INPUT=$(cat)
FILE=$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))' <<<"$INPUT" 2>/dev/null || true)
[[ "$FILE" != *"draft.tex" ]] && exit 0
DRAFT="$CLAUDE_PROJECT_DIR/draft.tex"
FIGURES_DIR="$CLAUDE_PROJECT_DIR/.arc/figures/rendered"
STATE="$CLAUDE_PROJECT_DIR/.arc/state/pipeline-status.json"
PT="$CLAUDE_PROJECT_DIR/.arc/paper-type.json"
[ ! -f "$DRAFT" ] && exit 0

# Read min_figures from paper-type.json (default 4)
MIN_FIGS=4
if [ -f "$PT" ]; then
  if command -v jq >/dev/null 2>&1; then
    MIN_FIGS=$(jq -r '.derived_thresholds.min_figures // 4' "$PT" 2>/dev/null || echo "4")
  else
    MIN_FIGS=$(python3 -c "import json; d=json.load(open('$PT')); print(d.get('derived_thresholds',{}).get('min_figures',4))" 2>/dev/null || echo "4")
  fi
fi

MISSING=""
WARNINGS=""

while IFS= read -r fig; do
  # Extract filename from \includegraphics{filename}, strip extension
  base=$(echo "$fig" | sed 's/.*{\([^}]*\)}.*/\1/' | sed 's/\.pdf$//; s/\.png$//; s/\.jpg$//; s/\.jpeg$//')
  if [ ! -f "$FIGURES_DIR/$base.pdf" ] && [ ! -f "$FIGURES_DIR/$base.png" ] \
     && [ ! -f "$CLAUDE_PROJECT_DIR/$base.pdf" ] && [ ! -f "$CLAUDE_PROJECT_DIR/$base.png" ]; then
    MISSING="$MISSING $base"
  fi
done < <(grep -o '\\includegraphics[^{]*{[^}]*}' "$DRAFT" 2>/dev/null || true)

COUNT=$(grep -o '\\includegraphics[^{]*{[^}]*}' "$DRAFT" 2>/dev/null | wc -l | tr -d ' ' || echo "0")

# Check for raster format on charts (should be vector)
RASTER_CHART=$(grep '\\includegraphics' "$DRAFT" 2>/dev/null | grep -E '\.(png|jpg|jpeg)' | wc -l | tr -d ' ' || echo "0")

python3 - <<PY "$STATE" "$COUNT" "$MIN_FIGS" "$MISSING"
import json, sys, datetime

path = sys.argv[1]
count = int(sys.argv[2])
min_figs = int(sys.argv[3])
missing_raw = sys.argv[4].strip()

try:
    data = json.load(open(path))
except Exception:
    data = {}

data['figure_count'] = count
data.setdefault('blocking_issues', [])
data['blocking_issues'] = [x for x in data['blocking_issues']
                           if not (isinstance(x, dict) and x.get('type') == 'missing_figures')]
if missing_raw:
    data['blocking_issues'].append({
        "type": "missing_figures",
        "details": missing_raw.split(),
        "severity": "blocking"
    })
data['last_updated'] = datetime.datetime.utcnow().replace(microsecond=0).isoformat() + "Z"
with open(path, 'w') as f:
    json.dump(data, f, indent=2)
PY

if [ -n "$MISSING" ]; then
  REASON="Referenced figures not found:$MISSING"
  echo "$REASON" >&2
  python3 - <<PY "$REASON"
import json,sys
print(json.dumps({"decision":"block","reason":sys.argv[1]}, ensure_ascii=False))
PY
  exit 2
fi

if [ "$COUNT" -lt "$MIN_FIGS" ]; then
  echo "⚠ Figure count $COUNT < min_figures $MIN_FIGS" >&2
fi

if [ "$RASTER_CHART" -gt 0 ]; then
  echo "⚠ $RASTER_CHART chart(s) in raster format (should be .pdf/.eps vector)" >&2
fi

exit 0
