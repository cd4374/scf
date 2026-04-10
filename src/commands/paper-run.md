---
name: paper-run
description: Run the academic paper pipeline from the current stage
usage: /paper:run [--idea "research question"] [--journal neurips|icml|iclr|acl|ieee|elsevier|springer] [--resume] [--max-review-rounds 4]
---

Run the academic paper pipeline from current state.

## Parameters

- `--idea`: Set or override research question, write to `.arc/state/idea.json`
- `--journal`: Set target venue (deprecated; use `/paper:init` instead)
- `--resume`: Resume from current stage
- `--max-review-rounds`: Override review loop default rounds

## Preflight (mandatory)

1. Read `.arc/paper-type.json` — if missing, require `/paper:init` first.
2. Read `.arc/env.json`.
3. Assert `compute.validated == true`.
4. If false: stop and ask user to run `validate.sh`.
5. Read `.arc/state/pipeline-status.json` and current stage.

## Stage sequence (v5)

```
not-started → paper-init → idea-exploration → idea-validation →
literature-review → synthesis → hypothesis-generation →
experiment-design → experiment-run → result-analysis →
writing → figure-generation → citation-verification →
integrity-check → stat-audit → peer-review → codex-review →
final-review → export → completed
```

**v5 new stages**: `paper-init`, `integrity-check`, `stat-audit`

## Core flow

1. If `--idea` provided, update `.arc/state/idea.json`.
2. Execute current stage skill/command action.
3. After each stage, update `.arc/state/pipeline-status.json`:
   - `stage`
   - `stages_completed`
   - `last_updated`
4. Delegate reviewer tasks and wait for `.arc/state/review-*.json`.
5. Do not advance while blocking issues exist.

## Blocking behavior

- Any blocking issue in review/hook/state stops progression.
- If loop reached max rounds without pass, mark `max-iter-reached` and stop or require user decision.

## Integration

- Use `/paper:status` for quick snapshot before/after transitions.
- Keep stage names strictly consistent with docs/state/skills.