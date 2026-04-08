#!/usr/bin/env bash
# scf uninstaller
set -euo pipefail

TARGET="${TARGET:-$(pwd)}"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

echo "About to remove scf artifacts from: $TARGET"
echo "Will remove:"
echo "  - .claude/commands/paper-*.md"
echo "  - .claude/agents/{idea-validator,novelty-checker,literature-reviewer,logic-checker,stat-auditor,figure-auditor,citation-verifier,peer-reviewer-1,peer-reviewer-2,devils-advocate,multi-agent-debate,final-reviewer}.md"
echo "  - .claude/skills/arc-*/"
echo "  - .arc/"
echo "  - .claude/settings.json (if present)"
read -r -p "Proceed? [y/N] " CONFIRM
if [[ "${CONFIRM:-}" != "y" && "${CONFIRM:-}" != "Y" ]]; then
  echo "Cancelled."
  exit 0
fi

if [ -d "$TARGET/.claude/commands" ]; then
  rm -f "$TARGET/.claude/commands/paper-"*.md 2>/dev/null || true
fi
if [ -d "$TARGET/.claude/agents" ]; then
  rm -f "$TARGET/.claude/agents/"*.md 2>/dev/null || true
fi
if [ -d "$TARGET/.claude/skills" ]; then
  rm -rf "$TARGET/.claude/skills/arc-"* 2>/dev/null || true
fi
rm -f "$TARGET/.claude/settings.json" 2>/dev/null || true
rm -rf "$TARGET/.arc" 2>/dev/null || true

# keep user project files by design
# do not remove CLAUDE.md, draft.tex, references.bib

echo "✅ uninstall complete"
