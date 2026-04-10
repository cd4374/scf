#!/usr/bin/env bash
# test-quality-gates.sh — Test all quality gate hooks with paper-type.json thresholds
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCF_DIR="$(dirname "$SCRIPT_DIR")"
FIXTURES_PT="$SCRIPT_DIR/fixtures/paper-type"

PASS=0
FAIL=0

# Helper functions
log_pass() { echo "✓ $1"; PASS=$((PASS+1)); }
log_fail() { echo "✗ $1"; FAIL=$((FAIL+1)); }

# JSON extraction helper (fallback to python3 if jq unavailable)
json_get() {
  local json="$1"
  local key="$2"
  if command -v jq >/dev/null 2>&1; then
    jq -r "$key" <<<"$json"
  else
    python3 -c "import json,sys; print(json.loads(sys.stdin.read()).get('$key',''))" <<<"$json"
  fi
}

echo "Testing quality gates with paper-type.json thresholds..."

# Test 1: long ai-experimental → min_references=30, min_figures=5, require_ablation=true
echo ""
echo "=== Test 1: long ai-experimental thresholds ==="
PT_JSON=$(cat "$FIXTURES_PT/long-ai-experimental.json")
MIN_REFS=$(python3 -c "import json; d=json.load(open('$FIXTURES_PT/long-ai-experimental.json')); print(d['derived_thresholds']['min_references'])")
MIN_FIGS=$(python3 -c "import json; d=json.load(open('$FIXTURES_PT/long-ai-experimental.json')); print(d['derived_thresholds']['min_figures'])")
REQ_ABL=$(python3 -c "import json; d=json.load(open('$FIXTURES_PT/long-ai-experimental.json')); print(str(d['derived_thresholds']['require_ablation']).lower())")
if [ "$MIN_REFS" = "30" ] && [ "$MIN_FIGS" = "5" ] && [ "$REQ_ABL" = "true" ]; then
  log_pass "long ai-experimental: min_refs=30, min_figs=5, require_ablation=true"
else
  log_fail "long ai-experimental threshold mismatch"
fi

# Test 2: short ai-experimental → min_references=15, min_figures=3
echo ""
echo "=== Test 2: short ai-experimental thresholds ==="
MIN_REFS=$(python3 -c "import json; d=json.load(open('$FIXTURES_PT/short-ai-experimental.json')); print(d['derived_thresholds']['min_references'])")
MIN_FIGS=$(python3 -c "import json; d=json.load(open('$FIXTURES_PT/short-ai-experimental.json')); print(d['derived_thresholds']['min_figures'])")
REQ_ABL=$(python3 -c "import json; d=json.load(open('$FIXTURES_PT/short-ai-experimental.json')); print(str(d['derived_thresholds']['require_ablation']).lower())")
if [ "$MIN_REFS" = "15" ] && [ "$MIN_FIGS" = "3" ] && [ "$REQ_ABL" = "true" ]; then
  log_pass "short ai-experimental: min_refs=15, min_figs=3, require_ablation=true"
else
  log_fail "short ai-experimental threshold mismatch"
fi

# Test 3: long ai-theoretical → require_ablation=false
echo ""
echo "=== Test 3: long ai-theoretical thresholds ==="
REQ_ABL=$(python3 -c "import json; d=json.load(open('$FIXTURES_PT/long-ai-theoretical.json')); print(str(d['derived_thresholds']['require_ablation']).lower())")
if [ "$REQ_ABL" = "false" ]; then
  log_pass "long ai-theoretical: require_ablation=false"
else
  log_fail "long ai-theoretical require_ablation should be false"
fi

# Test 4: post-write-section-check + require_ablation=true + no Ablation → warning
echo ""
echo "=== Test 4: section-check hook with missing Ablation ==="
# Simulate draft.tex without Ablation section
TMP_DIR=$(mktemp -d)
mkdir -p "$TMP_DIR/.arc/state" "$TMP_DIR/.arc/hooks"
cat "$FIXTURES_PT/long-ai-experimental.json" > "$TMP_DIR/.arc/paper-type.json"
cp "$SCF_DIR/src/arc/hooks/post-write-section-check.sh" "$TMP_DIR/.arc/hooks/"
chmod +x "$TMP_DIR/.arc/hooks/post-write-section-check.sh"
cat > "$TMP_DIR/draft.tex" << 'TEX'
\section{Abstract}
\section{Introduction}
\section{Method}
\section{Experiments}
\section{Conclusion}
TEX
cat > "$TMP_DIR/.arc/state/pipeline-status.json" << 'JSON'
{"stage":"writing","blocking_issues":[]}
JSON
INPUT=$(cat << 'INP'
{"tool_input":{"file_path":"draft.tex"}}
INP
)
export CLAUDE_PROJECT_DIR="$TMP_DIR"
OUTPUT=$(bash "$TMP_DIR/.arc/hooks/post-write-section-check.sh" <<<"$INPUT" 2>&1 || true)
if echo "$OUTPUT" | grep -qi "ablation"; then
  log_pass "section-check warns when Ablation required but missing"
