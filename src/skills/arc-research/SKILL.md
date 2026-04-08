---
name: arc-research
description: Runs literature-centered research workflow from topic framing through synthesis and hypothesis grounding. Use when collecting evidence-backed references, filtering noisy sources, and producing structured context for idea validation and experiment design.
---

# Arc Research

## Purpose

`arc-research` 将“想法”转为“有文献支撑的研究问题”。

目标：
- 建立系统化检索与筛选流程
- 形成可追溯知识提取结果
- 为 hypothesis 与实验设计提供依据

## Inputs

- `.arc/state/idea.json`
- 用户给定主题/关键字
- 已有参考文献库（若存在）
- `.arc/env.json` 中 API 状态（Semantic Scholar / arXiv）

## Outputs

- 文献候选集合（可导入 `references.bib`）
- 结构化知识摘要（问题、方法、数据、结果、局限）
- `.arc/state/review-literature.json` 的审查输入材料

## Workflow

1. Topic initialization
   - 明确研究问题与边界条件。
   - 生成核心关键词与同义扩展词。

2. Search strategy
   - 首选 Semantic Scholar + arXiv 查询。
   - API 缺失时记录 degraded 状态并显式提示。

3. Collection
   - 收集候选论文并保留来源元信息。
   - 去重并剔除明显无关结果。

4. Screening
   - 按相关性、质量、时间窗口筛选。
   - 保留可验证元信息（title/author/year/venue/identifier）。

5. Knowledge extraction
   - 提取每篇的核心贡献、实验设置、关键结果、局限性。
   - 标注与当前 idea 的关联程度。

6. Synthesis
   - 输出领域现状、空白点、冲突证据。
   - 给出可检验 hypothesis 候选。

## Quality constraints

- 不接受无法验证存在性的文献作为核心依据。
- 文献筛选必须保留可复核路径（查询词、筛选条件）。
- 输出必须能被 `arc-citation-style` 四层验证消费。

## Blocking conditions

- 核心主题缺乏足够文献支撑
- 大量候选缺少可验证标识（DOI/arXiv）
- 综述结论与证据不一致

## Integration points

- 与 `arc-idea-exploration`：用于 novelty 对比和反重复。
- 与 `arc-citation-style`：提供可验证引用候选。
- 与 `arc-analysis`：为后续 claim-evidence 映射提供文献证据链。

## Suggested data structure

推荐保存中间产物字段：
- query
- source
- title
- authors
- year
- venue
- doi_or_arxiv
- relevance_score
- notes

## Failure handling

- API 不可用：标记 degraded，并继续最低可行检索。
- 关键字段缺失：在输出中保留缺陷标记，不静默丢弃。

## Review handoff

文献阶段完成后，需可支持 reviewer 输出：
- novelty 是否足够
- related work 是否全面
- 是否存在遗漏关键先行工作

## Minimal acceptance criteria

- 有结构化候选文献集
- 有筛选依据
- 有可验证标识字段
- 有可直接进入写作与引用循环的结果
