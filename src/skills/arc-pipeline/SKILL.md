---
name: arc-pipeline
description: Orchestrates end-to-end pipeline stage transitions with strict blocking-gate enforcement. Use when starting, resuming, or advancing workflow while synchronizing command, reviewer, and state contracts.
---

# Arc Pipeline

## Purpose

`arc-pipeline` is the orchestration core for stage progression, blocking checks, and loop state synchronization.

## Authoritative stage order (v5)

```
not-started → paper-init → idea-exploration → idea-validation →
literature-review → synthesis → hypothesis-generation →
experiment-design → experiment-run → result-analysis →
writing → figure-generation → citation-verification →
integrity-check → stat-audit → peer-review → codex-review →
final-review → export → completed
```

**v5 new stages**: `paper-init`, `integrity-check`, `stat-audit`

## Inputs

- `.arc/state/pipeline-status.json`
- `.arc/state/review-*.json`
- `.arc/env.json`
- `.arc/paper-type.json`
- slash command parameters (run/resume/loop)

## Reviewer set (13 agents, v5)

- idea-validator
- novelty-checker
- literature-reviewer
- logic-checker
- stat-auditor
- figure-auditor
- citation-verifier
- integrity-checker (v5 new)
- peer-reviewer-1
- peer-reviewer-2
- devils-advocate
- multi-agent-debate
- final-reviewer

## Core contracts

1. Read `pipeline-status.json` before any stage advance.
2. No advance when blocking issues exist.
3. Reviewer subagents are read-only; output to `.arc/state/review-*.json`.
4. Cross-session state via `.arc/state/*.json` and `.arc/loop-logs/*`.
5. All quantity thresholds read from `.arc/paper-type.json`.

## Stage transition rules

- run: Start from current stage or not-started
- resume: Resume from interrupted stage
- reset: Reset only specified stage and downstream
- export: Only after final-review pass

## Loop integration

- idea-loop `MAX_ITER=3`
- review-loop `MAX_ITER=4`
- figure-loop `MAX_ITER=5`
- citation-loop `MAX_ITER=3`

review-loop supports "two consecutive score drops → human-intervention-needed".

## Blocking gate examples

- env not validated (`compute.validated=false`)
- review-final not passed
- review-integrity not passed (v5)
- review-stat not passed (v5)
- refs/figures/pages below paper-type thresholds

## Synchronization points

Must stay consistent with:
- `docs/pipeline-states.md`
- `src/commands/paper-run.md`
- `src/skills/arc-state-management/SKILL.md`
- `src/arc/state/pipeline-status.json`

## Failure handling

- Missing state file: write blocking reason and stop
- Invalid reviewer output: mark fail, require re-run
- Loop max_iter reached: state marked `max-iter-reached`

## Output expectations

- Update `pipeline-status.json`: `stage`, `stages_completed`, `last_updated`, `loop_status`
- Write necessary loop logs
- Output current stage and blocking summary to user

## Notes

- This skill orchestrates; does not replace experiment/writing/citation skills.
- All gate values read from `paper-type.json`, not hardcoded.