#!/usr/bin/env bash
# stop-gate.sh — Final pipeline validation
# stop-gate intentionally tolerant (no set -euo pipefail)
INPUT=$(cat)
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
STATE_DIR="$PROJECT_DIR/.arc/state"
ENV_JSON="$PROJECT_DIR/.arc/env.json"
PT="$PROJECT_DIR/.arc/paper-type.json"
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

# Read thresholds from paper-type.json (required)
MIN_REFS=""
MIN_FIGS=""
MIN_RECENT_PCT=""
if [ -f "$PT" ]; then
  if command -v jq >/dev/null 2>&1; then
    MIN_REFS=$(jq -r '.derived_thresholds.min_references // empty' "$PT")
    MIN_FIGS=$(jq -r '.derived_thresholds.min_figures // empty' "$PT")
    MIN_RECENT_PCT=$(jq -r '.derived_thresholds.min_recent_refs_pct // empty' "$PT")
  else
    MIN_REFS=$(python3 -c "import json; d=json.load(open('$PT')); print(d.get('derived_thresholds',{}).get('min_references',''))" 2>/dev/null || echo "")
    MIN_FIGS=$(python3 -c "import json; d=json.load(open('$PT')); print(d.get('derived_thresholds',{}).get('min_figures',''))" 2>/dev/null || echo "")
    MIN_RECENT_PCT=$(python3 -c "import json; d=json.load(open('$PT')); print(d.get('derived_thresholds',{}).get('min_recent_refs_pct',''))" 2>/dev/null || echo "")
  fi
else
  add_block "missing .arc/paper-type.json"
fi

if [ -z "$MIN_REFS" ] || [ -z "$MIN_FIGS" ] || [ -z "$MIN_RECENT_PCT" ]; then
  add_block "paper-type thresholds missing required fields (min_references/min_figures/min_recent_refs_pct)"
fi

# Check 1: review-final.json
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

# Check 2: review-integrity.json (v5 new)
if [ -f "$STATE_DIR/review-integrity.json" ]; then
  INTEG_PASS=$(python3 - <<'PY' "$STATE_DIR/review-integrity.json"
import json,sys
try:
    data=json.load(open(sys.argv[1], encoding='utf-8'))
    print('true' if data.get('pass') is True else 'false')
except Exception:
    print('false')
PY
)
  if [ "$INTEG_PASS" != "true" ]; then
    add_block "review-integrity.json pass=false — academic integrity violation"
  fi
else
  add_warn "missing .arc/state/review-integrity.json"
fi

# Check 3: review-stat.json (v5 new)
if [ -f "$STATE_DIR/review-stat.json" ]; then
  STAT_PASS=$(python3 - <<'PY' "$STATE_DIR/review-stat.json"
import json,sys
try:
    data=json.load(open(sys.argv[1], encoding='utf-8'))
    print('true' if data.get('pass') is True else 'false')
except Exception:
    print('false')
PY
)
  if [ "$STAT_PASS" != "true" ]; then
    add_block "review-stat.json pass=false — statistical compliance issues"
  fi
else
  add_warn "missing .arc/state/review-stat.json"
fi

# Check 4: page count vs paper-type limit
PAGE_LIMIT=100
if [ -f "$PT" ]; then
  if command -v jq >/dev/null 2>&1; then
    PAGE_LIMIT=$(jq -r '.page_limit // 100' "$PT")
  else
    PAGE_LIMIT=$(python3 -c "import json; d=json.load(open('$PT')); print(d.get('page_limit',100))" 2>/dev/null || echo "100")
  fi
fi
if [ -f "$DRAFT" ] && [ -f "$STATE_DIR/pipeline-status.json" ]; then
  PAGE_COUNT=$(python3 - <<'PY' "$STATE_DIR/pipeline-status.json"
import json,sys
try:
    d=json.load(open(sys.argv[1], encoding='utf-8'))
    print(d.get('page_count', 0))
except Exception:
    print(0)
PY
)
  if [ "$PAGE_COUNT" != "0" ] && [ "$PAGE_COUNT" -gt "$PAGE_LIMIT" ]; then
    add_block "page_count $PAGE_COUNT exceeds page_limit $PAGE_LIMIT"
  fi
fi

