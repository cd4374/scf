#!/usr/bin/env bash
set -euo pipefail
INPUT=$(cat)
FILE=$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))' <<<"$INPUT" 2>/dev/null || true)
[[ "$FILE" != *"draft.tex" ]] && exit 0
DRAFT="$CLAUDE_PROJECT_DIR/draft.tex"
[ ! -f "$DRAFT" ] && exit 0
MIN_WORDS=6000
WORD_COUNT=$(grep -v '^\s*%' "$DRAFT" | sed 's/\\[a-zA-Z]*\*\?//g; s/[{}]//g' | wc -w | tr -d ' ')
STATE="$CLAUDE_PROJECT_DIR/.arc/state/pipeline-status.json"
python3 - <<'PY' "$STATE" "$WORD_COUNT" "$MIN_WORDS"
import json,sys,datetime
path,wc,minw=sys.argv[1],int(sys.argv[2]),int(sys.argv[3])
try:
    data=json.load(open(path))
except Exception:
    data={}
data['word_count']=wc
data['word_count_ok']=wc>=minw
data['last_updated']=datetime.datetime.utcnow().replace(microsecond=0).isoformat()+"Z"
with open(path,'w') as f:
    json.dump(data,f,indent=2)
PY
[ "$WORD_COUNT" -lt "$MIN_WORDS" ] && echo "⚠ Word count: $WORD_COUNT / $MIN_WORDS" >&2
exit 0
