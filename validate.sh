#!/usr/bin/env bash
# Verify scf installation completeness
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

# 1) file integrity
check "CLAUDE.md"
check ".claude/settings.json"
for doc in architecture pipeline-states auto-loop-design cross-model-review citation-verification environment-setup ssh-gpu-guide adding-skills adding-agents hook-contracts; do
  check "docs/$doc.md"
done
for cmd in paper-run paper-status paper-resume paper-idea-loop paper-review-loop paper-figure-loop paper-citation-loop paper-codex-review paper-reset paper-export; do
  check ".claude/commands/$cmd.md"
done
if [ -f "$TARGET/.claude/commands/paper-review.md" ]; then
  echo "✗ FORBIDDEN: .claude/commands/paper-review.md"
  ERRORS=$((ERRORS + 1))
fi
for agent in idea-validator novelty-checker literature-reviewer logic-checker stat-auditor figure-auditor citation-verifier peer-reviewer-1 peer-reviewer-2 devils-advocate multi-agent-debate final-reviewer; do
  check ".claude/agents/$agent.md"
done
for skill in arc-pipeline arc-idea-exploration arc-research arc-experiment arc-analysis arc-writing arc-latex-formatting arc-citation-style arc-figure-codegen arc-state-management arc-reproducibility; do
  check ".claude/skills/$skill/SKILL.md"
done
for state in pipeline-status idea reproducibility review-idea review-novelty review-literature review-logic review-stat review-figures review-citations review-peer-1 review-peer-2 review-devil review-debate review-codex review-final; do
  check ".arc/state/$state.json"
done
for fixture in tests/fixtures/env/env-local-cuda.json tests/fixtures/env/env-local-mps.json tests/fixtures/env/env-ssh-gpu.json tests/fixtures/env/env-cpu-only.json tests/fixtures/reviews/review-score-90.json tests/fixtures/reviews/review-score-75.json tests/fixtures/reviews/review-score-50.json tests/fixtures/reviews/review-score-declining.json tests/fixtures/reviews/citation-hallucinated.json tests/fixtures/reviews/figure-score-6.json tests/fixtures/state/pipeline-complete.json tests/fixtures/state/pipeline-partial.json tests/fixtures/state/review-final-fail.json; do
  check "$fixture"
done

# 2) executable checks
for hook in pre-write-gate post-write-word-count post-write-section-check post-write-figure-check post-write-citation-check post-write-latex-check post-write-ai-pattern-check loop-progress-log stop-gate; do
  check_exec ".arc/hooks/$hook.sh"
done
check_exec ".arc/env-probe.sh"
check_exec ".arc/env-validate.sh"
check_exec ".arc/conda-setup.sh"

# 3) JSON validity
for jf in "$TARGET/.claude/settings.json" "$TARGET/.arc/state/pipeline-status.json" "$TARGET/.arc/state/idea.json" "$TARGET/.arc/state/reproducibility.json" "$TARGET/.arc/state/review-final.json" "$TARGET/.arc/env.json"; do
  if [ -f "$jf" ]; then
    if python3 -m json.tool "$jf" >/dev/null 2>&1; then
      echo "✓ JSON valid: ${jf#$TARGET/}"
    else
      echo "✗ INVALID JSON: ${jf#$TARGET/}"
      ERRORS=$((ERRORS + 1))
    fi
  fi
done

# 4) loop MAX_ITER statements and CLAUDE defaults
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
for s in "idea_loop MAX_ITER=3" "review_loop MAX_ITER=4" "figure_loop MAX_ITER=5" "citation_loop MAX_ITER=3"; do
  if grep -q "$s" "$TARGET/CLAUDE.md"; then
    echo "✓ CLAUDE.md has $s"
  else
    echo "✗ CLAUDE.md missing $s"
    ERRORS=$((ERRORS + 1))
  fi
done
if grep -q "## GPU Environment" "$TARGET/CLAUDE.md"; then
  echo "✗ CLAUDE.md contains forbidden GPU Environment section"
  ERRORS=$((ERRORS + 1))
fi

# 5) env validation
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

# 6) summary
if [ -f "$TARGET/.arc/env.json" ] && command -v jq >/dev/null 2>&1 && jq empty "$TARGET/.arc/env.json" >/dev/null 2>&1; then
  echo "Environment summary"
  echo "  compute.mode: $(jq -r '.compute.mode // "unknown"' "$TARGET/.arc/env.json")"
  echo "  conda env:    $(jq -r '.software.conda_env // "unknown"' "$TARGET/.arc/env.json")"
  echo "  validated:    $(jq -r '.compute.validated // false' "$TARGET/.arc/env.json")"
  echo "  apis: semantic_scholar=$(jq -r '.apis.semantic_scholar // "missing"' "$TARGET/.arc/env.json"), codex=$(jq -r '.apis.codex // "missing"' "$TARGET/.arc/env.json")"
fi

echo "Result: WARN=$WARNS ERROR=$ERRORS"
if [ "$ERRORS" -eq 0 ]; then
  echo "PASS"
else
  echo "FAIL"
  exit 1
fi
