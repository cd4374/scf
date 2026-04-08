---
name: paper-review-loop
description: Run multi-round peer/adversarial review and revision loop
usage: /paper:review-loop
---

Run review loop with `MAX_ITER=4`.

## Loop body per round

1. Run `peer-reviewer-1` and `peer-reviewer-2` in parallel.
2. Run `devils-advocate` for premise attack stress tests.
3. Main agent revises `draft.tex` based on blocking/major issues.
4. Re-review and write `.arc/loop-logs/review-rounds/review-round-{N}.json`.
5. Update `.arc/state/pipeline-status.json.loop_status.review_loop`.

## Stop conditions

- Overall score `>=85` and no blocking issue.
- Or `MAX_ITER=4` reached.

## Protection rule

- If score declines for 2 consecutive rounds, set status `human-intervention-needed` and pause.

## Additional constraints

- Devil's-advocate attack intensity should not be softened automatically across rounds.
- Reviewer agents remain read-only and must only emit review JSON outputs.
