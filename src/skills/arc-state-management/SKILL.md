---
name: arc-state-management
description: Maintains JSON state contracts as the cross-agent and cross-session source of execution truth. Use when validating, updating, and synchronizing pipeline, review, loop, and reproducibility state files.
---

# Arc State Management

## Purpose

`arc-state-management` 定义 `.arc/state/*.json` 的协议，确保命令、skills、agents 在同一状态模型上协作。

## State bus contract

- 跨 agent / 跨会话状态只能通过 `.arc/state/*.json` 传递
- 不依赖对话上下文作为状态源

## Required pipeline stage values

- not-started
- idea-exploration
- idea-validation
- literature-review
- synthesis
- hypothesis-generation
- experiment-design
- experiment-run
- result-analysis
- writing
- figure-generation
- citation-verification
- peer-review
- codex-review
- final-review
- export
- completed

## Required files

- `pipeline-status.json`
- `idea.json`
- `reproducibility.json`
- `review-idea.json`
- `review-novelty.json`
- `review-literature.json`
- `review-logic.json`
- `review-stat.json`
- `review-figures.json`
- `review-citations.json`
- `review-peer-1.json`
- `review-peer-2.json`
- `review-devil.json`
- `review-debate.json`
- `review-codex.json`
- `review-final.json`

## pipeline-status.json required fields

- `stage`
- `journal`
- `word_count`
- `word_count_ok`
- `figure_count`
- `active_agent`
- `stages_completed`
- `last_updated`
- `loop_status`
- `ai_pattern_warnings`
- `active_experiments`

## loop_status schema

```json
{
  "idea_loop": {
    "current_round": 0,
    "max_rounds": 3,
    "best_score": 0,
    "status": "not-started|running|completed|max-iter-reached"
  },
  "review_loop": {
    "current_round": 0,
    "max_rounds": 4,
    "best_score": 0,
    "score_history": [],
    "status": "not-started|running|completed|max-iter-reached|human-intervention-needed"
  },
  "figure_loop": {
    "current_round": 0,
    "max_rounds": 5,
    "figures": {},
    "status": "not-started|running|completed|max-iter-reached"
  },
  "citation_loop": {
    "current_round": 0,
    "max_rounds": 3,
    "verified_count": 0,
    "hallucinated_count": 0,
    "status": "not-started|running|completed|max-iter-reached"
  }
}
```

## Review schema baseline

每个 `review-*.json` 应满足统一结构：
- `agent`
- `timestamp`
- `pass`
- `score`
- `decision`
- `issues[]`
- `strengths[]`
- `summary`

约束：`pass=false` 时至少一个 `issues[].severity=blocking`。

## Update rules

1. 所有状态更新应保持 JSON 合法性。
2. 仅更新必要字段，避免覆盖无关状态。
3. 关键阶段切换必须同步 `last_updated` 与 `stages_completed`。
4. loop 轮次日志与 loop_status 必须同步。

## Consistency matrix

以下内容必须一致：
- stage 列表：commands/docs/skills/state 模板
- reviewer 名称：commands/hooks/agents/skills
- loop 参数：CLAUDE.md/commands/docs

## Failure handling

- 文件缺失：创建或恢复模板并记录 warning
- JSON 不合法：停止推进并返回 blocking issue
- 字段缺失：填默认值并记录兼容修复说明

## Integration points

- `arc-pipeline`：阶段推进与阻断状态
- `arc-experiment`：active_experiments
- `arc-citation-style`：citation loop 统计
- hooks：字数/章节/图表/AI 警告回写

## Notes

- 状态文件是系统“事实层”，所有门控判断应优先依赖它。
- 对状态的任何写入都必须可追踪、可复核。
