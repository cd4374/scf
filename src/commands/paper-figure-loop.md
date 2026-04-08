---
name: paper-figure-loop
description: Run figure quality loop with visual auditing and targeted fixes
usage: /paper:figure-loop
---

Run figure loop with `MAX_ITER=5` and `SCORE_THRESHOLD=8.0`.

## Loop body per round

1. Render figures from code.
2. Audit visual quality on 5 axes: accuracy, readability, no clipping, accessible color, complete caption/title.
3. Apply targeted fixes for top-3 issues only.
4. Keep versioned outputs such as `fig_N_v{iter}.pdf/png`; never overwrite prior versions.
5. Log `.arc/loop-logs/figure-rounds/figure-round-{N}.json`.
6. Update `.arc/state/pipeline-status.json.loop_status.figure_loop`.

## Stop conditions

- All figures reach score `>=8.0`.
- Or `MAX_ITER=5` reached.
