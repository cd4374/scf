#!/usr/bin/env bash
set -euo pipefail
HOOKS="$(cd "$(dirname "$0")/../src/arc/hooks" && pwd)"
FIXTURES="$(cd "$(dirname "$0")/fixtures" && pwd)"
TMP=$(mktemp -d)
export CLAUDE_PROJECT_DIR="$TMP"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/.arc/state" "$TMP/.arc/figures/rendered"

run_hook() {
  local hook="$1" fixture="$2" expected="$3"
  local code
  code=$(bash "$HOOKS/$hook" < "$FIXTURES/hooks/$fixture" >/tmp/hook.out 2>/tmp/hook.err; echo $?)
  if [ "$code" = "$expected" ]; then
    echo "✓ $hook exit=$code"
  else
    echo "✗ $hook expected $expected got $code"
    echo "stdout:"; cat /tmp/hook.out || true
    echo "stderr:"; cat /tmp/hook.err || true
    exit 1
  fi
}

# pre-write-gate blocks reviewer writing draft.tex
printf '{"active_agent":"idea-validator"}\n' > "$TMP/.arc/state/pipeline-status.json"
run_hook pre-write-gate.sh draft-write.json 2

# post-write hooks skip non-draft targets
run_hook post-write-page-count.sh non-draft-write.json 0
run_hook post-write-section-check.sh non-draft-write.json 0
run_hook post-write-figure-check.sh non-draft-write.json 0
run_hook post-write-table-check.sh non-draft-write.json 0
run_hook post-write-citation-check.sh non-draft-write.json 0
run_hook post-write-stat-check.sh non-draft-write.json 0
run_hook post-write-latex-check.sh non-draft-write.json 0
run_hook post-write-ai-pattern-check.sh non-draft-write.json 0
run_hook loop-progress-log.sh non-draft-write.json 0

# stop-gate pass path (no blocking)
cat > "$TMP/.arc/state/review-final.json" <<'EOF'
{"pass": true}
EOF
cat > "$TMP/.arc/state/review-integrity.json" <<'EOF'
{"pass": true}
EOF
cat > "$TMP/.arc/state/review-stat.json" <<'EOF'
{"pass": true}
EOF
cat > "$TMP/.arc/state/pipeline-status.json" <<'EOF'
{"page_count": 8}
EOF
cat > "$TMP/.arc/paper-type.json" <<'EOF'
{"page_limit":9,"derived_thresholds":{"min_references":1,"min_figures":1,"min_recent_refs_pct":0}}
EOF
cat > "$TMP/.arc/env.json" <<'EOF'
{"compute":{"validated":true,"mode":"cpu"},"active_experiments":[]}
EOF
cat > "$TMP/draft.tex" <<'EOF'
\includegraphics{fig1.pdf}
EOF
touch "$TMP/fig1.pdf"
cat > "$TMP/references.bib" <<'EOF'
@article{a1,
  author = {Doe, Jane},
  title = {Test Paper},
  year = {2026},
  journal = {Test Journal}
}
EOF
run_hook stop-gate.sh non-draft-write.json 0

# stop-gate block path (missing final pass)
cat > "$TMP/.arc/state/review-final.json" <<'EOF'
{"pass": false}
EOF
run_hook stop-gate.sh non-draft-write.json 2

# stop-gate block path (integrity fail)
cat > "$TMP/.arc/state/review-final.json" <<'EOF'
{"pass": true}
EOF
cat > "$TMP/.arc/state/review-integrity.json" <<'EOF'
{"pass": false}
EOF
run_hook stop-gate.sh non-draft-write.json 2
if ! grep -q '"decision": "block"\|"decision":"block"' /tmp/hook.out; then
  echo "✗ stop-gate did not output block decision JSON"
  cat /tmp/hook.out || true
  exit 1
fi

echo "✅ hooks test passed"
