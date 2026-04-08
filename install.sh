#!/usr/bin/env bash
# scf installer
set -euo pipefail

TARGET="${TARGET:-$(pwd)}"
JOURNAL="generic"
MAX_REVIEW_ROUNDS="4"
SKIP_ENV_PROBE="false"
SSH_HOST=""
PROJECT_NAME="paper"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    --journal) JOURNAL="$2"; shift 2 ;;
    --max-review-rounds) MAX_REVIEW_ROUNDS="$2"; shift 2 ;;
    --skip-env-probe) SKIP_ENV_PROBE="true"; shift 1 ;;
    --ssh-host) SSH_HOST="$2"; shift 2 ;;
    --project-name) PROJECT_NAME="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

ARC_SRC="$(cd "$(dirname "$0")/src" && pwd)"

mkdir -p "$TARGET"
mkdir -p "$TARGET/.claude/commands" "$TARGET/.claude/agents" "$TARGET/.claude/skills"
mkdir -p "$TARGET/.arc" "$TARGET/docs" "$TARGET/tests/fixtures"

echo "Installing scf → $TARGET (journal: $JOURNAL, max-review-rounds: $MAX_REVIEW_ROUNDS)"

# 1) Copy components
for cmd in paper-run.md paper-status.md paper-resume.md paper-idea-loop.md paper-review-loop.md paper-figure-loop.md paper-citation-loop.md paper-codex-review.md paper-reset.md paper-export.md; do
  cp "$ARC_SRC/commands/$cmd" "$TARGET/.claude/commands/"
done
cp "$ARC_SRC/agents/"*.md "$TARGET/.claude/agents/"
cp -R "$ARC_SRC/skills/"* "$TARGET/.claude/skills/"
mkdir -p "$TARGET/.arc/hooks" "$TARGET/.arc/state" "$TARGET/.arc/memory" "$TARGET/.arc/figures" "$TARGET/.arc/loop-logs"
cp -R "$ARC_SRC/arc/hooks/." "$TARGET/.arc/hooks/"
cp -R "$ARC_SRC/arc/state/." "$TARGET/.arc/state/"
cp -R "$ARC_SRC/arc/memory/." "$TARGET/.arc/memory/"
cp -R "$ARC_SRC/arc/figures/." "$TARGET/.arc/figures/" 2>/dev/null || true
cp -R "$ARC_SRC/arc/loop-logs/." "$TARGET/.arc/loop-logs/" 2>/dev/null || true
cp "$ARC_SRC/arc/env.template.json" "$TARGET/.arc/env.template.json"
cp "$ARC_SRC/arc/env-probe.sh" "$TARGET/.arc/env-probe.sh"
cp "$ARC_SRC/arc/env-validate.sh" "$TARGET/.arc/env-validate.sh"
cp "$ARC_SRC/arc/conda-setup.sh" "$TARGET/.arc/conda-setup.sh"
cp -R "$(cd "$(dirname "$0")" && pwd)/docs/." "$TARGET/docs/"
mkdir -p "$TARGET/tests/fixtures/env" "$TARGET/tests/fixtures/hooks" "$TARGET/tests/fixtures/reviews" "$TARGET/tests/fixtures/state"
cp -R "$(cd "$(dirname "$0")" && pwd)/tests/fixtures/." "$TARGET/tests/fixtures/"

# 2) Render CLAUDE.md with journal placeholder
if [ ! -f "$TARGET/CLAUDE.md" ]; then
  sed "s/__JOURNAL__/$JOURNAL/g" "$ARC_SRC/CLAUDE.md" > "$TARGET/CLAUDE.md"
  echo "  ✓ CLAUDE.md"
else
  echo "  ⚠ CLAUDE.md exists — skipped. Please check __JOURNAL__ manually."
fi

# settings.json
if [ ! -f "$TARGET/.claude/settings.json" ]; then
  cp "$ARC_SRC/claude-settings.json" "$TARGET/.claude/settings.json"
  echo "  ✓ .claude/settings.json"
else
  echo "  ⚠ .claude/settings.json exists — skipped. Please merge hooks manually."
fi

# 3) env probe or template copy
if [ "$SKIP_ENV_PROBE" = "true" ]; then
  cp "$TARGET/.arc/env.template.json" "$TARGET/.arc/env.json"
  echo "  ⚠ skipped env probe; copied .arc/env.template.json -> .arc/env.json"
  echo "  ⚠ please edit .arc/env.json manually then run validate.sh"
else
  PROBE_ARGS=(--target "$TARGET" --project-name "$PROJECT_NAME")
  if [ -n "$SSH_HOST" ]; then
    PROBE_ARGS+=(--ssh-host "$SSH_HOST")
  fi
  if bash "$TARGET/.arc/env-probe.sh" "${PROBE_ARGS[@]}"; then
    echo "  ✓ environment probed"
  else
    echo "  ⚠ environment probe finished with issues (see above)"
  fi
fi

# 4) hooks executable
chmod +x "$TARGET/.arc/hooks/"*.sh
chmod +x "$TARGET/.arc/env-probe.sh" "$TARGET/.arc/env-validate.sh" "$TARGET/.arc/conda-setup.sh"

# 5) append gitignore entries without duplicates
GITIGNORE="$TARGET/.gitignore"
[ -f "$GITIGNORE" ] || touch "$GITIGNORE"
for entry in ".arc/env.json" ".arc/state/" ".arc/loop-logs/" ".arc/memory/"; do
  if ! grep -Fxq "$entry" "$GITIGNORE"; then
    printf '%s\n' "$entry" >> "$GITIGNORE"
  fi
done

# 6) environment summary + codex hint
if [ -f "$TARGET/.arc/env.json" ] && command -v jq >/dev/null 2>&1; then
  MODE="$(jq -r '.compute.mode // "unknown"' "$TARGET/.arc/env.json")"
  ENV_NAME="$(jq -r '.software.conda_env // "unknown"' "$TARGET/.arc/env.json")"
  VALIDATED="$(jq -r '.compute.validated // false' "$TARGET/.arc/env.json")"
  CODEX="$(jq -r '.apis.codex // "missing"' "$TARGET/.arc/env.json")"
  echo ""
  echo "Environment summary"
  echo "  compute.mode: $MODE"
  echo "  conda env:    $ENV_NAME"
  echo "  validated:    $VALIDATED"
  echo "  apis.codex:   $CODEX"
  if [ "$CODEX" != "configured" ]; then
    echo "  ⚠ Codex MCP not configured; /paper:codex-review may degrade to multi-agent-debate"
  fi
fi

echo ""
echo "✅ Done. Run ./validate.sh --target $TARGET"