else
  log_fail "section-check should warn about missing Ablation when required"
fi
rm -rf "$TMP_DIR"

# Test 5: post-write-section-check + missing Limitations → warning (all types)
echo ""
echo "=== Test 5: section-check hook with missing Limitations ==="
TMP_DIR=$(mktemp -d)
mkdir -p "$TMP_DIR/.arc/state" "$TMP_DIR/.arc/hooks"
cat "$FIXTURES_PT/long-ai-theoretical.json" > "$TMP_DIR/.arc/paper-type.json"
cp "$SCF_DIR/src/arc/hooks/post-write-section-check.sh" "$TMP_DIR/.arc/hooks/"
chmod +x "$TMP_DIR/.arc/hooks/post-write-section-check.sh"
cat > "$TMP_DIR/draft.tex" << 'TEX'
\section{Abstract}
\section{Introduction}
\section{Method}
\section{Experiments}
\section{Conclusion}
TEX
cat > "$TMP_DIR/.arc/state/pipeline-status.json" << 'JSON'
{"stage":"writing","blocking_issues":[]}
JSON
INPUT=$(cat << 'INP'
{"tool_input":{"file_path":"draft.tex"}}
INP
)
export CLAUDE_PROJECT_DIR="$TMP_DIR"
OUTPUT=$(bash "$TMP_DIR/.arc/hooks/post-write-section-check.sh" <<<"$INPUT" 2>&1 || true)
if echo "$OUTPUT" | grep -qi "limitations"; then
  log_pass "section-check warns when Limitations missing (required for all types)"
else
  log_fail "section-check should warn about missing Limitations"
fi
rm -rf "$TMP_DIR"

# Test 6: post-write-stat-check + numbers without ± → warning (exit 0)
echo ""
echo "=== Test 6: stat-check hook detects numbers without error bars ==="
TMP_DIR=$(mktemp -d)
mkdir -p "$TMP_DIR/.arc/state" "$TMP_DIR/.arc/hooks"
cat "$FIXTURES_PT/long-ai-experimental.json" > "$TMP_DIR/.arc/paper-type.json"
cp "$SCF_DIR/src/arc/hooks/post-write-stat-check.sh" "$TMP_DIR/.arc/hooks/"
chmod +x "$TMP_DIR/.arc/hooks/post-write-stat-check.sh"
cat > "$TMP_DIR/draft.tex" << 'TEX'
\section{Experiments}
Our method achieves 94.5 accuracy.
The baseline scores 85.3.
Model A gets 92.1.
Model B gets 88.7.
The comparison shows 91.2.
All results are averaged over 3 runs.
TEX
INPUT=$(cat << 'INP'
{"tool_input":{"file_path":"draft.tex"}}
INP
)
export CLAUDE_PROJECT_DIR="$TMP_DIR"
EXIT_CODE=0
OUTPUT=$(bash "$TMP_DIR/.arc/hooks/post-write-stat-check.sh" <<<"$INPUT" 2>&1) || EXIT_CODE=$?
if [ "$EXIT_CODE" -eq 0 ] && echo "$OUTPUT" | grep -qi "error"; then
  log_pass "stat-check warns (exit 0) on numbers without error bars"
else
  log_fail "stat-check should warn but not block"
fi
rm -rf "$TMP_DIR"

# Test 7: post-write-figure-check + count < min_figures → warning (exit 0)
echo ""
echo "=== Test 7: figure-check hook with insufficient figures ==="
TMP_DIR=$(mktemp -d)
mkdir -p "$TMP_DIR/.arc/state" "$TMP_DIR/.arc/figures/rendered" "$TMP_DIR/.arc/hooks"
cat "$FIXTURES_PT/long-ai-experimental.json" > "$TMP_DIR/.arc/paper-type.json"
cp "$SCF_DIR/src/arc/hooks/post-write-figure-check.sh" "$TMP_DIR/.arc/hooks/"
chmod +x "$TMP_DIR/.arc/hooks/post-write-figure-check.sh"
cat > "$TMP_DIR/draft.tex" << 'TEX'
\begin{figure}
\includegraphics{fig1.pdf}
\end{figure}
TEX
cat > "$TMP_DIR/.arc/state/pipeline-status.json" << 'JSON'
{"stage":"writing","blocking_issues":[]}
JSON
touch "$TMP_DIR/.arc/figures/rendered/fig1.pdf"
INPUT=$(cat << 'INP'
{"tool_input":{"file_path":"draft.tex"}}
INP
)
export CLAUDE_PROJECT_DIR="$TMP_DIR"
EXIT_CODE=0
OUTPUT=$(bash "$TMP_DIR/.arc/hooks/post-write-figure-check.sh" <<<"$INPUT" 2>&1) || EXIT_CODE=$?
if [ "$EXIT_CODE" -eq 0 ] && echo "$OUTPUT" | grep -qi "Figure count"; then
  log_pass "figure-check warns when count < min_figures (exit 0)"
