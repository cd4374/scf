---
name: paper-codex-review
description: Perform cross-model review via Codex MCP, with degraded fallback
usage: /paper:codex-review
---

1. Check Codex MCP configuration.
2. If configured, run four parallel external reviews:
   - method
   - experiment
   - writing
   - citation
3. If missing, run `multi-agent-debate` and set `cross_model: degraded`.
4. Write result to `.arc/state/review-codex.json`.
5. Present summary and wait for user confirmation before continuation.

Result schema should include `cross_model: codex|degraded` and blocking issues when pass=false.
