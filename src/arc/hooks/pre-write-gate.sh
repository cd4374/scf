#!/usr/bin/env bash
# pre-write-gate.sh — PreToolUse hook
# Blocks reviewer agents from writing to draft.tex

INPUT=$(cat)
FILE=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))" 2>/dev/null || echo "")

if [[ "$FILE" == *"draft.tex" ]]; then
    AGENT=$(python3 -c "
import json, os
try:
    s = json.load(open(os.environ['CLAUDE_PROJECT_DIR']+'/.arc/state/pipeline-status.json'))
    print(s.get('active_agent',''))
except: print('')
" 2>/dev/null)
    REVIEWER_AGENTS="idea-validator literature-reviewer logic-checker stat-auditor figure-auditor final-reviewer"
    if echo "$REVIEWER_AGENTS" | grep -qw "$AGENT"; then
        echo '{"decision":"block","reason":"Reviewer agents cannot write to draft.tex. Write review output to .arc/state/review-*.json instead."}'
        exit 2
    fi
fi
exit 0