else
  log_fail "figure-check should warn on insufficient figures"
fi
rm -rf "$TMP_DIR"

# Test 8: post-write-figure-check + missing figure file → block (exit 2)
echo ""
echo "=== Test 8: figure-check hook blocks on missing figure file ==="
TMP_DIR=$(mktemp -d)
mkdir -p "$TMP_DIR/.arc/state" "$TMP_DIR/.arc/figures/rendered" "$TMP_DIR/.arc/hooks"
cat "$FIXTURES_PT/long-ai-experimental.json" > "$TMP_DIR/.arc/paper-type.json"
cp "$SCF_DIR/src/arc/hooks/post-write-figure-check.sh" "$TMP_DIR/.arc/hooks/"
chmod +x "$TMP_DIR/.arc/hooks/post-write-figure-check.sh"
cat > "$TMP_DIR/draft.tex" << 'TEX'
\begin{figure}
\includegraphics{missing_fig.pdf}
\end{figure}
TEX
cat > "$TMP_DIR/.arc/state/pipeline-status.json" << 'JSON'
{"stage":"writing","blocking_issues":[]}
JSON
INPUT=$(cat << 'INP'
{"tool_input":{"file_path":"draft.tex"}}
INP
)
export CLAUDE_PROJECT_DIR="$TMP_DIR"
EXIT_CODE=0
OUTPUT=$(bash "$TMP_DIR/.arc/hooks/post-write-figure-check.sh" <<<"$INPUT" 2>&1) || EXIT_CODE=$?
if [ "$EXIT_CODE" -eq 2 ] && echo "$OUTPUT" | grep -q '"decision":"block"\|"decision": "block"'; then
  log_pass "figure-check blocks (exit 2) with block JSON when referenced figure is missing"
else
  log_fail "figure-check should block on missing referenced figure"
fi
rm -rf "$TMP_DIR"

# Test 9: stop-gate + review-integrity.json pass=false → block
echo ""
echo "=== Test 9: stop-gate blocks on review-integrity pass=false ==="
TMP_DIR=$(mktemp -d)
mkdir -p "$TMP_DIR/.arc/state" "$TMP_DIR/.arc/hooks"
cat "$FIXTURES_PT/long-ai-experimental.json" > "$TMP_DIR/.arc/paper-type.json"
cp "$SCF_DIR/src/arc/hooks/stop-gate.sh" "$TMP_DIR/.arc/hooks/"
chmod +x "$TMP_DIR/.arc/hooks/stop-gate.sh"
cat "$SCRIPT_DIR/fixtures/reviews/review-final-fail.json" > "$TMP_DIR/.arc/state/review-final.json"
cat "$SCRIPT_DIR/fixtures/reviews/review-integrity-fail.json" > "$TMP_DIR/.arc/state/review-integrity.json"
cat > "$TMP_DIR/.arc/state/review-stat.json" << 'JSON'
{"pass":true}
JSON
cat > "$TMP_DIR/.arc/state/pipeline-status.json" << 'JSON'
{"stage":"final-review","figure_count":5}
JSON
cat > "$TMP_DIR/draft.tex" << 'TEX'
\section{Abstract}
\section{Introduction}
\section{Method}
\section{Experiments}
\section{Conclusion}
\includegraphics{f1.pdf}
\includegraphics{f2.pdf}
\includegraphics{f3.pdf}
\includegraphics{f4.pdf}
\includegraphics{f5.pdf}
TEX
cat > "$TMP_DIR/.arc/env.json" << 'JSON'
{"compute":{"validated":true,"mode":"local"}}
JSON
INPUT=""
export CLAUDE_PROJECT_DIR="$TMP_DIR"
EXIT_CODE=0
bash "$TMP_DIR/.arc/hooks/stop-gate.sh" <<<"$INPUT" 2>&1 || EXIT_CODE=$?
if [ "$EXIT_CODE" -eq 2 ]; then
  log_pass "stop-gate blocks (exit 2) when review-integrity pass=false"
else
  log_fail "stop-gate should block on integrity failure"
fi
rm -rf "$TMP_DIR"

# Summary
echo ""
echo "================================"
echo "Quality gates test summary"
echo "PASS: $PASS"
echo "FAIL: $FAIL"
if [ "$FAIL" -gt 0 ]; then
  echo "FAIL"
  exit 1
fi
echo "PASS"