#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

assert_contains() {
  local file="$1" expected="$2"
  if grep -q "$expected" "$file"; then
    echo "✓ $(basename "$file") contains $expected"
  else
    echo "✗ $(basename "$file") missing $expected"
    exit 1
  fi
}

assert_contains "$ROOT/src/commands/paper-idea-loop.md" "MAX_ITER=3"
assert_contains "$ROOT/src/commands/paper-review-loop.md" "MAX_ITER=4"
assert_contains "$ROOT/src/commands/paper-figure-loop.md" "MAX_ITER=5"
assert_contains "$ROOT/src/commands/paper-citation-loop.md" "MAX_ITER=3"
assert_contains "$ROOT/src/commands/paper-review-loop.md" "human-intervention-needed"

echo "✅ auto-loop checks passed"
