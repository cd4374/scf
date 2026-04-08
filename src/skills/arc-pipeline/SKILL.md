---
name: arc-pipeline
description: Orchestrates end-to-end pipeline stage transitions with strict blocking-gate enforcement. Use when starting, resuming, or advancing workflow while synchronizing command, reviewer, and state contracts.
---

# Arc Pipeline

## Purpose

`arc-pipeline` 是全流程编排核心，负责阶段推进、阻断判断、循环状态同步。

## Authoritative stage order

not-started → idea-exploration → idea-validation → literature-review → synthesis → hypothesis-generation → experiment-design → experiment-run → result-analysis → writing → figure-generation → citation-verification → peer-review → codex-review → final-review → export → completed

## Inputs

- `.arc/state/pipeline-status.json`
- `.arc/state/review-*.json`
- `.arc/env.json`
- slash command 参数（run/resume/loop）

## Reviewer set (must stay consistent)

- idea-validator
- novelty-checker
- literature-reviewer
- logic-checker
- stat-auditor
- figure-auditor
- citation-verifier
- peer-reviewer-1
- peer-reviewer-2
- devils-advocate
- multi-agent-debate
- final-reviewer

## Core contracts

1. 任何阶段推进前先读 `pipeline-status.json`。
2. 有 blocking issue 时不得推进。
3. reviewer subagents 只读审查，输出 `.arc/state/review-*.json`。
4. 跨轮次状态仅通过 `.arc/state/*.json` 与 `.arc/loop-logs/*`。

## Stage transition rules

- run: 从当前 stage 或 not-started 启动
- resume: 从中断 stage 恢复
- reset: 仅重置指定阶段及其下游相关状态
- export: 仅在 final-review pass 后允许

## Loop integration

- idea-loop `MAX_ITER=3`
- review-loop `MAX_ITER=4`
- figure-loop `MAX_ITER=5`
- citation-loop `MAX_ITER=3`

review-loop 需支持“连续两轮分数下降 -> human-intervention-needed”。

## Blocking gate examples

- env 未验证（`compute.validated=false`）
- review-final 未通过
- 引用/图表/字数未达标
- 关键 reviewer 输出含 blocking

## Synchronization points

必须与以下文件保持一致：
- `docs/pipeline-states.md`
- `src/commands/paper-run.md`
- `src/skills/arc-state-management/SKILL.md`
- `src/arc/state/pipeline-status.json`

## Failure handling

- 状态文件缺失：写入阻断原因并停止推进
- reviewer 输出不合法：标记 fail，要求重跑对应审查
- loop 达到 max_iter：状态记为 `max-iter-reached`

## Output expectations

- 更新 `pipeline-status.json`：`stage`、`stages_completed`、`last_updated`、`loop_status`
- 写入必要 loop logs
- 对用户输出当前阶段与阻断摘要

## Notes

- 本 skill 负责编排，不直接替代具体实验/写作/引用处理 skill。
- 所有门控值必须与 `src/CLAUDE.md`、hooks、docs 保持一致。
