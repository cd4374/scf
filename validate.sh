#!/usr/bin/env bash
# Verify arc-harness installation completeness
set -euo pipefail

TARGET="${TARGET:-$(pwd)}"
while [[ $# -gt 0 ]]; do
    case $1 in --target) TARGET="$2"; shift 2 ;; *) shift ;; esac
done

ERRORS=0
check() {
    if [ -e "$TARGET/$1" ]; then
        echo "  ✓ $1"
    else
        echo "  ✗ MISSING: $1"
        ERRORS=$((ERRORS + 1))
    fi
}
check_exec() {
    if [ -x "$TARGET/$1" ]; then
        echo "  ✓ $1 (executable)"
    else
        echo "  ✗ NOT EXECUTABLE: $1"
        ERRORS=$((ERRORS + 1))
    fi
}

echo "Validating arc-harness installation in $TARGET..."
echo ""
echo "Core files:"
check "CLAUDE.md"
check ".claude/settings.json"

echo "Commands:"
for cmd in paper-run paper-status paper-resume paper-review paper-reset paper-export; do
    check ".claude/commands/$cmd.md"
done

echo "Agents:"
for agent in idea-validator literature-reviewer logic-checker stat-auditor figure-auditor final-reviewer; do
    check ".claude/agents/$agent.md"
done

echo "Skills:"
for skill in arc-pipeline arc-research arc-experiment arc-analysis arc-writing arc-latex-formatting arc-citation-style arc-figure-codegen arc-state-management; do
    check ".claude/skills/$skill/SKILL.md"
done

echo "Hooks (scripts):"
for hook in pre-write-gate post-write-word-count post-write-section-check post-write-figure-check post-write-citation-check post-write-latex-check stop-gate; do
    check_exec ".arc/hooks/$hook.sh"
done

echo "State templates:"
for state in pipeline-status idea review-idea review-literature review-logic review-stat review-figures review-final; do
    check ".arc/state/$state.json"
done

echo ""
if [ "$ERRORS" -eq 0 ]; then
    echo "✅ All checks passed."
else
    echo "❌ $ERRORS missing items. Re-run install.sh or check manually."
    exit 1
fi
