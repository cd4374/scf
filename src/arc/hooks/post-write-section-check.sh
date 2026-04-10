#!/usr/bin/env bash
set -euo pipefail
INPUT=$(cat)
if command -v jq >/dev/null 2>&1; then
  FILE=$(jq -r '.tool_input.file_path // ""' <<<"$INPUT" 2>/dev/null || true)
else
  FILE=$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))' <<<"$INPUT" 2>/dev/null || true)
fi
[[ "$FILE" != *"draft.tex" ]] && exit 0
DRAFT="$CLAUDE_PROJECT_DIR/draft.tex"
STATE="$CLAUDE_PROJECT_DIR/.arc/state/pipeline-status.json"
PT="$CLAUDE_PROJECT_DIR/.arc/paper-type.json"
[ ! -f "$DRAFT" ] && exit 0

# Read require_ablation from paper-type.json (default false)
REQUIRE_ABLATION="false"
if [ -f "$PT" ]; then
  if command -v jq >/dev/null 2>&1; then
    REQUIRE_ABLATION=$(jq -r '.derived_thresholds.require_ablation // false' "$PT" 2>/dev/null || echo "false")
  else
    REQUIRE_ABLATION=$(python3 -c "import json; d=json.load(open('$PT')); print(str(d.get('derived_thresholds',{}).get('require_ablation',False)).lower())" 2>/dev/null || echo "false")
  fi
fi

python3 - <<'PY' "$DRAFT" "$REQUIRE_ABLATION" "$STATE"
import json, re, sys, datetime

draft_path = sys.argv[1]
require_ablation = sys.argv[2].lower() == "true"
state_path = sys.argv[3]

text = open(draft_path, encoding='utf-8', errors='ignore').read()

# Always required sections
ALWAYS_REQUIRED = [
    "Abstract", "Introduction", "Method", "Experiments",
    "Conclusion", "References"
]

# Conditionally required
CONDITIONAL_REQUIRED = []
if require_ablation:
    CONDITIONAL_REQUIRED.append("Ablation")

# All papers require Limitations (v5)
ALL_PAPERS_REQUIRE = ["Limitations"]

missing = []
warnings = []

for sec in ALWAYS_REQUIRED:
    if not re.search(r'\\section\{[^}]*' + re.escape(sec) + r'[^}]*\}', text, flags=re.IGNORECASE):
        missing.append(sec)

for sec in CONDITIONAL_REQUIRED:
    if not re.search(r'\\section\{[^}]*' + re.escape(sec) + r'[^}]*\}', text, flags=re.IGNORECASE):
        missing.append(sec)
        warnings.append(f"Ablation study required (paper-type require_ablation=true) but section not found")

for sec in ALL_PAPERS_REQUIRE:
    if not re.search(r'\\section\{[^}]*' + re.escape(sec) + r'[^}]*\}', text, flags=re.IGNORECASE):
        missing.append(sec)
        warnings.append(f"Limitations section required for all paper types but not found")

# Update state
try:
    data = json.load(open(state_path))
except Exception:
    data = {}
data.setdefault('blocking_issues', [])
# Remove old missing_sections entries
data['blocking_issues'] = [x for x in data['blocking_issues']
                           if not (isinstance(x, dict) and x.get('type') == 'missing_sections')]
if missing:
    data['blocking_issues'].append({
        "type": "missing_sections",
        "details": missing,
        "require_ablation": require_ablation
    })
data['last_updated'] = datetime.datetime.utcnow().replace(microsecond=0).isoformat() + "Z"
with open(state_path, 'w') as f:
    json.dump(data, f, indent=2)

for w in warnings:
    print(w, file=sys.stderr)
PY

exit 0
