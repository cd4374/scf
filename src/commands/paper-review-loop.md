---
name: paper-review-loop
description: Run multi-round peer/adversarial review and revision loop
usage: /paper:review-loop
---

Run review loop with `MAX_ITER=4`.

## Preflight

1. Read `.arc/paper-type.json` for `require_ablation` and other thresholds.
2. Pass `paper_type_context` to all reviewers.

## Loop body per round

1. Run in parallel: `peer-reviewer-1`, `peer-reviewer-2`, `integrity-checker`, `citation-verifier`.
2. Run in parallel: `stat-auditor` (if ai-exp/numerical), `figure-auditor`.
3. Run `devils-advocate` for premise attack stress tests.
4. Main agent revises `draft.tex` based on blocking/major issues.
5. Re-review and write `.arc/loop-logs/review-rounds/review-round-{N}.json`.
6. Update `.arc/state/pipeline-status.json.loop_status.review_loop`.

## Stop conditions

- Overall score `>=85` and no blocking issue.
- `review-integrity.json` must have `pass: true`.
- `review-stat.json` must have `pass: true` (for ai-exp/numerical).
- Or `MAX_ITER=4` reached.

## Protection rule

- If score declines for 2 consecutive rounds, set status `human-intervention-needed` and pause.

## Reviewer weights (v5, read from paper-type)

| Dimension | Weight | Notes |
|-----------|--------|-------|
| Novelty | 25% | |
| Technical Rigor | 20% | |
| Experimental Adequacy | 20% | Includes ablation if require_ablation=true |
| Writing Clarity | 15% | Includes Limitations section |
| Citation Accuracy | 10% | |
| Reproducibility | 5% | |
| Impact | 5% | |

## Additional constraints

- Devil's-advocate attack intensity should not be softened automatically across rounds.
- Reviewer agents remain read-only and must only emit review JSON outputs.
- All reviewers must check against `paper-type.json` thresholds.