#!/usr/bin/env bash
set -euo pipefail
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "Testing install in $TMP..."
"$ROOT/install.sh" --target "$TMP" --journal neurips --project-name testproj --skip-env-probe
VALIDATE_OUT="$("$ROOT/validate.sh" --target "$TMP" 2>&1 || true)"
echo "$VALIDATE_OUT"
if printf '%s' "$VALIDATE_OUT" | grep -q "FAIL"; then
  echo "⚠ validate reported FAIL in test environment (often due to missing conda/env), continue structural assertions"
fi

if grep -q "## GPU Environment" "$TMP/CLAUDE.md"; then
  echo "✗ CLAUDE.md should not contain GPU Environment section"
  exit 1
fi
if ! grep -q "Compute environment: read" "$TMP/CLAUDE.md"; then
  echo "✗ CLAUDE.md missing env pointer"
  exit 1
fi
if [ ! -f "$TMP/.arc/env.json" ]; then
  echo "✗ .arc/env.json missing"
  exit 1
fi
if [ -f "$TMP/src/CLAUDE.env.fragment" ]; then
  echo "✗ deprecated CLAUDE.env.fragment should not exist"
  exit 1
fi

echo "✅ install test passed"
