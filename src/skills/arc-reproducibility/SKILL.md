---
name: arc-reproducibility
description: Enforces reproducibility artifacts and validation steps across experiment and export phases. Use when recording seeds, environment snapshots, dataset versions, and reproduction checks before final delivery.
---

# Arc Reproducibility

## Purpose

`arc-reproducibility` 确保他人可在独立环境中复现实验结果，并验证误差在可接受范围内。

## Inputs

- 训练/评估代码
- 结果文件（结构化 JSON）
- `.arc/env.json`
- 数据源与版本信息

## Required artifacts

- `.arc/state/reproducibility.json`
- `.arc/environment.yml`
- `requirements.txt`
- 随机种子记录
- 数据版本记录
- 复现实验摘要

## Mandatory rules

1. 固定随机种子（例如 `np.random.seed(42)` 或等效）
2. 记录环境快照路径：`.arc/environment.yml`
3. 记录数据版本与获取方式
4. 至少执行 1 次复现实验
5. 复现实验结果偏差控制在 ±5%
6. Experiments 节必须包含 Reproducibility Statement

## State schema expectations

`reproducibility.json` 至少包含：
- `random_seeds`
- `datasets`
- `environment_snapshot_path`
- `sanity_check_passed`

## Procedure

1. 从实验代码提取或声明随机种子策略。
2. 更新/校验 `requirements.txt` 与 `.arc/environment.yml`。
3. 记录数据集名称、版本、分割方式、访问路径。
4. 执行最小复现实验并计算与主结果偏差。
5. 将结果写入 reproducibility 状态文件。

## Blocking conditions

- 无种子记录
- 无环境快照
- 无数据版本信息
- 复现实验偏差 > ±5%

## Integration points

- 与 `arc-experiment` 联动记录运行配置
- 与 `paper-export` 联动打包 reproducibility-bundle
- 与 `final-reviewer` 联动作为放行条件之一

## Export linkage

导出阶段应包含：
- 代码
- 环境快照
- 依赖清单
- 数据引用
- 复现说明文档

## Notes

- 可重复性不是附加项，而是主门控的一部分。
- 若资源受限导致无法完整复现，必须明确记录范围和限制。
