#!/usr/bin/env bash
set -euo pipefail
INPUT=$(cat)
FILE=$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))' <<<"$INPUT" 2>/dev/null || true)
[[ "$FILE" != *"draft.tex" ]] && exit 0
DRAFT="$CLAUDE_PROJECT_DIR/draft.tex"
[ ! -f "$DRAFT" ] && exit 0
command -v pdflatex >/dev/null 2>&1 || exit 0
cd "$CLAUDE_PROJECT_DIR"
set +e
FULL_LOG=$(pdflatex -interaction=nonstopmode -halt-on-error draft.tex 2>&1)
STATUS=$?
set -e
LOG=$(printf '%s
' "$FULL_LOG" | tail -20)
STATE="$CLAUDE_PROJECT_DIR/.arc/state/pipeline-status.json"
python3 - <<'PY' "$STATE" "$STATUS"
import json,sys,datetime
path,status=sys.argv[1],int(sys.argv[2])
try:
    data=json.load(open(path))
except Exception:
    data={}
data.setdefault('blocking_issues', [])
data['blocking_issues']=[x for x in data['blocking_issues'] if not (isinstance(x,dict) and x.get('type')=='latex_compile')]
if status != 0:
    data['blocking_issues'].append({"type":"latex_compile","details":"pdflatex failed"})
data['last_updated']=datetime.datetime.utcnow().replace(microsecond=0).isoformat()+"Z"
with open(path,'w') as f:
    json.dump(data,f,indent=2)
PY
if [ "$STATUS" -ne 0 ] || echo "$LOG" | grep -q '! '; then
  echo "⚠ LaTeX compilation errors detected" >&2
  echo "$LOG" | grep '! ' >&2 || true
fi
exit 0
