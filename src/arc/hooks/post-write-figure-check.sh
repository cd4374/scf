#!/usr/bin/env bash
set -euo pipefail
INPUT=$(cat)
FILE=$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))' <<<"$INPUT" 2>/dev/null || true)
[[ "$FILE" != *"draft.tex" ]] && exit 0
DRAFT="$CLAUDE_PROJECT_DIR/draft.tex"
FIGURES_DIR="$CLAUDE_PROJECT_DIR/.arc/figures/rendered"
[ ! -f "$DRAFT" ] && exit 0
MISSING=""
while IFS= read -r fig; do
  base=$(echo "$fig" | sed 's/.*{\(.*\)}.*/\1/')
  if [ ! -f "$FIGURES_DIR/$base.pdf" ] && [ ! -f "$FIGURES_DIR/$base.png" ] && [ ! -f "$CLAUDE_PROJECT_DIR/$base.pdf" ] && [ ! -f "$CLAUDE_PROJECT_DIR/$base.png" ]; then
    MISSING="$MISSING $base"
  fi
done < <(grep -o '\\includegraphics[^{]*{[^}]*}' "$DRAFT" 2>/dev/null || true)
COUNT=$(grep -o '\\includegraphics[^{]*{[^}]*}' "$DRAFT" 2>/dev/null | wc -l | tr -d ' ')
STATE="$CLAUDE_PROJECT_DIR/.arc/state/pipeline-status.json"
python3 - <<'PY' "$STATE" "$COUNT" "$MISSING"
import json,sys,datetime
path,count,missing=sys.argv[1],int(sys.argv[2]),sys.argv[3].strip()
try:
    data=json.load(open(path))
except Exception:
    data={}
data['figure_count']=count
data.setdefault('blocking_issues', [])
data['blocking_issues']=[x for x in data['blocking_issues'] if not (isinstance(x,dict) and x.get('type')=='missing_figures')]
if missing:
    data['blocking_issues'].append({"type":"missing_figures","details":missing.split()})
data['last_updated']=datetime.datetime.utcnow().replace(microsecond=0).isoformat()+"Z"
with open(path,'w') as f:
    json.dump(data,f,indent=2)
PY
[ -n "$MISSING" ] && echo "⚠ Referenced figures not found:$MISSING" >&2
exit 0
