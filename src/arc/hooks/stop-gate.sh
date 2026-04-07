#!/usr/bin/env bash
# stop-gate.sh — Stop event hook
# Final pipeline validation before stopping

STATE="$CLAUDE_PROJECT_DIR/.arc/state"
ERRORS=""

# Check final-review passes
if [ -f "$STATE/review-final.json" ]; then
    PASS=$(python3 -c "import json; print(json.load(open('$STATE/review-final.json')).get('pass', False))" 2>/dev/null || echo "False")
    if [ "$PASS" != "True" ]; then
        ERRORS="$ERRORS\n  Final review has not passed"
    fi
fi

# Check minimum word count
if [ -f "$STATE/pipeline-status.json" ]; then
    WC_OK=$(python3 -c "import json; print(json.load(open('$STATE/pipeline-status.json')).get('word_count_ok', False))" 2>/dev/null || echo "False")
    if [ "$WC_OK" != "True" ]; then
        WC=$(python3 -c "import json; print(json.load(open('$STATE/pipeline-status.json')).get('word_count', 0))" 2>/dev/null || echo "0")
        ERRORS="$ERRORS\n  Word count insufficient: $WC / 6000"
    fi
fi

if [ -n "$ERRORS" ]; then
    echo -e "⛔ Pipeline not complete. Blocking issues:$ERRORS" >&2
    echo "Run /paper:status for full details." >&2
fi
exit 0
