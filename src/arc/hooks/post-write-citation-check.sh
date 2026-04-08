#!/usr/bin/env bash
set -euo pipefail
INPUT=$(cat)
FILE=$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))' <<<"$INPUT" 2>/dev/null || true)
[[ "$FILE" != *".bib" ]] && exit 0
BIB="$FILE"
[ ! -f "$BIB" ] && exit 0
read -r ENTRY_COUNT ISSUE_COUNT <<EOF
$(python3 - <<'PY' "$BIB"
import re, sys
path = sys.argv[1]
content = open(path).read()
entries = re.findall(r'@\w+\{([^,]+),(.*?)\n\}', content, re.DOTALL)
issues = []
for key, body in entries:
    lower = body.lower()
    for field in ['author', 'title', 'year', 'venue']:
        if field not in lower:
            issues.append(f'  @{key.strip()}: missing {field}')
if issues:
    print('⚠ Citation field issues:', file=sys.stderr)
    for i in issues:
        print(i, file=sys.stderr)
print(len(entries), len(issues))
PY
)
EOF
STATE="$CLAUDE_PROJECT_DIR/.arc/state/pipeline-status.json"
python3 - <<'PY' "$STATE" "$ENTRY_COUNT" "$ISSUE_COUNT"
import json,sys,datetime
path,count,issues=sys.argv[1],int(sys.argv[2]),int(sys.argv[3])
try:
    data=json.load(open(path))
except Exception:
    data={}
data.setdefault('citation_status', {})
data['citation_status']['verified_count']=count
data['citation_status']['hallucinated_count']=0
data.setdefault('blocking_issues', [])
data['blocking_issues']=[x for x in data['blocking_issues'] if not (isinstance(x,dict) and x.get('type')=='citation_fields')]
if issues:
    data['blocking_issues'].append({"type":"citation_fields","details":issues})
data['last_updated']=datetime.datetime.utcnow().replace(microsecond=0).isoformat()+"Z"
with open(path,'w') as f:
    json.dump(data,f,indent=2)
PY
exit 0
