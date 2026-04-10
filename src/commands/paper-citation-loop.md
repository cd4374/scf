---
name: paper-citation-loop
description: Run four-layer citation verification loop and remove hallucinated refs
usage: /paper:citation-loop
---

Run citation loop with `MAX_ITER=3`.

## Preflight

1. Read `.arc/paper-type.json` for:
   - `min_references`
   - `min_recent_refs_pct`
   - `exemptions.recent_refs_pct_exempt`

## Loop body per round

1. Run `citation-verifier` through Layer 1-4 checks.
2. Remove entries that fail Layer 2 or Layer 3 and mark them `HALLUCINATED`.
3. Add missing citations needed by unsupported claims.
4. Re-verify and log `.arc/loop-logs/citation-rounds/citation-round-{N}.json`.
5. Update `.arc/state/pipeline-status.json.loop_status.citation_loop` with verified/hallucinated counts.

## Stop conditions (v5)

- All entries pass Layer 1-3.
- Verified count ≥ `paper-type.min_references`.
- Recent refs % ≥ `paper-type.min_recent_refs_pct` (unless exempted).
- Or `MAX_ITER=3` reached.

## Exemptions

If `exemptions.recent_refs_pct_exempt == true`:
- Skip recent refs percentage check.
- Still enforce total count.
- Record exemption reason in `citation_status`.

## Output

```text
Citation Status
═══════════════════════════════════════════════════
Verified:     32 / 30 ✓
Recent (5yr): 35% / 30% ✓
Hallucinated: 2 removed
Exempt:       none
```