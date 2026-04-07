#!/usr/bin/env bash
# post-write-section-check.sh — PostToolUse hook
# Verifies required sections exist in draft.tex

INPUT=$(cat)
FILE=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))" 2>/dev/null || echo "")
[[ "$FILE" != *"draft.tex" ]] && exit 0

DRAFT="$CLAUDE_PROJECT_DIR/draft.tex"
[ ! -f "$DRAFT" ] && exit 0

REQUIRED_SECTIONS="Introduction Related.Work Method Experiment Conclusion"
MISSING=""
for section in $REQUIRED_SECTIONS; do
    if ! grep -qi "\\\\section{.*$section" "$DRAFT"; then
        MISSING="$MISSING $section"
    fi
done
if [ -n "$MISSING" ]; then
    echo "⚠️  Missing required sections:$MISSING" >&2
fi
exit 0
