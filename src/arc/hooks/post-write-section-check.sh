#!/usr/bin/env bash
set -euo pipefail
INPUT=$(cat)
FILE=$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))' <<<"$INPUT" 2>/dev/null || true)
[[ "$FILE" != *"draft.tex" ]] && exit 0
DRAFT="$CLAUDE_PROJECT_DIR/draft.tex"
[ ! -f "$DRAFT" ] && exit 0
REQUIRED=("Abstract" "Introduction" "Related Work" "Method" "Experiments" "Conclusion")
MISSING=()
for sec in "${REQUIRED[@]}"; do
  if ! grep -Eqi "\\\\section\{[^}]*${sec}" "$DRAFT"; then
    MISSING+=("$sec")
  fi
done
STATE="$CLAUDE_PROJECT_DIR/.arc/state/pipeline-status.json"
python3 - <<'PY' "$STATE" "${MISSING[*]:-}"
import json,sys,datetime
path,missing=sys.argv[1],sys.argv[2].strip()
try:
    data=json.load(open(path))
except Exception:
    data={}
data.setdefault('blocking_issues', [])
data['blocking_issues']=[x for x in data['blocking_issues'] if not (isinstance(x,dict) and x.get('type')=='missing_sections')]
if missing:
    data['blocking_issues'].append({"type":"missing_sections","details":missing.split()})
data['last_updated']=datetime.datetime.utcnow().replace(microsecond=0).isoformat()+"Z"
with open(path,'w') as f:
    json.dump(data,f,indent=2)
PY
if [ "${#MISSING[@]}" -gt 0 ]; then
  echo "⚠ Missing required sections: ${MISSING[*]}" >&2
fi
exit 0
