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

# Read min_tables from paper-type.json, default 1
if [ -f "$PT" ]; then
  if command -v jq >/dev/null 2>&1; then
    MIN_TABLES=$(jq -r '.derived_thresholds.min_tables // 1' "$PT" 2>/dev/null || echo "1")
  else
    MIN_TABLES=$(python3 -c "import json; d=json.load(open('$PT')); print(d.get('derived_thresholds',{}).get('min_tables',1))" 2>/dev/null || echo "1")
  fi
else
  MIN_TABLES="1"
fi

# Count tables in main body (exclude appendix)
# Appendix starts with \section{Appendix} or \appendix
python3 - <<'PY' "$DRAFT" "$MIN_TABLES" "$STATE"
import re, sys, datetime

draft_path = sys.argv[1]
min_tables = int(sys.argv[2])
state_path = sys.argv[3]

text = open(draft_path, encoding='utf-8', errors='ignore').read()

# Find main body end (before \appendix or appendix section)
appendix_match = re.search(r'\\appendix\b|\\section\{[Aa]ppendix', text, re.IGNORECASE)
main_body = text[:appendix_match.start()] if appendix_match else text

# Count \begin{table} in main body
tables = re.findall(r'\\begin\{table\}', main_body)
table_count = len(tables)

# Check for comparison table (contains Baseline/Ours/Comparison keywords)
has_comparison = bool(re.search(r'\\begin\{table\}.*?(?:[Bb]aseline|[Oo]urs|[Cc]omparison)', main_body, re.DOTALL))

# Update state
try:
    data = json.load(open(state_path))
except Exception:
    data = {}
data['table_count'] = table_count
data['has_comparison_table'] = has_comparison
data['last_updated'] = datetime.datetime.utcnow().replace(microsecond=0).isoformat() + "Z"
with open(state_path, 'w') as f:
    json.dump(data, f, indent=2)

# Warn if insufficient
if table_count < min_tables:
    print(f"⚠ Table count {table_count} < min_tables {min_tables}", file=sys.stderr)
if table_count >= 1 and not has_comparison:
    print("⚠ At least one table found but no results comparison table (Baseline/Ours)", file=sys.stderr)
PY

exit 0
