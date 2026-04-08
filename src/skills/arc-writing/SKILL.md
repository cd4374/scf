---
name: arc-writing
description: Produces and revises manuscript drafts under hard academic quality gates. Use when building section structure, integrating evidence-backed claims, and iterating through review feedback before final export.
---

# Arc Writing

## Purpose

`arc-writing` 负责把研究结果组织为符合投稿要求的论文文本，并持续迭代到门控通过。

## Mandatory quality gates

- 正文字数 `>=6000`（不含参考文献）
- 必要章节：Abstract / Introduction / Related Work / Method / Experiments / Conclusion
- 图表数量 `>=4` 且实体文件存在
- 引用满足四层验证与数量/时效门槛
- LaTeX 可无错编译
- 数字结论必须来自真实实验

## Inputs

- `.arc/state/pipeline-status.json`
- `.arc/state/idea.json`
- 实验结果与分析结论
- `.arc/state/review-*.json`
- `references.bib`

## Outputs

- `draft.tex`
- 写作阶段相关状态更新（word_count、blocking_issues）

## Draft protocol

1. 生成大纲并映射到必须章节。
2. 每个核心 claim 绑定证据来源（实验结果或文献）。
3. 合并图表与引用，确保文图引一致。
4. 保持术语、符号、实验设置在全文一致。

## Review-loop integration

- 输入 `peer-reviewer-1/2` 与 `devils-advocate` 反馈。
- 每轮仅修复优先级最高问题，避免全量重写。
- 保留修订理由，便于后续 final-review 追溯。

## Anti-fabrication rules

- 未运行实验不得生成具体数值结论。
- 未验证引用不得作为关键论据。
- 对不确定结果使用保守表述并标注限制。

## Reproducibility linkage

Experiments 节必须包含 Reproducibility Statement，说明：
- 随机种子策略
- 环境快照位置（`.arc/environment.yml`）
- 数据版本记录位置（`.arc/state/reproducibility.json`）

## Failure conditions

以下情况不得推进到 export：
- blocking issue 未清零
- 字数/章节/图表/引用门槛未达标
- LaTeX 编译失败

## Style constraints

- 优先清晰、简洁、可验证表述。
- 避免夸大措辞与空泛“AI 味”模板表达。

## Expected handoff

写作阶段完成后，应可直接进入：
- `paper-review-loop`
- `paper-citation-loop`
- `paper-figure-loop`
- `paper-export`（在全部门控通过后）

## Minimal completion checklist

- [ ] 必要章节齐全
- [ ] 关键 claims 全部有证据映射
- [ ] 图表和引用计数达标
- [ ] 可重复性声明已写入
- [ ] 编译检查通过