# Check 5: Figure count vs min_figures
if [ -f "$DRAFT" ]; then
  FIG_COUNT=$(python3 - <<'PY' "$DRAFT"
import re,sys
text=open(sys.argv[1], encoding='utf-8', errors='ignore').read()
figs=re.findall(r'\\includegraphics(?:\[[^\]]*\])?\{([^}]+)\}', text)
print(len(figs))
PY
)
  if [ "$FIG_COUNT" -lt "$MIN_FIGS" ]; then
    add_block "figure_count insufficient: ${FIG_COUNT}/${MIN_FIGS}"
  fi
fi

# Check 6: Citation count vs min_references
if [ -f "$BIB" ]; then
  CIT_COUNT=$(python3 - <<'PY' "$BIB" "$MIN_REFS" "$MIN_RECENT_PCT"
import re,sys,datetime
text=open(sys.argv[1], encoding='utf-8', errors='ignore').read()
entries=re.findall(r'@\w+\{[^@]*?\n\}', text, flags=re.DOTALL)
count=len(entries)
years=[]
for e in entries:
    m=re.search(r'\byear\s*=\s*[\{"]?([12][0-9]{3})', e, flags=re.IGNORECASE)
    if m:
        years.append(int(m.group(1)))
recent_pct=0
if count>0:
    current_year=datetime.datetime.utcnow().year
    recent=sum(1 for y in years if y>=current_year-5)
    recent_pct=round((recent/count)*100,2)
print(f"{count}|{recent_pct}")
PY
)
  CIT_NUM="${CIT_COUNT%%|*}"
  RECENT_PCT="${CIT_COUNT##*|}"
  if [ "$CIT_NUM" -lt "$MIN_REFS" ]; then
    add_block "citation_count insufficient: ${CIT_NUM}/${MIN_REFS}"
  fi
  # Check recent refs pct with exemption
  EXEMPT="false"
  if [ -f "$PT" ]; then
    if command -v jq >/dev/null 2>&1; then
      EXEMPT=$(jq -r '.exemptions.recent_refs_pct_exempt // false' "$PT")
    else
      EXEMPT=$(python3 -c "import json; d=json.load(open('$PT')); print(str(d.get('exemptions',{}).get('recent_refs_pct_exempt',False)).lower())" 2>/dev/null || echo "false")
    fi
  fi
  if [ "$EXEMPT" != "true" ] && [ "$RECENT_PCT" -lt "$MIN_RECENT_PCT" ]; then
    add_block "recent_refs_pct insufficient: ${RECENT_PCT}%/${MIN_RECENT_PCT}%"
  fi
fi

# Check 7: env.json validated
if [ -f "$ENV_JSON" ]; then
  VALIDATED=$(python3 - <<'PY' "$ENV_JSON"
import json,sys
try:
    d=json.load(open(sys.argv[1], encoding='utf-8'))
    print('true' if d.get('compute',{}).get('validated') is True else 'false')
except Exception:
    print('false')
PY
)
  MODE=$(python3 - <<'PY' "$ENV_JSON"
import json,sys
try:
    d=json.load(open(sys.argv[1], encoding='utf-8'))
    print(d.get('compute',{}).get('mode','unknown'))
except Exception:
    print('unknown')
PY
)
  UNCLOSED=$(python3 - <<'PY' "$ENV_JSON"
import json,sys
try:
    d=json.load(open(sys.argv[1], encoding='utf-8'))
    active=d.get('active_experiments',[])
    if not isinstance(active,list): active=[]
    print(sum(1 for item in active if isinstance(item,dict) and item.get('status','running')!='collected'))
except Exception:
    print(0)
PY
)
  if [ "$VALIDATED" != "true" ]; then
    add_warn "environment not validated; run validate.sh"
  fi
  if [ "$MODE" = "ssh" ] && [ "$UNCLOSED" != "0" ]; then
    add_warn "ssh active_experiments has ${UNCLOSED} uncollected result(s)"
  fi
else
  add_warn "missing .arc/env.json; run validate.sh"
fi

# Output and exit
if [ "${#BLOCKING_REASONS[@]}" -gt 0 ]; then
  REASON=$(printf '%s; ' "${BLOCKING_REASONS[@]}" | sed 's/; $//')
  python3 - <<PY "$REASON"
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
