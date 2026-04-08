---
name: arc-figure-codegen
description: Generates reproducible paper figures from code and runs iterative visual audits to reach publication-quality outputs. Use when rendering charts, diagnosing visual defects, and improving figures under bounded loop controls.
---

# Arc Figure Codegen

## Purpose

`arc-figure-codegen` 负责将实验结果转为可重复、可审查的图表资产，并通过视觉审查循环提升质量。

## Inputs

- 实验结果文件（结构化 JSON/CSV）
- 图表生成代码
- 目标论文图表需求（数量、类型、章节对应）

## Outputs

- 版本化图表文件：`fig_N_v{iter}.pdf/png`
- 图表审查结果：`review-figures.json`（由 figure-auditor 消费）
- figure-loop 轮次日志：`.arc/loop-logs/figure-rounds/figure-round-{N}.json`

## Generation contract

- 必须从代码渲染，不允许手工截图替代。
- 分辨率不少于 300 DPI。
- 每轮保留版本，不覆盖历史文件。
- 图表与正文引用必须可对应。

## Visual audit dimensions (5)

1. 准确性（数据映射正确）
2. 可读性（字号、线宽、标签）
3. 无截断（坐标轴、图例、标题完整）
4. 色彩可访问性（避免不可区分配色）
5. 标题/说明完整（含必要上下文）

## Loop controls

- `MAX_ITER=5`
- `SCORE_THRESHOLD=8.0`
- 每轮只修复 top-3 问题，避免整体重写

## Recommended round process

1. 渲染当前版本图表
2. 调用审查（VLM 或 figure-auditor）
3. 汇总 top-3 问题
4. 定向修改图表代码
5. 重新渲染并记录分数变化
6. 更新 loop_status.figure_loop

## Blocking conditions

- 图表数量不足（<4）
- 图表文件缺失或路径失效
- 核心图表分数长期低于阈值且达到 MAX_ITER

## Integration points

- 与 `post-write-figure-check.sh` 联动验证 `\includegraphics` 文件存在性
- 与 `paper-figure-loop` 命令共享轮次与终止条件
- 与 `paper-export` 联动打包最终图表资产

## Suggested figure metadata

- `figure_id`
- `version`
- `source_data`
- `render_script`
- `score_breakdown`
- `issues_fixed`
- `timestamp`

## Notes

- 图表是论文主证据之一，必须可追溯到实验输出。
- 若图表与正文 claim 不一致，优先修正数据映射，再修美观问题。
