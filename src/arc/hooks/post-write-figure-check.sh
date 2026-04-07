#!/usr/bin/env bash
# post-write-figure-check.sh — PostToolUse hook
# Verifies referenced figures exist as files

INPUT=$(cat)
FILE=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))" 2>/dev/null || echo "")
[[ "$FILE" != *"draft.tex" ]] && exit 0

DRAFT="$CLAUDE_PROJECT_DIR/draft.tex"
FIGURES_DIR="$CLAUDE_PROJECT_DIR/.arc/figures/rendered"
[ ! -f "$DRAFT" ] && exit 0

MISSING_FIGS=""
while IFS= read -r fig; do
    fig=$(echo "$fig" | sed 's/.*{\(.*\)}.*/\1/')
    if [ ! -f "$FIGURES_DIR/$fig.pdf" ] && [ ! -f "$FIGURES_DIR/$fig.png" ] && [ ! -f "$fig.pdf" ] && [ ! -f "$fig.png" ]; then
        MISSING_FIGS="$MISSING_FIGS\n  $fig"
    fi
done < <(grep -o '\\includegraphics[^{]*{[^}]*}' "$DRAFT" 2>/dev/null)

if [ -n "$MISSING_FIGS" ]; then
    echo -e "⚠️  Referenced figures not found as files:$MISSING_FIGS\nGenerate them with arc-figure-codegen skill." >&2
fi
exit 0
