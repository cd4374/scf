#!/usr/bin/env bash
# post-write-word-count.sh — PostToolUse hook
# Tracks word count after draft.tex modifications

INPUT=$(cat)
FILE=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))" 2>/dev/null || echo "")
[[ "$FILE" != *"draft.tex" ]] && exit 0

DRAFT="$CLAUDE_PROJECT_DIR/draft.tex"
[ ! -f "$DRAFT" ] && exit 0

WORD_COUNT=$(grep -v '^\s*%' "$DRAFT" | sed 's/\\[a-zA-Z]*\*\?//g; s/[{}]//g' | wc -w | tr -d ' ')
MIN_WORDS=6000

python3 -c "
import json, os
f = os.environ['CLAUDE_PROJECT_DIR']+'/.arc/state/pipeline-status.json'
try: s = json.load(open(f))
except: s = {}
s['word_count'] = $WORD_COUNT
s['word_count_ok'] = $WORD_COUNT >= $MIN_WORDS
open(f,'w').write(json.dumps(s, indent=2))
" 2>/dev/null

if [ "$WORD_COUNT" -lt "$MIN_WORDS" ]; then
    echo "⚠️  Word count: $WORD_COUNT / $MIN_WORDS minimum. Keep writing." >&2
fi
exit 0
