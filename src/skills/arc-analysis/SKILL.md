---
name: arc-analysis
description: Evaluates experiment outcomes and constructs claim-to-evidence mappings for paper decisions. Use when validating statistical soundness, resolving unsupported claims, and preparing structured review inputs for downstream gates.
---

# Arc Analysis

## Scope

`arc-analysis` 负责把实验结果转化为可审查、可追溯的论文证据。

核心任务：
- 结果统计与一致性检查
- claim-to-evidence 映射
- 失败模式识别与阻断问题输出

## Inputs

- `.arc/state/pipeline-status.json`
- `.arc/state/idea.json`
- 实验结果 JSON（建议 `results/latest.json` 或等价结构化产物）
- `draft.tex`（只读，用于定位 claim）
- `.arc/state/reproducibility.json`

## Output contracts

- `.arc/state/review-stat.json`（统计审查结果）
- 必要时更新 `.arc/state/pipeline-status.json.blocking_issues`

## Procedure

1. 读取实验结果主文件，确认指标字段完整（指标值、配置、时间戳）。
2. 抽取草稿中的核心 quantitative claims。
3. 建立 claim -> evidence 映射表：每条 claim 必须能对应实验结果中的具体字段或图表来源。
4. 校验统计一致性：
   - 指标方向是否与文中叙述一致
   - 关键比较是否有基线或消融支持
   - 数值是否超出合理范围（明显异常值）
5. 生成问题清单，按 `blocking | major | minor` 分级。
6. 将结构化结论写入 `review-stat.json`，供后续 review-loop/final-review 使用。

## Blocking rules

以下情况应标记 blocking：
- 关键 claim 无可追溯证据
- 文中数值与结果文件不一致
- 复现实验失败且偏差超过可接受范围（通常 ±5%）
- 统计结论依赖不存在的实验

## Severity guidance

- blocking：影响结论真实性或可验证性
- major：影响可信度但可通过补实验修复
- minor：表述或局部统计格式问题

## Integration points

- 与 `arc-reproducibility` 联动：读取种子、环境快照、数据版本记录。
- 与 `arc-writing` 联动：将 unsupported claims 反馈给写作修订。
- 与 `final-reviewer` 联动：输出用于综合裁决。

## Quality gates linkage

分析结论必须支持以下门控：
- 实验结果真实性（无捏造）
- claim-evidence 可追溯
- 与图表/引用的一致性

## Failure handling

- 输入文件缺失时，输出 `pass=false`，并给出明确缺失项位置。
- 遇到格式不合法数据时，不静默跳过，记录为 issue。

## Output JSON template

```json
{
  "agent": "stat-auditor",
  "timestamp": "ISO-8601",
  "pass": false,
  "score": 62,
  "decision": "major",
  "issues": [
    {
      "location": "Section 4.2",
      "type": "unsupported_claim",
      "description": "Claimed +6.1% gain has no matching metric entry in results JSON.",
      "severity": "blocking"
    }
  ],
  "strengths": ["Ablation structure is clear"],
  "summary": "Main claim-evidence mismatch must be fixed before final review."
}
```

## Notes

- 保持输出简洁、结构化，优先支持自动门控和后续循环修复。
- 不在本 skill 内直接改写论文正文，仅输出审查结论和修复方向。
