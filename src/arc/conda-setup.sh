#!/usr/bin/env bash
set -euo pipefail

TARGET="${TARGET:-${CLAUDE_PROJECT_DIR:-$(pwd)}}"
PROJECT_NAME="paper"
PYTHON_VERSION="3.10"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    --project-name) PROJECT_NAME="$2"; shift 2 ;;
    --python-version) PYTHON_VERSION="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

if ! command -v conda >/dev/null 2>&1; then
  echo "conda not found. Install Miniforge: https://github.com/conda-forge/miniforge" >&2
  exit 1
fi

if [ "${CONDA_DEFAULT_ENV:-}" = "base" ]; then
  echo "Refusing to operate from base env. Activate another shell env first." >&2
  exit 1
fi

ENV_NAME="scf-${PROJECT_NAME}"

if ! conda env list | awk '{print $1}' | grep -Fxq "$ENV_NAME"; then
  conda create -n "$ENV_NAME" "python=${PYTHON_VERSION}" -y
fi

conda run -n "$ENV_NAME" pip install torch numpy scipy matplotlib seaborn >/dev/null
mkdir -p "$TARGET/.arc"
conda env export -n "$ENV_NAME" > "$TARGET/.arc/environment.yml"

ENV_JSON="$TARGET/.arc/env.json"
if [ -f "$ENV_JSON" ] && command -v jq >/dev/null 2>&1; then
  tmp="$(mktemp)"
  jq --arg env "$ENV_NAME" \
     --arg py "$PYTHON_VERSION" \
     '.software.conda_env=$env | .software.python_version=$py | .software.activate_cmd=("conda activate " + $env) | .software.environment_yml_path=".arc/environment.yml"' \
     "$ENV_JSON" > "$tmp"
  mv "$tmp" "$ENV_JSON"
fi

echo "Prepared conda env: $ENV_NAME"
