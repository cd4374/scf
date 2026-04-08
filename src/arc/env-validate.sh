#!/usr/bin/env bash
set -euo pipefail

TARGET="${TARGET:-${CLAUDE_PROJECT_DIR:-$(pwd)}}"
CONNECTIVITY="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    --connectivity) CONNECTIVITY="true"; shift 1 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

ENV_JSON="$TARGET/.arc/env.json"
PASS=0
WARN=0
ERROR=0

pass() { echo "✓ $1"; PASS=$((PASS+1)); }
warn() { echo "⚠ $1"; WARN=$((WARN+1)); }
err() { echo "✗ $1"; ERROR=$((ERROR+1)); }

json_get() {
  python3 - <<'PY' "$ENV_JSON" "$1"
import json,sys
path,key=sys.argv[1],sys.argv[2]
try:
    d=json.load(open(path, encoding='utf-8'))
except Exception:
    print("")
    raise SystemExit(0)
cur=d
for p in key.split('.'):
    if isinstance(cur,dict) and p in cur:
        cur=cur[p]
    else:
        print("")
        raise SystemExit(0)
if isinstance(cur,bool):
    print('true' if cur else 'false')
else:
    print(cur)
PY
}

python_in_conda_ok() {
  local env_name="$1"
  conda run -n "$env_name" python -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null || true
}

torch_import_ok() {
  local env_name="$1"
  conda run -n "$env_name" python -c 'import torch; print("ok")' >/dev/null 2>&1
}

cuda_available_ok() {
  local env_name="$1"
  local out
  out="$(conda run -n "$env_name" python -c 'import torch; print("1" if torch.cuda.is_available() else "0")' 2>/dev/null || true)"
  [ "$out" = "1" ]
}

mps_available_ok() {
  local env_name="$1"
  local out
  out="$(conda run -n "$env_name" python -c 'import torch; print("1" if (hasattr(torch.backends, "mps") and torch.backends.mps.is_available()) else "0")' 2>/dev/null || true)"
  [ "$out" = "1" ]
}

echo "Environment Validation"
echo "══════════════════════════════════════════"

if [ ! -f "$ENV_JSON" ]; then
  err ".arc/env.json missing"
  echo "Result: ${PASS} PASS  ${WARN} WARN  ${ERROR} ERROR"
  exit 1
fi

if python3 -m json.tool "$ENV_JSON" >/dev/null 2>&1; then
  pass ".arc/env.json valid JSON"
else
  err ".arc/env.json invalid JSON"
  echo "Result: ${PASS} PASS  ${WARN} WARN  ${ERROR} ERROR"
  exit 1
fi

MODE="$(json_get compute.mode)"
case "$MODE" in
  local|ssh|modal|cpu) pass "compute.mode: $MODE" ;;
  *) err "compute.mode invalid: $MODE" ;;
esac

CONDA_ENV="$(json_get software.conda_env)"
if [ -n "$CONDA_ENV" ] && [ "$CONDA_ENV" != "base" ]; then
  pass "software.conda_env: $CONDA_ENV (not base)"
else
  err "software.conda_env empty or base"
fi

PY_VER_REQ="$(json_get software.python_version)"
if [[ "$PY_VER_REQ" =~ ^3\.(1[0-9]|[2-9][0-9])$ ]]; then
  pass "software.python_version: $PY_VER_REQ"
else
  err "software.python_version must be >= 3.10"
fi

if command -v conda >/dev/null 2>&1; then
  pass "conda installed"
else
  err "conda not installed"
fi

if command -v conda >/dev/null 2>&1; then
  if [ -n "$CONDA_ENV" ] && conda env list | awk '{print $1}' | grep -Fxq "$CONDA_ENV"; then
    pass "conda env $CONDA_ENV exists"

    PY_ACTUAL="$(python_in_conda_ok "$CONDA_ENV")"
    if [[ "$PY_ACTUAL" =~ ^3\.(1[0-9]|[2-9][0-9])$ ]]; then
      pass "Python $PY_ACTUAL (>= 3.10)"
    else
      err "Python version in env is invalid: $PY_ACTUAL"
    fi

    if torch_import_ok "$CONDA_ENV"; then
      pass "PyTorch importable"
    else
      err "PyTorch not importable in conda env"
    fi

    BACKEND="$(json_get compute.backend)"
    if [ "$MODE" = "local" ] && [ "$BACKEND" = "cuda" ]; then
      if cuda_available_ok "$CONDA_ENV"; then
        pass "local-cuda backend available"
      else
        err "local-cuda backend unavailable"
      fi
    fi
    if [ "$MODE" = "local" ] && [ "$BACKEND" = "mps" ]; then
      if mps_available_ok "$CONDA_ENV"; then
        pass "local-mps backend available"
      else
        err "local-mps backend unavailable"
      fi
    fi
  else
    err "conda env $CONDA_ENV missing"
  fi
