---
name: paper-run
description: Run the academic paper pipeline from the current stage
usage: /paper:run [--idea "research question"] [--journal neurips|icml|iclr|acl|ieee|elsevier|springer] [--resume] [--max-review-rounds 4]
---

Run the academic paper pipeline from current state.

## Parameters

- `--idea`: 设置或覆盖研究问题，写入 `.arc/state/idea.json`
- `--journal`: 设置目标期刊/会议
- `--resume`: 从当前 stage 恢复
- `--max-review-rounds`: 覆盖 review loop 默认轮次

## Preflight (mandatory)

1. Read `.arc/env.json`.
2. Assert `compute.validated == true`.
3. If false: stop and ask user to run `validate.sh`.
4. Read `.arc/state/pipeline-status.json` and current stage.

## Stage sequence

not-started -> idea-exploration -> idea-validation -> literature-review -> synthesis -> hypothesis-generation -> experiment-design -> experiment-run -> result-analysis -> writing -> figure-generation -> citation-verification -> peer-review -> codex-review -> final-review -> export -> completed

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
