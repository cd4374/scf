#!/usr/bin/env bash
# post-write-latex-check.sh — PostToolUse hook
# Checks LaTeX compilation after draft.tex saves

INPUT=$(cat)
FILE=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))" 2>/dev/null || echo "")
[[ "$FILE" != *"draft.tex" ]] && exit 0

DRAFT="$CLAUDE_PROJECT_DIR/draft.tex"
[ ! -f "$DRAFT" ] && exit 0

# Only check if pdflatex is available
command -v pdflatex >/dev/null 2>&1 || exit 0

cd "$CLAUDE_PROJECT_DIR"
LOG=$(pdflatex -interaction=nonstopmode -halt-on-error draft.tex 2>&1 | tail -20)
if echo "$LOG" | grep -q "! "; then
    echo "⚠️  LaTeX compilation errors detected:" >&2
    echo "$LOG" | grep "! " >&2
fi
exit 0
