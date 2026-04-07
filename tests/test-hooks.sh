#!/usr/bin/env bash
# test-hooks.sh — Test hook scripts with mock JSON input
set -euo pipefail
HOOKS="$(cd "$(dirname "$0")/../src/arc/hooks" && pwd)"
FIXTURES="$(cd "$(dirname "$0")/fixtures" && pwd)"
TMP=$(mktemp -d)
export CLAUDE_PROJECT_DIR="$TMP"
PASS=0; FAIL=0

# Create minimal state structure
mkdir -p "$TMP/.arc/state"
mkdir -p "$TMP/.arc/figures/rendered"
echo '{}' > "$TMP/.arc/state/pipeline-status.json"

run_hook() {
    local hook="$1" fixture="$2" expected_exit="$3"
    local result
    result=$("$HOOKS/$hook" < "$FIXTURES/hooks/$fixture" 2>/dev/null; echo $?)
    local exit_code="${result##*$'\n'}"
    if [ "$exit_code" -eq "$expected_exit" ]; then
        echo "  ✓ $hook ($fixture)"
        PASS=$((PASS+1))
    else
        echo "  ✗ $hook ($fixture): expected exit $expected_exit, got $exit_code"
        FAIL=$((FAIL+1))
    fi
}

echo "Testing hooks..."
run_hook "post-write-word-count.sh" "non-draft-write.json" 0
run_hook "post-write-section-check.sh" "non-draft-write.json" 0
run_hook "post-write-figure-check.sh" "non-draft-write.json" 0
run_hook "post-write-citation-check.sh" "non-draft-write.json" 0
run_hook "post-write-latex-check.sh" "non-draft-write.json" 0

rm -rf "$TMP"
echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
