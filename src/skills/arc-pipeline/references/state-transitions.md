# State Transitions Reference

## Pipeline States

```
pending → running → done | blocked | failed
blocked → approved | rejected | paused
approved → done
rejected → pending (rollback)
paused → running
```

## Blocking vs Gating

- **BLOCKING**: Pipeline cannot proceed — user must fix issue
- **GATE**: Pipeline pauses at checkpoint — user approves/rejects

## Always Blocking Stages

| Stage | Condition |
|-------|-----------|
| 0 | Missing execution/LaTeX/network |
| 4 | Hallucinated citations |
| 7.5 | No novelty gap |
| 9.5 | Reproducibility contract incomplete |
| 15.5 | Unsupported claims |
| 17.5 | Structure/marker issues |
| 18.5 | Bibliography quality issues |
| 21.5 | Reproducibility bundle incomplete |
| 24 | Codex MCP unavailable |
| 24.5 | Academic integrity issues |
| 26.5 | Claim-evidence traceability failed |
| 27 | Figure quality failed |
| 28 | Format noncompliance |
| 28.5 | Final acceptance failed |

## Gate Behaviors

| Gate | On Approve | On Reject |
|------|------------|-----------|
| Stage 5 | Advance to 6 | Rollback to 4 |
| Stage 7.5 | Advance to 8 | Rollback to 7 |
| Stage 9 | Advance to 10 | Rollback to 8 |
| Stage 9.5 | Advance to 10 | Rollback to 9 |
| Stage 15.5 | Advance to 15.7 | Rollback to 15 |
| Stage 17.5 | Advance to 18 | Rollback to 17 |
| Stage 18.5 | Advance to 19 | Rollback to 17 |
| Stage 20 | Advance to 21 | Rollback to 16 |
| Stage 21.5 | Advance to 22 | Rollback to 20 |
| Stage 24.5 | Advance to 25 | Rollback to 24 |
| Stage 26 | Advance to 26.5 | Rollback to 19 |
| Stage 26.5 | Advance to 27 | Rollback to 19 |
| Stage 27 | Advance to 28 | Rollback to 22 |
| Stage 28 | Advance to 28.5 | Rollback to 22 |
| Stage 28.5 | Terminal done | Rollback to 28 |
