---
name: arc-idea-exploration
description: Explores, diversifies, and ranks candidate research ideas with novelty validation before committing to downstream execution. Use when generating alternatives, checking repetition risk, and selecting an idea that passes novelty and feasibility thresholds.
---

# Arc Idea Exploration

## Purpose

`arc-idea-exploration` 用于在 pipeline 前段建立“高质量 idea 候选池”，并避免重复探索历史失败方向。

## Inputs

- 用户提供的初始 idea / 研究主题
- `.arc/memory/idea-history/MEMORY.md`
- `.arc/env.json`（用于判断 API 状态）
- 现有 `.arc/state/idea.json`（若是 resume 场景）

## Outputs

- 更新后的 `.arc/state/idea.json`
- 每轮日志：`.arc/loop-logs/review-rounds/idea-round-{N}.json`
- novelty/idea reviewer 的输入材料

## Diversity requirements

每轮候选集合必须覆盖至少两个创新维度，例如：
- 方法创新（新架构/新训练策略）
- 数据创新（新数据构建/数据利用方式）
- 任务定义创新（新问题设定）
- 评估创新（新指标/新评测框架）

## Novelty protocol

1. 使用 Semantic Scholar 做查新（API 可用时）。
2. 若 API 缺失，显式标记 degraded，不得静默跳过。
3. 将候选与近似已有工作进行差异化对比。

## Loop contract

- `MAX_ITER=3`
- 每轮流程：
  1. 生成候选 ideas
  2. novelty-checker 查新
  3. idea-validator 评分
  4. 排名与筛选
  5. 写 round 日志
- 提前终止条件：任一 idea `score >= 80` 且 novelty 通过

## Ranking formula

优先级按综合分排序：

`rank_score = novelty × feasibility × impact`

并结合风险提示：
- 资源不可行（计算/数据）
- 可验证性弱
- 与历史失败方向高重合

## Anti-repetition

- 在每轮开始前读取 idea-history。
- 命中“已探索且失败”方向时应降权或跳过。
- 如必须复用历史方向，需要给出明确新证据（新方法/新数据/新评估）。

## Blocking conditions

以下情况不能推进到 idea-validation：
- 候选缺乏明显新颖性
- 候选不可执行（资源或数据不可得）
- 候选无法形成可验证假设

## Integration points

- 与 `novelty-checker` subagent 配合输出 `review-novelty.json`
- 与 `idea-validator` subagent 配合输出 `review-idea.json`
- 为 `arc-research` 和 `arc-experiment` 提供目标问题定义

## Suggested round log fields

- `round`
- `candidates`
- `diversity_dimensions`
- `novelty_results`
- `validator_scores`
- `selected_idea`
- `stop_reason`

## Notes

- 该 skill 聚焦“选题质量”，不直接产出实验结果。
- 输出必须可回放（可追踪每轮为何保留/淘汰）。
