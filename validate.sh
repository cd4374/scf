#!/usr/bin/env bash
# Verify scf installation completeness (v5)
set -euo pipefail

TARGET="${TARGET:-$(pwd)}"
FULL_ENV_CHECK="false"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    --full-env-check) FULL_ENV_CHECK="true"; shift 1 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

ERRORS=0
WARNS=0

check() {
  if [ -e "$TARGET/$1" ]; then
    echo "✓ $1"
  else
    echo "✗ MISSING: $1"
    ERRORS=$((ERRORS + 1))
  fi
}

check_exec() {
  if [ -x "$TARGET/$1" ]; then
    echo "✓ $1 (executable)"
  else
    echo "✗ NOT EXECUTABLE: $1"
    ERRORS=$((ERRORS + 1))
  fi
}

# 1) file integrity (v5 updated)
check "LICENSE"
for doc in architecture pipeline-states auto-loop-design cross-model-review citation-verification environment-setup ssh-gpu-guide adding-skills adding-agents hook-contracts quality-standards paper-type-guide; do
  check "docs/$doc.md"
done
# 11 commands (v5: paper-init added)
for cmd in paper-init paper-run paper-status paper-resume paper-idea-loop paper-review-loop paper-figure-loop paper-citation-loop paper-codex-review paper-reset paper-export; do
  check ".claude/commands/$cmd.md"
done
if [ -f "$TARGET/.claude/commands/paper-review.md" ]; then
  echo "✗ FORBIDDEN: .claude/commands/paper-review.md"
  ERRORS=$((ERRORS + 1))
fi
# 13 agents (v5: integrity-checker added)
for agent in idea-validator novelty-checker literature-reviewer logic-checker stat-auditor figure-auditor citation-verifier integrity-checker peer-reviewer-1 peer-reviewer-2 devils-advocate multi-agent-debate final-reviewer; do
  check ".claude/agents/$agent.md"
done
# 12 skills (v5: arc-statistics added)
for skill in arc-pipeline arc-idea-exploration arc-research arc-experiment arc-statistics arc-analysis arc-writing arc-latex-formatting arc-citation-style arc-figure-codegen arc-state-management arc-reproducibility; do
  check ".claude/skills/$skill/SKILL.md"
done
# state files (v5: review-integrity.json added)
for state in pipeline-status idea reproducibility review-idea review-novelty review-literature review-logic review-stat review-figures review-citations review-peer-1 review-peer-2 review-devil review-debate review-codex review-final review-integrity; do
  check ".arc/state/$state.json"
done
# fixtures
for fixture in \
  tests/fixtures/env/env-local-cuda.json \
  tests/fixtures/env/env-local-mps.json \
  tests/fixtures/env/env-ssh-gpu.json \
  tests/fixtures/env/env-cpu-only.json \
  tests/fixtures/reviews/review-score-90.json \
  tests/fixtures/reviews/review-score-75.json \
  tests/fixtures/reviews/review-score-50.json \
  tests/fixtures/reviews/review-score-declining.json \
  tests/fixtures/reviews/citation-hallucinated.json \
  tests/fixtures/reviews/figure-score-6.json \
  tests/fixtures/reviews/review-integrity-pass.json \
  tests/fixtures/reviews/review-integrity-fail.json \
  tests/fixtures/reviews/review-stat-missing-error-bars.json \
  tests/fixtures/state/pipeline-complete.json \
  tests/fixtures/state/pipeline-partial.json \
  tests/fixtures/state/review-final-fail.json \
  tests/fixtures/paper-type/long-ai-experimental.json \
  tests/fixtures/paper-type/short-ai-experimental.json \
  tests/fixtures/paper-type/long-ai-theoretical.json \
  tests/fixtures/paper-type/long-numerical.json \
  tests/fixtures/hooks/draft-write.json \
  tests/fixtures/hooks/non-draft-write.json; do
  check "$fixture"
