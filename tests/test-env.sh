#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/.arc"

assert_contains() {
  local haystack="$1" needle="$2"
  if printf '%s' "$haystack" | grep -q "$needle"; then
    echo "✓ output contains $needle"
  else
    echo "✗ output missing $needle"
    printf '%s\n' "$haystack"
    exit 1
  fi
}

for f in env-local-cuda.json env-local-mps.json env-ssh-gpu.json env-cpu-only.json; do
  cp "$ROOT/tests/fixtures/env/$f" "$TMP/.arc/env.json"
  OUT="$(bash "$ROOT/src/arc/env-validate.sh" --target "$TMP" 2>&1 || true)"
  assert_contains "$OUT" ".arc/env.json valid JSON"
  assert_contains "$OUT" "compute.mode"
  echo "✓ validate handled $f"
done

printf '{bad json' > "$TMP/.arc/env.json"
if bash "$ROOT/src/arc/env-validate.sh" --target "$TMP" >/dev/null 2>&1; then
  echo "✗ invalid JSON should fail"
  exit 1
else
  echo "✓ invalid JSON fails as expected"
fi

cat > "$TMP/.arc/env.json" <<'EOF'
{
  "version": "1.0",
  "created_at": "",
  "last_validated": "",
  "compute": {"mode": "cpu", "backend": "cpu", "validated": true, "gpu_info": "", "experiment_time_limit": "4h", "max_parallel_runs": 3, "probe_errors": [], "ssh": {"host": "", "user": "", "key_path": "", "remote_dir": "", "code_sync": "rsync", "screen_prefix": "scf-exp"}, "modal": {"enabled": false, "app_name": "scf-experiments"}},
  "software": {"conda_env": "base", "python_version": "3.10", "activate_cmd": "conda activate base", "pytorch_version": "", "cuda_version": "", "environment_yml_path": ".arc/environment.yml"},
  "monitoring": {"wandb": false, "wandb_entity": "", "wandb_project": ""},
  "apis": {"semantic_scholar": "missing", "arxiv": "configured", "codex": "missing", "wandb": "disabled"},
  "active_experiments": []
}
EOF
if bash "$ROOT/src/arc/env-validate.sh" --target "$TMP" >/dev/null 2>&1; then
  echo "✗ base env should fail"
  exit 1
else
  echo "✓ base env fails as expected"
fi

echo "✅ env tests finished"
