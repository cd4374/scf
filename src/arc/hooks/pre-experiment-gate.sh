#!/usr/bin/env bash
# pre-experiment-gate.sh
# Blocks experiment execution if env.json not validated or paper-type.json missing
set -euo pipefail
INPUT=$(cat)

# Only intercept Bash tool calls
if command -v jq >/dev/null 2>&1; then
  TOOL=$(jq -r '.tool_call_name // ""' <<<"$INPUT" 2>/dev/null || true)
  CMD=$(jq -r '.tool_input.command // ""' <<<"$INPUT" 2>/dev/null || true)
else
  TOOL=$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_call_name",""))' <<<"$INPUT" 2>/dev/null || true)
  CMD=$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' <<<"$INPUT" 2>/dev/null || true)
fi

if [ "$TOOL" != "Bash" ]; then
  exit 0
fi

# Only block experiment-related commands
EXPERIMENT_PATTERNS="python train|python run|bash run|python.*experiment|python.*eval|python.*benchmark"
if ! echo "$CMD" | grep -Eq "$EXPERIMENT_PATTERNS"; then
  exit 0
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
ENV_JSON="$PROJECT_DIR/.arc/env.json"
PT="$PROJECT_DIR/.arc/paper-type.json"

BLOCK=()
WARN=()

# Check 1: env.json exists and validated
if [ ! -f "$ENV_JSON" ]; then
  BLOCK+=("Missing .arc/env.json — run validate.sh first")
elif command -v jq >/dev/null 2>&1; then
  VALIDATED=$(jq -r '.compute.validated // false' "$ENV_JSON" 2>/dev/null || echo "false")
  if [ "$VALIDATED" != "true" ]; then
    BLOCK+=(".arc/env.json compute.validated != true — run validate.sh")
  fi
else
  # fallback without jq
  if ! python3 -c "import json; d=json.load(open('$ENV_JSON')); exit(0 if d.get('compute',{}).get('validated') else 1)" 2>/dev/null; then
    BLOCK+=(".arc/env.json compute.validated != true — run validate.sh")
  fi
fi

# Check 2: paper-type.json exists
if [ ! -f "$PT" ]; then
  WARN+=("Missing .arc/paper-type.json — run /paper:init first")
fi

# Check 3: random seed declaration in experiment code
SCRIPT_PATH=""
if command -v python3 >/dev/null 2>&1; then
  SCRIPT_PATH=$(python3 - <<'PY' "$CMD"
import re,sys
cmd = sys.argv[1]
patterns = [
    r'python\s+([^\s]+\.py)',
    r'python3\s+([^\s]+\.py)',
    r'bash\s+([^\s]+\.sh)'
]
for p in patterns:
    m = re.search(p, cmd)
    if m:
        print(m.group(1))
        break
PY
)
fi

if [ -n "$SCRIPT_PATH" ] && [ -f "$PROJECT_DIR/$SCRIPT_PATH" ]; then
  if ! grep -Eq 'random\.seed|np\.random\.seed|torch\.manual_seed|set_random_seed' "$PROJECT_DIR/$SCRIPT_PATH" 2>/dev/null; then
    WARN+=("Experiment script $SCRIPT_PATH may not set random seed")
  fi
fi

# Report
if [ ${#BLOCK[@]} -gt 0 ]; then
  REASON=$(printf '%s; ' "${BLOCK[@]}" | sed 's/; $//')
  python3 - <<PY "$REASON"
import json, sys
print(json.dumps({"decision":"block","reason":sys.argv[1]}, ensure_ascii=False))
PY
  exit 2
fi

if [ ${#WARN[@]} -gt 0 ]; then
  printf 'Experiment warnings: %s\n' "$(printf '%s; ' "${WARN[@]}" | sed 's/; $//')" >&2
fi

exit 0
