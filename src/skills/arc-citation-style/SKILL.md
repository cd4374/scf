---
name: arc-citation-style
description: Enforces citation integrity with four-layer verification and bibliography consistency checks. Use when validating references, removing hallucinated entries, and ensuring citation quality gates for final submission.
---

# Arc Citation Style

## Purpose

`arc-citation-style` 保证引用真实、相关、格式一致，避免“幻觉引用”污染论文结论。

## Inputs

- `references.bib`
- `draft.tex`
- 外部验证接口状态（Semantic Scholar / DOI / arXiv）

## Outputs

- `.arc/state/review-citations.json`
- citation-loop 轮次日志
- 对 `draft.tex`/`references.bib` 的修订建议（由主 agent 执行）

## Four-layer verification

1. Layer 1 — 字段完整性
   - `author/title/year/venue` 全部存在
2. Layer 2 — 存在性验证
   - DOI resolver 或 arXiv API 确认论文存在
3. Layer 3 — 元信息交叉验证
   - Semantic Scholar 对 author/title/year 一致性复核
4. Layer 4 — claim 相关性验证
   - 引用是否真正支持其所在 claim

## Hallucination policy

- Layer 2 或 Layer 3 失败：标记 `HALLUCINATED`
- 该条目必须从可交付版本中删除
- 删除后重新计算引用数量与近五年占比

## Quantity gates

- 引用总数 `>=20`
- 近五年占比 `>=60%`

## Alignment checks

- bib 条目必须在正文有 `\cite{}` 使用
- 若正文引用缺失或孤立条目存在，必须修正

## Loop contract

`paper:citation-loop` 使用：
- `MAX_ITER=3`
- 每轮流程：验证 -> 删除幻觉 -> 补充缺失 -> 重验
- 每轮更新 verified/hallucinated 统计

## Severity policy

- blocking：幻觉引用、关键 claim 缺证据引用
- major：数量不足、近五年比例不足
- minor：格式或局部一致性问题

## Integration points

- 与 `citation-verifier` subagent 保持协议一致
- 与 `docs/citation-verification.md` 四层定义一致
- 与 `final-reviewer` 的质量门控一致

## Suggested review output fields

- `citations[]`（每条 Layer 1-4 结果）
- `verified_count`
- `hallucinated_count`
- `issues[]`
- `summary`

## Notes

- 引用完整性是强门控，不允许“先过后补”。
- API 不可用时必须显式 degraded，不能伪装为通过。