fi

# Check actual semantic_scholar API availability
if curl -s "https://api.semanticscholar.org/graph/v1/paper/search?query=test&limit=1" >/dev/null 2>&1; then
  pass "semantic_scholar API reachable"
else
  warn "semantic_scholar API unreachable"
fi

# Check actual Codex MCP availability (not just env.json setting)
CODEX_ENV="$(json_get apis.codex)"
if claude mcp list 2>/dev/null | grep -q "codex.*Connected"; then
    pass "codex MCP connected"
    # Warn if env.json is out of sync
    if [ "$CODEX_ENV" = "missing" ]; then
        warn "env.json apis.codex is 'missing' but MCP is connected - consider updating env.json"
    fi
else
    warn "codex missing -> /paper:codex-review degraded"
fi

# Check wandb: if enabled in config, verify CLI availability
WANDB_MON="$(json_get monitoring.wandb)"
WANDB_API="$(json_get apis.wandb)"
if [ "$WANDB_MON" = "true" ]; then
  if command -v wandb >/dev/null 2>&1; then
    if wandb login --list 2>/dev/null | grep -q "currently logged in"; then
      pass "wandb CLI available and logged in"
    else
      warn "wandb monitoring enabled but not logged in (run: wandb login)"
    fi
  else
    warn "wandb monitoring enabled but CLI not installed"
  fi
else
  pass "wandb monitoring disabled"
fi

if [ "$MODE" = "ssh" ]; then
  SSH_HOST="$(json_get compute.ssh.host)"
  if [ -n "$SSH_HOST" ] && [ -f "$HOME/.ssh/config" ] && grep -q "^Host[[:space:]]\+$SSH_HOST\b" "$HOME/.ssh/config"; then
    pass "SSH config entry for $SSH_HOST"
  else
    warn "SSH config entry missing for host $SSH_HOST"
  fi
fi

if [ "$CONNECTIVITY" = "true" ]; then
  if [ "$MODE" = "ssh" ]; then
    SSH_HOST="$(json_get compute.ssh.host)"
    SSH_REMOTE_DIR="$(json_get compute.ssh.remote_dir)"
    if [ -n "$SSH_HOST" ]; then
      if ssh -o ConnectTimeout=10 -o BatchMode=yes "$SSH_HOST" echo ok >/dev/null 2>&1; then
        pass "SSH connectivity"
      else
        err "SSH connectivity failed"
      fi
      if [ -n "$CONDA_ENV" ] && ssh "$SSH_HOST" "conda env list | awk '{print \$1}' | grep -Fxq '$CONDA_ENV'" >/dev/null 2>&1; then
        pass "remote conda env exists"
      else
        warn "remote conda env missing or not accessible"
      fi
      if ssh "$SSH_HOST" "nvidia-smi" >/dev/null 2>&1; then
        pass "remote GPU available"
      else
        warn "remote GPU check failed"
      fi
      if [ -n "$SSH_REMOTE_DIR" ] && ssh "$SSH_HOST" "mkdir -p '$SSH_REMOTE_DIR'" >/dev/null 2>&1; then
        pass "remote_dir exists/created"
      else
        warn "remote_dir check failed"
      fi
    fi
  fi

  if curl -s "https://api.semanticscholar.org/graph/v1/paper/search?query=test&limit=1" >/dev/null; then
    pass "semantic scholar API reachable"
  else
    warn "semantic scholar API unreachable"
  fi
  if curl -s "http://export.arxiv.org/api/query?search_query=all:test&max_results=1" >/dev/null; then
    pass "arXiv API reachable"
  else
    warn "arXiv API unreachable"
  fi
else
  warn "SSH/API connectivity checks skipped (--connectivity not set)"
fi

echo "══════════════════════════════════════════"
echo "Result: ${PASS} PASS  ${WARN} WARN  ${ERROR} ERROR"
if [ "$ERROR" -gt 0 ]; then exit 1; fi
