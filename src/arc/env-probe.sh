#!/usr/bin/env bash
set -euo pipefail

TARGET="${TARGET:-${CLAUDE_PROJECT_DIR:-$(pwd)}}"
SSH_HOST=""
CONDA_ENV=""
PROJECT_NAME="paper"
SKIP_CONDA_CREATE="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    --ssh-host) SSH_HOST="$2"; shift 2 ;;
    --conda-env) CONDA_ENV="$2"; shift 2 ;;
    --project-name) PROJECT_NAME="$2"; shift 2 ;;
    --skip-conda-create) SKIP_CONDA_CREATE="true"; shift 1 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

mkdir -p "$TARGET/.arc"
ENV_JSON="$TARGET/.arc/env.json"

MODE="cpu"
BACKEND="cpu"
GPU_INFO=""
PROBE_ERRORS='[]'

append_probe_error_json() {
  local current="$1"
  local level="$2"
  local message="$3"
  python3 - <<'PY' "$current" "$level" "$message"
import json,sys
cur,level,msg=sys.argv[1],sys.argv[2],sys.argv[3]
try:
    arr=json.loads(cur)
    if not isinstance(arr,list):
        arr=[]
except Exception:
    arr=[]
arr.append({"level": level, "message": msg})
print(json.dumps(arr, ensure_ascii=False))
PY
}

add_probe_error() {
  local level="$1"
  local msg="$2"
  PROBE_ERRORS="$(append_probe_error_json "$PROBE_ERRORS" "$level" "$msg")"
}

get_ssh_config_field() {
  local host="$1"
  local field="$2"
  local cfg="$HOME/.ssh/config"
  [ -f "$cfg" ] || return 0
  awk -v host="$host" -v want="$field" '
    BEGIN{in_host=0}
    /^[[:space:]]*Host[[:space:]]+/ {
      in_host=0
      for (i=2; i<=NF; i++) {
        if ($i==host) { in_host=1; break }
      }
      next
    }
    in_host==1 {
      key=$1
      val=$2
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", key)
      if (tolower(key)==tolower(want)) {
        print val
        exit
      }
    }
  ' "$cfg"
}

# Stage 1: local CUDA -> MPS -> CPU
if command -v python3 >/dev/null 2>&1; then
  CUDA_OUT="$(python3 -c 'import torch; print(int(torch.cuda.is_available()), torch.cuda.device_count())' 2>/dev/null || true)"
  if [[ "$CUDA_OUT" =~ ^1\  ]]; then
    MODE="local"
    BACKEND="cuda"
    GPU_INFO="$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | paste -sd ';' - || echo "cuda")"
  else
    MPS_OUT="$(python3 -c 'import torch; print(int(hasattr(torch.backends, "mps") and torch.backends.mps.is_available()))' 2>/dev/null || true)"
    if [ "$MPS_OUT" = "1" ]; then
      MODE="local"
      BACKEND="mps"
      GPU_INFO="Apple Silicon (MPS)"
    fi
  fi
else
  add_probe_error "warning" "python3 not found"
fi

# Stage 2: optional SSH probe
SSH_USER=""
SSH_KEY_PATH="~/.ssh/id_rsa"
SSH_REMOTE_DIR="/home/${USER:-user}/scf-experiments/"
SSH_CODE_SYNC="rsync"
SSH_SCREEN_PREFIX="scf-exp"

if [ -n "$SSH_HOST" ]; then
  if [ -f "$HOME/.ssh/config" ] && grep -q "^Host[[:space:]]\+$SSH_HOST\b" "$HOME/.ssh/config"; then
    SSH_USER="$(get_ssh_config_field "$SSH_HOST" "User" || true)"
    SSH_KEY_PATH="$(get_ssh_config_field "$SSH_HOST" "IdentityFile" || true)"
    [ -n "$SSH_KEY_PATH" ] || SSH_KEY_PATH="~/.ssh/id_rsa"

    if ssh -o ConnectTimeout=5 -o BatchMode=yes "$SSH_HOST" echo ok >/dev/null 2>&1; then
      REMOTE_GPU="$(ssh "$SSH_HOST" "nvidia-smi --query-gpu=name --format=csv,noheader | head -1" 2>/dev/null || true)"
      if [ -n "$REMOTE_GPU" ]; then
        MODE="ssh"
        BACKEND="cuda"
        GPU_INFO="$REMOTE_GPU"
      else
        add_probe_error "warning" "ssh host reachable but no nvidia-smi output"
      fi
    else
      add_probe_error "warning" "ssh connectivity failed for host $SSH_HOST"
    fi
  else
    add_probe_error "warning" "ssh host alias $SSH_HOST not found in ~/.ssh/config"
  fi
fi

# Stage 3: conda
if [ -z "$CONDA_ENV" ]; then
  CONDA_ENV="scf-${PROJECT_NAME}"
fi

if [ "$CONDA_ENV" = "base" ]; then
  add_probe_error "error" "software.conda_env cannot be base"
fi

if command -v conda >/dev/null 2>&1; then
  if ! conda env list | awk '{print $1}' | grep -Fxq "$CONDA_ENV"; then
    if [ "$SKIP_CONDA_CREATE" = "false" ]; then
      if ! bash "$TARGET/.arc/conda-setup.sh" --target "$TARGET" --project-name "$PROJECT_NAME"; then
        add_probe_error "warning" "failed to create conda env $CONDA_ENV"
      fi
    else
      add_probe_error "warning" "conda env $CONDA_ENV not found"
    fi
  fi
