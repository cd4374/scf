# Cross-model Review

目标：在关键审查阶段执行跨模型对抗审查，降低单模型自证偏差。

## `/paper:codex-review` 行为

1. 检查 Codex MCP 是否可用。
2. 可用时：并行执行方法/实验/写作/引用四路外部审查。
3. 不可用时：降级到 `multi-agent-debate`，并标记 `cross_model: degraded`。
4. 输出写入 `.arc/state/review-codex.json`。
5. 展示审查结果并等待用户确认再继续流程。

## 输出要求

`review-codex.json` 至少包含：
- `agent`
- `timestamp`
- `pass`
- `score`
- `decision`
- `issues[]`
- `summary`
- `cross_model: codex | degraded`

## 失败处理

- 若外部审查发现 blocking issue，不推进到 final-review/export。
- 降级模式需在状态与汇报中显式提示，避免“静默降级”。
