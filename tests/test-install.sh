#!/usr/bin/env bash
# test-install.sh — Test install.sh in a temporary directory
set -euo pipefail
TMP=$(mktemp -d)
trap "rm -rf $TMP" EXIT
echo "Testing install in $TMP..."
"$(dirname "$0")/../install.sh" --target "$TMP" --journal neurips
"$(dirname "$0")/../validate.sh" --target "$TMP"
echo "✅ Install test passed"
