#!/usr/bin/env bash
# scf installer
set -euo pipefail

TARGET="${TARGET:-$(pwd)}"
JOURNAL="generic"
FORMAT="long"
DOMAIN="ai-experimental"
MAX_REVIEW_ROUNDS="4"
SKIP_ENV_PROBE="false"
SSH_HOST=""
PROJECT_NAME="paper"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    --journal|--venue) JOURNAL="$2"; shift 2 ;;
    --format) FORMAT="$2"; shift 2 ;;
    --domain) DOMAIN="$2"; shift 2 ;;
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

SCF_ROOT="$(cd "$(dirname "$0")" && pwd)"

echo "Installing scf → $TARGET (journal: $JOURNAL, format: $FORMAT, domain: $DOMAIN)"

# 1) Copy components
cp "$SCF_ROOT/README.md" "$TARGET/README.md"
cp "$SCF_ROOT/LICENSE" "$TARGET/LICENSE"
cp "$SCF_ROOT/install.sh" "$TARGET/install.sh"
cp "$SCF_ROOT/uninstall.sh" "$TARGET/uninstall.sh"
cp "$SCF_ROOT/validate.sh" "$TARGET/validate.sh"
cp "$SCF_ROOT/manifest.json" "$TARGET/manifest.json"
for cmd in paper-init paper-run paper-status paper-resume paper-idea-loop paper-review-loop paper-figure-loop paper-citation-loop paper-codex-review paper-reset paper-export; do
  cp "$ARC_SRC/commands/$cmd.md" "$TARGET/.claude/commands/"
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
cp "$ARC_SRC/arc/paper-type.template.json" "$TARGET/.arc/paper-type.template.json"
cp "$ARC_SRC/arc/env-probe.sh" "$TARGET/.arc/env-probe.sh"
cp "$ARC_SRC/arc/env-validate.sh" "$TARGET/.arc/env-validate.sh"
cp "$ARC_SRC/arc/conda-setup.sh" "$TARGET/.arc/conda-setup.sh"
mkdir -p "$TARGET/docs"
cp -R "$SCF_ROOT/docs/." "$TARGET/docs/"
mkdir -p "$TARGET/tests/fixtures/env" "$TARGET/tests/fixtures/hooks" "$TARGET/tests/fixtures/reviews" "$TARGET/tests/fixtures/state" "$TARGET/tests/fixtures/paper-type"
cp -R "$SCF_ROOT/tests/fixtures/." "$TARGET/tests/fixtures/"

# 2) Render CLAUDE.md with journal placeholder
if [ ! -f "$TARGET/CLAUDE.md" ]; then
  sed "s/__JOURNAL__/$JOURNAL/g" "$ARC_SRC/CLAUDE.md" > "$TARGET/CLAUDE.md"
  echo "  ✓ CLAUDE.md"
else
  echo "  ⚠ CLAUDE.md exists — skipped. Please check __JOURNAL__ manually."
fi

# 3) Generate paper-type.json from format+domain
PT_TARGET="$TARGET/.arc/paper-type.json"
PT_TEMPLATE="$TARGET/.arc/paper-type.template.json"
if [ ! -f "$PT_TARGET" ]; then
  if [ -f "$PT_TEMPLATE" ]; then
    # Auto-derive thresholds based on format+domain
    case "${FORMAT}-${DOMAIN}" in
      long-ai-experimental)
        MIN_REFS=30; RECENT_PCT=30; MIN_FIGS=5; REQ_ABL=true; MIN_RUNS=3; ABSTRACT_MAX=250 ;;
      long-ai-theoretical)
        MIN_REFS=30; RECENT_PCT=15; MIN_FIGS=3; REQ_ABL=false; MIN_RUNS=1; ABSTRACT_MAX=250 ;;
      long-physics)
        MIN_REFS=30; RECENT_PCT=20; MIN_FIGS=4; REQ_ABL=false; MIN_RUNS=1; ABSTRACT_MAX=250 ;;
      long-numerical)
        MIN_REFS=30; RECENT_PCT=20; MIN_FIGS=3; REQ_ABL=true; MIN_RUNS=1; ABSTRACT_MAX=250 ;;
      short-ai-experimental)
        MIN_REFS=15; RECENT_PCT=30; MIN_FIGS=3; REQ_ABL=true; MIN_RUNS=3; ABSTRACT_MAX=150 ;;
      short-ai-theoretical)
        MIN_REFS=15; RECENT_PCT=15; MIN_FIGS=3; REQ_ABL=false; MIN_RUNS=1; ABSTRACT_MAX=150 ;;
      short-physics)
        MIN_REFS=15; RECENT_PCT=20; MIN_FIGS=3; REQ_ABL=false; MIN_RUNS=1; ABSTRACT_MAX=150 ;;
      short-numerical)
        MIN_REFS=15; RECENT_PCT=20; MIN_FIGS=3; REQ_ABL=false; MIN_RUNS=1; ABSTRACT_MAX=150 ;;
      letter-*)
        MIN_REFS=10; RECENT_PCT=15; MIN_FIGS=2; REQ_ABL=false; MIN_RUNS=1; ABSTRACT_MAX=150 ;;
      *)
        MIN_REFS=30; RECENT_PCT=30; MIN_FIGS=5; REQ_ABL=true; MIN_RUNS=3; ABSTRACT_MAX=250 ;;
    esac
    PAGE_LIMIT=9
    if [ "$FORMAT" = "letter" ]; then PAGE_LIMIT=4; fi
    if [ "$FORMAT" = "short" ]; then PAGE_LIMIT=8; fi

    python3 - <<PY "$PT_TARGET" "$FORMAT" "$DOMAIN" "$JOURNAL" "$PAGE_LIMIT" \
      "$MIN_REFS" "$RECENT_PCT" "$MIN_FIGS" "$REQ_ABL" "$MIN_RUNS" "$ABSTRACT_MAX"
