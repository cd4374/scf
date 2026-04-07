#!/usr/bin/env bash
# arc-harness installer
# Usage: ./install.sh [--target /path/to/paper-project] [--journal neurips]
set -euo pipefail

TARGET="${TARGET:-$(pwd)}"
JOURNAL="generic"
while [[ $# -gt 0 ]]; do
    case $1 in
        --target) TARGET="$2"; shift 2 ;;
        --journal) JOURNAL="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

ARC_SRC="$(cd "$(dirname "$0")/src" && pwd)"
echo "Installing arc-harness → $TARGET (journal: $JOURNAL)"

# CLAUDE.md
if [ ! -f "$TARGET/CLAUDE.md" ]; then
    sed "s/__JOURNAL__/$JOURNAL/g" "$ARC_SRC/CLAUDE.md" > "$TARGET/CLAUDE.md"
    echo "  ✓ CLAUDE.md"
else
    echo "  ⚠ CLAUDE.md exists — skipped. Manually merge src/CLAUDE.md if needed."
fi

# .claude/ structure
mkdir -p "$TARGET/.claude/commands" "$TARGET/.claude/agents" "$TARGET/.claude/skills"

cp "$ARC_SRC/commands/"*.md "$TARGET/.claude/commands/"
echo "  ✓ commands ($(ls "$ARC_SRC/commands/"*.md | wc -l | tr -d ' '))"

cp "$ARC_SRC/agents/"*.md "$TARGET/.claude/agents/"
echo "  ✓ agents ($(ls "$ARC_SRC/agents/"*.md | wc -l | tr -d ' '))"

cp -r "$ARC_SRC/skills/"* "$TARGET/.claude/skills/"
echo "  ✓ skills ($(ls "$ARC_SRC/skills/" | wc -l | tr -d ' '))"

# settings.json
if [ ! -f "$TARGET/.claude/settings.json" ]; then
    cp "$ARC_SRC/claude-settings.json" "$TARGET/.claude/settings.json"
    echo "  ✓ .claude/settings.json"
else
    echo "  ⚠ .claude/settings.json exists — skipped. Manually merge hooks."
fi

# .arc/ runtime
cp -r "$ARC_SRC/arc/" "$TARGET/.arc/"
chmod +x "$TARGET/.arc/hooks/"*.sh
echo "  ✓ .arc/ runtime directory"

# .gitignore
GITIGNORE="$TARGET/.gitignore"
if [ -f "$GITIGNORE" ] && ! grep -q "^\.arc/state" "$GITIGNORE" 2>/dev/null; then
    printf '\n# arc-harness runtime\n.arc/state/\n.arc/figures/rendered/\n.arc/memory/\n' >> "$GITIGNORE"
    echo "  ✓ .gitignore updated"
fi

echo ""
echo "✅ Done. Run ./validate.sh --target $TARGET to verify."
echo "   Then: cd $TARGET && claude"
echo "   In Claude Code: /paper:run --idea \"your research question\" --journal $JOURNAL"