else
  add_probe_error "warning" "conda not installed"
fi

PY_VER="$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null || echo "")"
TORCH_VER="$(python3 -c 'import torch; print(torch.__version__)' 2>/dev/null || echo "")"
CUDA_VER="$(python3 -c 'import torch; print(torch.version.cuda or "")' 2>/dev/null || echo "")"

# Stage 4: API status by env vars only
SEMANTIC="missing"
CODEX="missing"
WANDB_API="disabled"
ARXIV="configured"
if [ -n "${SEMANTIC_SCHOLAR_API_KEY:-}" ]; then SEMANTIC="configured"; fi
if [ -n "${OPENAI_API_KEY:-}" ]; then CODEX="configured"; fi
if [ "${WANDB_ENABLED:-}" = "true" ]; then
  if [ -n "${WANDB_API_KEY:-}" ]; then WANDB_API="configured"; else WANDB_API="missing"; fi
fi

HAS_ERROR="$(python3 - <<'PY' "$PROBE_ERRORS"
import json,sys
try:
    arr=json.loads(sys.argv[1])
except Exception:
    arr=[]
print(sum(1 for x in arr if isinstance(x,dict) and x.get('level')=='error'))
PY
)"
VALIDATED="false"
if [ "$HAS_ERROR" = "0" ]; then VALIDATED="true"; fi

NOW="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
ACTIVATE_CMD="conda activate ${CONDA_ENV}"

python3 - <<'PY' "$ENV_JSON" "$NOW" "$MODE" "$BACKEND" "$GPU_INFO" "$VALIDATED" "$PROBE_ERRORS" "$SSH_HOST" "$SSH_USER" "$SSH_KEY_PATH" "$SSH_REMOTE_DIR" "$SSH_CODE_SYNC" "$SSH_SCREEN_PREFIX" "$CONDA_ENV" "$PY_VER" "$ACTIVATE_CMD" "$TORCH_VER" "$CUDA_VER" "$SEMANTIC" "$ARXIV" "$CODEX" "$WANDB_API"
import json,os,sys
(
  env_path, now, mode, backend, gpu, validated_raw, probe_errors_raw,
  ssh_host, ssh_user, ssh_key, ssh_remote, ssh_sync, ssh_prefix,
  conda_env, py_ver, activate_cmd, torch_ver, cuda_ver,
  semantic, arxiv, codex, wandb_api
)=sys.argv[1:]

try:
    probe_errors=json.loads(probe_errors_raw)
    if not isinstance(probe_errors,list):
        probe_errors=[]
except Exception:
    probe_errors=[]

validated = str(validated_raw).lower() == 'true'
wandb_enabled = os.getenv('WANDB_ENABLED','').lower() == 'true'

if not ssh_user:
    ssh_user = os.getenv('USER','')

data={
  "version":"1.0",
  "created_at":now,
  "last_validated":now,
  "compute":{
    "mode":mode,
    "backend":backend,
    "validated":validated,
    "gpu_info":gpu,
    "experiment_time_limit":"4h",
    "max_parallel_runs":3,
    "probe_errors":probe_errors,
    "ssh":{
      "host":ssh_host,
      "user":ssh_user,
      "key_path":ssh_key,
      "remote_dir":ssh_remote,
      "code_sync":ssh_sync,
      "screen_prefix":ssh_prefix
    },
    "modal":{"enabled":False,"app_name":"scf-experiments"}
  },
  "software":{
    "conda_env":conda_env,
    "python_version":py_ver,
    "activate_cmd":activate_cmd,
    "pytorch_version":torch_ver,
    "cuda_version":cuda_ver,
    "environment_yml_path":".arc/environment.yml"
  },
  "monitoring":{
    "wandb":wandb_enabled,
    "wandb_entity":os.getenv("WANDB_ENTITY", ""),
    "wandb_project":os.getenv("WANDB_PROJECT", "")
  },
  "apis":{
    "semantic_scholar":semantic,
    "arxiv":arxiv,
    "codex":codex,
    "wandb":wandb_api
  },
  "active_experiments":[]
}

with open(env_path,'w',encoding='utf-8') as f:
    json.dump(data,f,indent=2,ensure_ascii=False)
PY

read -r WARN_COUNT ERR_COUNT SUMMARY_MODE SUMMARY_CONDA SUMMARY_SEM SUMMARY_CODEX <<<"$(python3 - <<'PY' "$ENV_JSON"
import json,sys
try:
    d=json.load(open(sys.argv[1], encoding='utf-8'))
except Exception:
    print('0 0 unknown unknown missing missing')
    raise SystemExit(0)
errs=d.get('compute',{}).get('probe_errors',[])
warn=sum(1 for x in errs if isinstance(x,dict) and x.get('level')=='warning')
err=sum(1 for x in errs if isinstance(x,dict) and x.get('level')=='error')
mode=d.get('compute',{}).get('mode','unknown')
conda=d.get('software',{}).get('conda_env','unknown')
sem=d.get('apis',{}).get('semantic_scholar','missing')
codex=d.get('apis',{}).get('codex','missing')
print(f"{warn} {err} {mode} {conda} {sem} {codex}")
PY
)"

echo "env probe summary"
echo "  compute.mode: $SUMMARY_MODE"
echo "  software.conda_env: $SUMMARY_CONDA"
echo "  apis: semantic_scholar=$SUMMARY_SEM, codex=$SUMMARY_CODEX"
echo "  probe_errors: warnings=$WARN_COUNT errors=$ERR_COUNT"
