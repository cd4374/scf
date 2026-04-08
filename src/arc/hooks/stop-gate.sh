#!/usr/bin/env bash
# stop-gate is intentionally tolerant (no set -euo pipefail)
INPUT=$(cat)
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
STATE_DIR="$PROJECT_DIR/.arc/state"
ENV_JSON="$PROJECT_DIR/.arc/env.json"
DRAFT="$PROJECT_DIR/draft.tex"
BIB="$PROJECT_DIR/references.bib"

BLOCKING_REASONS=()
WARNINGS=()

add_block() {
  BLOCKING_REASONS+=("$1")
}

add_warn() {
  WARNINGS+=("$1")
}

if [ -f "$STATE_DIR/review-final.json" ]; then
  FINAL_PASS=$(python3 - <<'PY' "$STATE_DIR/review-final.json"
import json,sys
try:
    data=json.load(open(sys.argv[1], encoding='utf-8'))
    print('true' if data.get('pass') is True else 'false')
except Exception:
    print('false')
PY
)
  if [ "$FINAL_PASS" != "true" ]; then
    add_block "review-final.json pass=false"
  fi
else
  add_warn "missing .arc/state/review-final.json"
fi

if [ -f "$STATE_DIR/pipeline-status.json" ]; then
  read -r WC_OK WC <<<"$(python3 - <<'PY' "$STATE_DIR/pipeline-status.json"
import json,sys
try:
    d=json.load(open(sys.argv[1], encoding='utf-8'))
    print('true' if d.get('word_count_ok') else 'false', int(d.get('word_count', 0) or 0))
except Exception:
    print('false 0')
PY
)"
  if [ "$WC_OK" != "true" ]; then
    add_block "word_count insufficient: ${WC}/6000"
  fi
else
  add_warn "missing .arc/state/pipeline-status.json"
fi

if [ -f "$DRAFT" ]; then
  read -r FIG_COUNT MISSING_SECTIONS <<<"$(python3 - <<'PY' "$DRAFT"
import re,sys
text=open(sys.argv[1], encoding='utf-8', errors='ignore').read()
figs=re.findall(r'\\includegraphics(?:\[[^\]]*\])?\{([^}]+)\}', text)
required=["Abstract","Introduction","Related Work","Method","Experiments","Conclusion"]
missing=[]
for sec in required:
    if not re.search(r'\\section\{[^}]*'+re.escape(sec)+r'[^}]*\}', text, flags=re.IGNORECASE):
        missing.append(sec)
print(len(figs), '|'.join(missing))
PY
)"
  if [ "$FIG_COUNT" -lt 4 ]; then
    add_block "figure_count insufficient: ${FIG_COUNT}/4"
  fi
  if [ -n "$MISSING_SECTIONS" ]; then
    add_block "missing required sections: ${MISSING_SECTIONS//|/, }"
  fi
else
  add_warn "missing draft.tex; skipped section/figure checks"
fi

if [ -f "$BIB" ]; then
  read -r CIT_COUNT RECENT_RATIO <<<"$(python3 - <<'PY' "$BIB"
import re,sys,datetime
text=open(sys.argv[1], encoding='utf-8', errors='ignore').read()
entries=re.findall(r'@\w+\{[^@]*?\n\}', text, flags=re.DOTALL)
years=[]
for e in entries:
    m=re.search(r'\byear\s*=\s*[\{"]?([12][0-9]{3})', e, flags=re.IGNORECASE)
    if m:
        years.append(int(m.group(1)))
count=len(entries)
if count==0:
    print(0, 0)
    raise SystemExit(0)
current_year=datetime.datetime.utcnow().year
recent=sum(1 for y in years if y >= current_year-5)
ratio=(recent/count)*100.0
print(count, round(ratio, 2))
PY
)"
  if [ "$CIT_COUNT" -lt 20 ]; then
    add_block "citation_count insufficient: ${CIT_COUNT}/20"
  fi
  RECENT_OK=$(python3 - <<'PY' "$RECENT_RATIO"
import sys
try:
    r=float(sys.argv[1])
except Exception:
    r=0.0
print('true' if r >= 60.0 else 'false')
PY
)
  if [ "$RECENT_OK" != "true" ]; then
    add_block "citation_recency insufficient: ${RECENT_RATIO}%/60%"
  fi
else
  add_warn "missing references.bib; skipped citation checks"
fi

if [ -f "$ENV_JSON" ]; then
  read -r VALIDATED MODE UNCLOSED <<<"$(python3 - <<'PY' "$ENV_JSON"
import json,sys
try:
    d=json.load(open(sys.argv[1], encoding='utf-8'))
except Exception:
    print('false unknown 0')
    raise SystemExit(0)
validated='true' if d.get('compute',{}).get('validated') is True else 'false'
mode=d.get('compute',{}).get('mode','unknown')
active=d.get('active_experiments',[])
if not isinstance(active,list):
    active=[]
unclosed=0
for item in active:
    if isinstance(item,dict) and item.get('status','running') != 'collected':
        unclosed += 1
print(validated, mode, unclosed)
PY
)"
  if [ "$VALIDATED" != "true" ]; then
    add_warn "environment not validated; run validate.sh"
  fi
  if [ "$MODE" = "ssh" ] && [ "$UNCLOSED" != "0" ]; then
    add_warn "ssh active_experiments has ${UNCLOSED} uncollected result(s); manual confirmation required"
  fi
else
  add_warn "missing .arc/env.json; run validate.sh"
fi

if [ "${#BLOCKING_REASONS[@]}" -gt 0 ]; then
  REASON=$(printf '%s; ' "${BLOCKING_REASONS[@]}" | sed 's/; $//')
  python3 - <<'PY' "$REASON"
import json,sys
print(json.dumps({"decision":"block","reason":sys.argv[1]}, ensure_ascii=False))
PY
  if [ "${#WARNINGS[@]}" -gt 0 ]; then
    printf 'Final warnings: %s\n' "$(printf '%s; ' "${WARNINGS[@]}" | sed 's/; $//')" >&2
  fi
  exit 2
fi

if [ "${#WARNINGS[@]}" -gt 0 ]; then
  printf 'Final warnings: %s\n' "$(printf '%s; ' "${WARNINGS[@]}" | sed 's/; $//')" >&2
fi

exit 0