done

# 2) executable checks (v5: 12 hooks)
for hook in pre-write-gate post-write-page-count post-write-section-check post-write-figure-check post-write-table-check post-write-citation-check post-write-stat-check post-write-latex-check post-write-ai-pattern-check loop-progress-log pre-experiment-gate stop-gate; do
  check_exec ".arc/hooks/$hook.sh"
done
check_exec ".arc/env-probe.sh"
check_exec ".arc/env-validate.sh"
check_exec ".arc/conda-setup.sh"

# 3) JSON validity
for jf in "$TARGET/.claude/settings.json" \
          "$TARGET/.arc/state/pipeline-status.json" \
          "$TARGET/.arc/state/idea.json" \
          "$TARGET/.arc/state/reproducibility.json" \
          "$TARGET/.arc/state/review-final.json" \
          "$TARGET/.arc/state/review-integrity.json" \
          "$TARGET/.arc/env.json" \
          "$TARGET/.arc/paper-type.json" \
          "$TARGET/.arc/paper-type.template.json"; do
  if [ -f "$jf" ]; then
    if python3 -m json.tool "$jf" >/dev/null 2>&1; then
      echo "✓ JSON valid: ${jf#$TARGET/}"
    else
      echo "✗ INVALID JSON: ${jf#$TARGET/}"
      ERRORS=$((ERRORS + 1))
    fi
  fi
done

# 4) paper-type.json derived_thresholds filled
if [ -f "$TARGET/.arc/paper-type.json" ]; then
  if command -v jq >/dev/null 2>&1; then
    MR=$(jq -r '.derived_thresholds.min_references // 0' "$TARGET/.arc/paper-type.json")
    MF=$(jq -r '.derived_thresholds.min_figures // 0' "$TARGET/.arc/paper-type.json")
    RA=$(jq -r '.derived_thresholds.require_ablation // null' "$TARGET/.arc/paper-type.json")
  else
    MR=$(python3 -c "import json; d=json.load(open('$TARGET/.arc/paper-type.json')); print(d.get('derived_thresholds',{}).get('min_references',0))" 2>/dev/null || echo "0")
    MF=$(python3 -c "import json; d=json.load(open('$TARGET/.arc/paper-type.json')); print(d.get('derived_thresholds',{}).get('min_figures',0))" 2>/dev/null || echo "0")
    RA=$(python3 -c "import json; d=json.load(open('$TARGET/.arc/paper-type.json')); print(d.get('derived_thresholds',{}).get('require_ablation',None))" 2>/dev/null || echo "None")
  fi
  if [ "$MR" -gt 0 ] && [ "$MF" -gt 0 ] && [ "$RA" != "null" ] && [ "$RA" != "None" ]; then
    echo "✓ paper-type.json derived_thresholds filled"
  else
    echo "✗ paper-type.json derived_thresholds not properly filled"
    ERRORS=$((ERRORS + 1))
  fi
else
  echo "✗ MISSING: .arc/paper-type.json"
  ERRORS=$((ERRORS + 1))
fi

# 5) deprecated artifact checks (v5)
if grep -Rqs "post-write-word-count.sh" "$TARGET/.claude" "$TARGET/docs" "$TARGET/tests" 2>/dev/null; then
  echo "✗ Deprecated hook reference found: post-write-word-count.sh"
  ERRORS=$((ERRORS + 1))
fi
if grep -Rqs "\bword_count\b\|word_count_ok" "$TARGET/.arc/state" "$TARGET/tests/fixtures/state" 2>/dev/null; then
  echo "⚠ Deprecated word_count fields found in state files/fixtures"
  WARNS=$((WARNS + 1))
fi

