#!/usr/bin/env bash
# scf uninstaller
# Usage: ./uninstall.sh [--target /path/to/paper-project]
set -euo pipefail

TARGET="${TARGET:-$(pwd)}"
while [[ $# -gt 0 ]]; do
    case $1 in
        --target) TARGET="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

echo "Uninstalling scf from $TARGET..."

# Remove .claude/ structure
if [ -d "$TARGET/.claude" ]; then
    rm -rf "$TARGET/.claude/commands"
    rm -rf "$TARGET/.claude/agents"
    rm -rf "$TARGET/.claude/skills"
    rm -f "$TARGET/.claude/settings.json"
    rmdir "$TARGET/.claude" 2>/dev/null || true
    echo "  ✓ Removed .claude/"
fi

# Remove .arc/ runtime
if [ -d "$TARGET/.arc" ]; then
    rm -rf "$TARGET/.arc"
    echo "  ✓ Removed .arc/"
fi

# Remove CLAUDE.md (installed by scf)
if [ -f "$TARGET/CLAUDE.md" ]; then
    # Check if it's an scf installed one (contains scf marker)
    if grep -q "scf" "$TARGET/CLAUDE.md" 2>/dev/null; then
        rm -f "$TARGET/CLAUDE.md"
        echo "  ✓ Removed CLAUDE.md"
    else
        echo "  ⚠ CLAUDE.md exists but not from scf — skipped"
    fi
fi

# Restore .gitignore (remove scf entries)
if [ -f "$TARGET/.gitignore" ]; then
    # Remove scf runtime entries
    sed -i '' '/^# scf runtime$/,/^$/d' "$TARGET/.gitignore" 2>/dev/null || true
    sed -i '' '/^\.arc\/state\/$/d' "$TARGET/.gitignore" 2>/dev/null || true
    sed -i '' '/^\.arc\/figures\/rendered\/$/d' "$TARGET/.gitignore" 2>/dev/null || true
    sed -i '' '/^\.arc\/memory\/$/d' "$TARGET/.gitignore" 2>/dev/null || true
    echo "  ✓ Cleaned .gitignore"
fi

echo ""
echo "✅ Uninstall complete. The paper project is now clean."
