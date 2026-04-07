#!/usr/bin/env bash
# post-write-citation-check.sh — PostToolUse hook
# Validates bib entries have required fields

INPUT=$(cat)
FILE=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))" 2>/dev/null || echo "")
[[ "$FILE" != *".bib" ]] && exit 0

BIB="$FILE"
[ ! -f "$BIB" ] && exit 0

python3 -c "
import re, sys
content = open('$BIB').read()
entries = re.findall(r'@\w+\{([^,]+),(.*?)\n\}', content, re.DOTALL)
issues = []
for key, body in entries:
    for field in ['author', 'title', 'year']:
        if field not in body.lower():
            issues.append(f'  @{key.strip()}: missing {field}')
if issues:
    print('⚠️  Citation issues:', file=__import__('sys').stderr)
    for i in issues: print(i, file=__import__('sys').stderr)
" 2>& >&2 || true
exit 0
