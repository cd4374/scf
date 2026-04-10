#!/usr/bin/env bash
set -euo pipefail
INPUT=$(cat)
FILE=$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))' <<<"$INPUT" 2>/dev/null || true)
[[ "$FILE" != *"draft.tex" ]] && exit 0
DRAFT="$CLAUDE_PROJECT_DIR/draft.tex"
PT="$CLAUDE_PROJECT_DIR/.arc/paper-type.json"

if [ ! -f "$DRAFT" ]; then
  exit 0
fi

# Read paper_domain and require_ablation from paper-type.json
DOMAIN="ai-experimental"
REQUIRE_ABLATION="false"
if [ -f "$PT" ]; then
  if command -v jq >/dev/null 2>&1; then
    DOMAIN=$(jq -r '.paper_domain // "ai-experimental"' "$PT" 2>/dev/null || echo "ai-experimental")
    REQUIRE_ABLATION=$(jq -r '.derived_thresholds.require_ablation // false' "$PT" 2>/dev/null || echo "false")
  else
    DOMAIN=$(python3 -c "import json; d=json.load(open('$PT')); print(d.get('paper_domain','ai-experimental'))" 2>/dev/null || echo "ai-experimental")
    REQUIRE_ABLATION=$(python3 -c "import json; d=json.load(open('$PT')); print(str(d.get('derived_thresholds',{}).get('require_ablation',False)).lower())" 2>/dev/null || echo "false")
  fi
fi

python3 - <<'PY' "$DRAFT" "$DOMAIN" "$REQUIRE_ABLATION"
import re, sys

draft_path = sys.argv[1]
domain = sys.argv[2]
require_ablation = sys.argv[3].lower() == "true"

text = open(draft_path, encoding='utf-8', errors='ignore').read()

# 1. Detect lines with numbers but no error indicators
# Look for table cells / paragraph text with numbers but no ± symbol
numeric_lines = re.findall(r'\b\d+\.\d+\b', text)
error_indicators = re.findall(r'\\pm|±|±|\bstd\b|\bs\.e\.\b|\bstd\.?\s+dev\b', text)

# Count quantitative result paragraphs (lines with numbers in results sections)
results_sections = re.search(r'\\section\{[^}]*(?:Results|Experiments|Evaluation)[^}]*\}.*?(?=\\section|$)', text, re.IGNORECASE | re.DOTALL)
results_text = results_sections.group() if results_sections else ""

# Crude detection: numbers in results without ± nearby
# Split into rough "cells" by & (LaTeX table) or \n
lines_with_numbers = re.findall(r'(?:^|\n)[^\n]*(?:\d+\.\d+|\d+%|\d+\s*(?:±|\$\\pm\$))[^\n]*', results_text, re.MULTILINE)
lines_without_errors = [l for l in lines_with_numbers if not re.search(r'±|\\pm|\bstd\b|\bs\.e\.\b', l)]

no_error_count = len(lines_without_errors)

# 2. Cherry-picking signal detection
cherry_signals = re.findall(
    r'(?:best\s+(?:result|performance|accuracy)|'
    r'achieve(?:s|d)?\s+(?:state-of-the-art|the\s+best)|'
    r'outperform(?:s|ed)?\s+all|'
    r'our\s+best\s+(?:model|method))',
    text, re.IGNORECASE
)
cherry_count = len(cherry_signals)

# 3. Ablation check (if required)
ablation_found = bool(re.search(r'\\section\{[^}]*ablation', text, re.IGNORECASE))
ablation_mentioned = bool(re.search(r'\bablation\b', text, re.IGNORECASE))

warnings = []

if no_error_count >= 5:
    warnings.append(f"⚠ {no_error_count} result lines with numbers lack error indicators (mean±std)")

if cherry_count > 0:
    warnings.append(f"⚠ Cherry-picking signals detected ({cherry_count}): {cherry_count} occurrences of 'best result/performance' without full search space disclosure")

if require_ablation and not ablation_found and not ablation_mentioned:
    warnings.append(f"⚠ Ablation study required for {domain} but not found")

if domain == "physics":
    if not re.search(r'(?:systematic|random)\s+error', text, re.IGNORECASE):
        warnings.append("⚠ Physics domain: no systematic/random error distinction found")

if domain == "numerical":
    if not re.search(r'(?:grid|mesh)\s+independen', text, re.IGNORECASE):
        warnings.append("⚠ Numerical domain: no grid independence test found")
    if not re.search(r'convergence\s+(?:order|rate)', text, re.IGNORECASE):
        warnings.append("⚠ Numerical domain: no convergence order reported")

# All warnings are non-blocking (exit 0)
for w in warnings:
    print(w, file=sys.stderr)

PY

exit 0