# 6) loop MAX_ITER statements (v5 updated)
for pair in "paper-idea-loop.md:MAX_ITER=3" "paper-review-loop.md:MAX_ITER=4" "paper-figure-loop.md:MAX_ITER=5" "paper-citation-loop.md:MAX_ITER=3"; do
  f="${pair%%:*}"
  s="${pair##*:}"
  if [ -f "$TARGET/.claude/commands/$f" ] && grep -q "$s" "$TARGET/.claude/commands/$f"; then
    echo "✓ loop setting: $f has $s"
  else
    echo "✗ loop setting mismatch: $f missing $s"
    ERRORS=$((ERRORS + 1))
  fi
done

# 7) CLAUDE.md checks (v5)
if [ -f "$TARGET/CLAUDE.md" ]; then
  if grep -q "## GPU Environment" "$TARGET/CLAUDE.md"; then
    echo "✗ CLAUDE.md contains forbidden GPU Environment section"
    ERRORS=$((ERRORS + 1))
  else
    echo "✓ CLAUDE.md: no GPU Environment section"
  fi
  if grep -q "paper-type" "$TARGET/CLAUDE.md"; then
    echo "✓ CLAUDE.md: contains paper-type reference"
  else
    echo "⚠ CLAUDE.md: no paper-type reference (should point to .arc/paper-type.json)"
    WARNS=$((WARNS + 1))
  fi
fi

# 8) hooks read paper-type.json via jq (not hardcoded thresholds)
echo ""
echo "Checking hooks use jq for paper-type.json thresholds..."
for hook in post-write-section-check post-write-figure-check post-write-table-check post-write-stat-check stop-gate; do
  f="$TARGET/.arc/hooks/${hook}.sh"
  if [ -f "$f" ]; then
    if grep -q "paper-type.json" "$f" && grep -q "jq " "$f"; then
      echo "  ✓ ${hook}.sh reads paper-type.json via jq"
    else
      echo "  ⚠ ${hook}.sh may hardcode thresholds (should use jq to read paper-type.json)"
      WARNS=$((WARNS + 1))
    fi
  fi
done

# 9) env validation
if [ -x "$TARGET/.arc/env-validate.sh" ]; then
  if [ "$FULL_ENV_CHECK" = "true" ]; then
    if ! bash "$TARGET/.arc/env-validate.sh" --target "$TARGET" --connectivity; then
      ERRORS=$((ERRORS + 1))
    fi
  else
    if ! bash "$TARGET/.arc/env-validate.sh" --target "$TARGET"; then
      ERRORS=$((ERRORS + 1))
    fi
  fi
else
  echo "✗ MISSING: .arc/env-validate.sh"
  ERRORS=$((ERRORS + 1))
fi

# 10) quality gates test
if [ -x "$TARGET/tests/test-quality-gates.sh" ]; then
  echo ""
  echo "Running quality gates tests..."
  if bash "$TARGET/tests/test-quality-gates.sh" >/dev/null 2>&1; then
    echo "✓ quality gates tests PASS"
  else
    echo "⚠ quality gates tests had failures"
    WARNS=$((WARNS + 1))
  fi
fi

# 11) summary
if [ -f "$TARGET/.arc/env.json" ] && command -v jq >/dev/null 2>&1; then
  echo ""
  echo "Environment summary"
  echo "  compute.mode: $(jq -r '.compute.mode // "unknown"' "$TARGET/.arc/env.json")"
  echo "  conda env:    $(jq -r '.software.conda_env // "unknown"' "$TARGET/.arc/env.json")"
  echo "  validated:    $(jq -r '.compute.validated // false' "$TARGET/.arc/env.json")"
  echo "  apis: semantic_scholar=$(jq -r '.apis.semantic_scholar // "missing"' "$TARGET/.arc/env.json"), codex=$(jq -r '.apis.codex // "missing"' "$TARGET/.arc/env.json")"
fi

echo ""
echo "Result: WARN=$WARNS ERROR=$ERRORS"
if [ "$ERRORS" -eq 0 ]; then
  echo "PASS"
else
  echo "FAIL"
  exit 1
fi
