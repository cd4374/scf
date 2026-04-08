---
name: paper-citation-loop
description: Run four-layer citation verification loop and remove hallucinated refs
usage: /paper:citation-loop
---

Run citation loop with `MAX_ITER=3`.

## Loop body per round

1. Run `citation-verifier` through Layer 1-4 checks.
2. Remove entries that fail Layer 2 or Layer 3 and mark them `HALLUCINATED`.
3. Add missing citations needed by unsupported claims.
4. Re-verify and log `.arc/loop-logs/citation-rounds/citation-round-{N}.json`.
5. Update `.arc/state/pipeline-status.json.loop_status.citation_loop` with verified/hallucinated counts.

## Stop conditions

- All entries pass Layer 1-3.
- Or `MAX_ITER=3` reached.

Warn when verified citation count remains below 20.