import json, sys
path = sys.argv[1]
data = {
    "paper_format": sys.argv[2],
    "paper_domain": sys.argv[3],
    "target_venue": sys.argv[4],
    "page_limit": int(sys.argv[5]),
    "derived_thresholds": {
        "min_references": int(sys.argv[6]),
        "min_references_note": "long≥30, short≥15, letter≥10",
        "min_recent_refs_pct": int(sys.argv[7]),
        "min_recent_refs_note": "ai-exp≥30%, ai-theory≥15%, physics/numerical≥20%",
        "min_figures": int(sys.argv[8]),
        "min_figures_note": "ai-exp long≥5, ai-exp short≥3, physics≥4, theory/numerical≥3",
        "min_tables": 1,
        "require_ablation": sys.argv[9].lower() == "true",
        "require_ablation_note": "true for ai-experimental and numerical",
        "min_experiment_runs": int(sys.argv[10]),
        "min_experiment_runs_note": "ai-exp≥3, others as appropriate",
        "abstract_max_words": int(sys.argv[11]),
        "abstract_max_words_note": "long≤250, short/letter≤150",
        "recent_years_cutoff": 5
    },
    "exemptions": {
        "ablation_exempt": False,
        "recent_refs_pct_exempt": False,
        "recent_refs_pct_exempt_reason": ""
    }
}
with open(path, 'w') as f:
    json.dump(data, f, indent=2)
PY
    echo "  ✓ paper-type.json (format=$FORMAT, domain=$DOMAIN)"
  else
    echo "  ⚠ paper-type.template.json missing, skipped"
  fi
else
  echo "  ⚠ paper-type.json exists — skipped"
fi

# 4) settings.json
if [ ! -f "$TARGET/.claude/settings.json" ]; then
  cp "$ARC_SRC/claude-settings.json" "$TARGET/.claude/settings.json"
  echo "  ✓ .claude/settings.json"
else
  echo "  ⚠ .claude/settings.json exists — skipped. Please merge hooks manually."
fi

# 5) env probe or template copy
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

# 6) hooks executable
chmod +x "$TARGET/.arc/hooks/"*.sh
chmod +x "$TARGET/.arc/env-probe.sh" "$TARGET/.arc/env-validate.sh" "$TARGET/.arc/conda-setup.sh"

# 7) append gitignore entries without duplicates
GITIGNORE="$TARGET/.gitignore"
[ -f "$GITIGNORE" ] || touch "$GITIGNORE"
for entry in ".arc/env.json" ".arc/state/" ".arc/loop-logs/" ".arc/memory/"; do
  if ! grep -Fxq "$entry" "$GITIGNORE"; then
    printf '%s\n' "$entry" >> "$GITIGNORE"
  fi
done

# 8) environment summary + paper-type thresholds + codex hint
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

# 9) paper-type threshold summary
if [ -f "$TARGET/.arc/paper-type.json" ] && command -v jq >/dev/null 2>&1; then
  FMT=$(jq -r '.paper_format' "$TARGET/.arc/paper-type.json")
  DOM=$(jq -r '.paper_domain' "$TARGET/.arc/paper-type.json")
  VEN=$(jq -r '.target_venue' "$TARGET/.arc/paper-type.json")
  PL=$(jq -r '.page_limit' "$TARGET/.arc/paper-type.json")
  MR=$(jq -r '.derived_thresholds.min_references' "$TARGET/.arc/paper-type.json")
  RP=$(jq -r '.derived_thresholds.min_recent_refs_pct' "$TARGET/.arc/paper-type.json")
  MF=$(jq -r '.derived_thresholds.min_figures' "$TARGET/.arc/paper-type.json")
  MT=$(jq -r '.derived_thresholds.min_tables' "$TARGET/.arc/paper-type.json")
  MER=$(jq -r '.derived_thresholds.min_experiment_runs' "$TARGET/.arc/paper-type.json")
  RA=$(jq -r '.derived_thresholds.require_ablation' "$TARGET/.arc/paper-type.json")
  echo ""
  echo "Paper-type thresholds [$FMT | $DOM | $VEN]"
  echo "  min_references:      $MR"
  echo "  min_recent_refs_pct: $RP%"
  echo "  min_figures:         $MF"
  echo "  min_tables:          $MT"
  echo "  min_experiment_runs: $MER"
  echo "  require_ablation:    $RA"
  echo "  page_limit:          $PL"
fi

echo ""
echo "✅ Done. Run ./validate.sh --target $TARGET"
