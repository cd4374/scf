---
name: paper-idea-loop
description: Run idea exploration auto-loop with novelty and feasibility checks
usage: /paper:idea-loop
---

Run idea loop with `MAX_ITER=3`.

## Pre-round checks

1. Read `.arc/memory/idea-history/MEMORY.md` to avoid repetition.
2. Ensure candidate ideas cover at least 2 innovation dimensions.

## Loop body per round

1. Generate candidate ideas.
2. Run `novelty-checker` against Semantic Scholar (or mark degraded explicitly if unavailable).
3. Run `idea-validator` for novelty × feasibility × impact scoring.
4. Record `.arc/loop-logs/review-rounds/idea-round-{N}.json`.
5. Update `.arc/state/pipeline-status.json.loop_status.idea_loop`.

## Stop conditions

- Any idea score `>=80` and novelty passes.
- Or `MAX_ITER=3` reached.
