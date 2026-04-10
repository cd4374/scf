# Hook Contracts

## 通用约定

- 输入：stdin JSON（Claude tool call payload）
- 触发：由 `.claude/settings.json` 的 matcher 控制
- 非目标文件：必须快速 `exit 0`
- 阻断：`exit 2` 且 stdout 输出 JSON：`{"decision":"block","reason":"..."}`
- 放行：`exit 0`
- 路径：使用 `$CLAUDE_PROJECT_DIR`（禁止硬编码绝对路径）
- JSON 读取：优先 `jq`，回退 Python 时保持字段语义一致

## Exit Code 语义

- `0`：允许继续
- `2`：阻断（必须同时输出 block JSON）

## Hook 列表与契约

### 1) `pre-write-gate.sh`
- 事件：PreToolUse
- matcher：`Write|Edit|MultiEdit`
- 输入关键字段：`.tool_input.file_path`
- 行为：
  - 非 `draft.tex` 写入直接放行
  - 读取 `.arc/state/pipeline-status.json.active_agent`
  - 若 active_agent 属于 reviewer 列表，阻断并输出 block JSON
- 副作用：无

### 2) `post-write-page-count.sh`
- 事件：PostToolUse
- matcher：`Write|Edit|MultiEdit`
- 输入关键字段：`.tool_input.file_path`
- 行为：
  - 仅对 `draft.tex` 生效
  - 基于编译结果/状态统计页数并写回 `.arc/state/pipeline-status.json`
  - 读取 `.arc/paper-type.json.page_limit` 进行页数门控（不足给警告，超限阻断）
  - 更新：`page_count`、`last_updated`
- 副作用：更新 pipeline state

### 3) `post-write-section-check.sh`
- 事件：PostToolUse
- matcher：`Write|Edit|MultiEdit`
- 输入关键字段：`.tool_input.file_path`
- 行为：
  - 仅对 `draft.tex` 生效
  - 检查必要章节：Abstract/Introduction/Method(or Theory)/Experiments(or Results)/Limitations/Conclusion/References
  - 当 `require_ablation=true` 时额外检查 Ablation 章节
  - 缺失项写入 pipeline state 的阻断信息
- 副作用：更新 pipeline state

### 4) `post-write-figure-check.sh`
- 事件：PostToolUse
- matcher：`Write|Edit|MultiEdit`
- 输入关键字段：`.tool_input.file_path`
- 行为：
  - 仅对 `draft.tex` 生效
  - 检查 `\includegraphics{}` 是否对应真实文件
  - 更新 `figure_count` 和图表相关阻断信息
- 副作用：更新 pipeline state

### 5) `post-write-table-check.sh`
- 事件：PostToolUse
- matcher：`Write|Edit|MultiEdit`
- 输入关键字段：`.tool_input.file_path`
- 行为：
  - 仅对 `draft.tex` 生效
  - 从 `.arc/paper-type.json` 读取 `min_tables`
  - 检查正文表格数量与结果对比表存在性
  - 不达标给警告（不阻断）
- 副作用：更新 pipeline state 中 `table_count`

### 6) `post-write-citation-check.sh`
- 事件：PostToolUse
- matcher：`Write|Edit|MultiEdit`
- 输入关键字段：`.tool_input.file_path`
- 行为：
  - 对 `draft.tex` / `references.bib` 生效
  - 执行 Layer-1 快速检查（author/title/year/venue 完整性）
  - 同步统计写入 state
- 副作用：更新 pipeline state

### 7) `post-write-stat-check.sh`
- 事件：PostToolUse
- matcher：`Write|Edit|MultiEdit`
- 输入关键字段：`.tool_input.file_path`
- 行为：
  - 仅对 `draft.tex` 生效
  - 从 `.arc/paper-type.json` 读取 `paper_domain` 和 `require_ablation`
  - 检测有数字无误差报告、cherry-picking 信号词、缺失消融（按条件）
  - 仅告警，不阻断
- 副作用：无阻断写入

### 8) `post-write-latex-check.sh`
- 事件：PostToolUse
- matcher：`Write|Edit|MultiEdit`
- 输入关键字段：`.tool_input.file_path`
- 行为：
  - 对 `draft.tex` 生效
  - 执行本地编译探测（快速失败输出 stderr）
  - 不直接覆盖导出阶段完整编译流程
- 副作用：写入编译错误摘要到 state（如实现）

### 9) `post-write-ai-pattern-check.sh`
- 事件：PostToolUse
- matcher：`Write|Edit|MultiEdit`
- 输入关键字段：`.tool_input.file_path`
- 行为：
  - 对正文写入检测 AI 写作模式词
  - 输出警告，不阻断
- 副作用：更新 `ai_pattern_warnings`

### 10) `loop-progress-log.sh`
- 事件：PostToolUse
- matcher：`Write|Edit|MultiEdit`
- 输入关键字段：`.tool_input.file_path`
- 行为：
  - 依据当前 loop 状态写入 `.arc/loop-logs/*` 轮次日志
- 副作用：追加 loop 日志文件

### 11) `pre-experiment-gate.sh`
- 事件：PreToolUse
- matcher：`Bash`
- 输入关键字段：`.tool_input.command`
- 行为：
  - 仅拦截实验运行命令
  - 检查 `.arc/env.json` 且 `compute.validated == true`（不满足则阻断）
  - 检查 `.arc/paper-type.json` 是否存在（缺失告警）
  - 尝试检测实验脚本随机种子声明（缺失告警）
- 副作用：无

### 12) `stop-gate.sh`
- 事件：Stop
- matcher：空字符串
- 行为：
  - 读取 `review-final.json`、`review-integrity.json`、`review-stat.json`、`pipeline-status.json`、`draft.tex`、`references.bib`
  - 核查：最终审查通过、页数、章节、图表、引用数量与近5年比例（阈值均来自 `.arc/paper-type.json`）
  - 读取 `.arc/env.json` 并检查 `compute.validated`
  - 若 `compute.mode==ssh`，检查 `active_experiments` 未收集结果提示
  - 有阻断项时返回 `exit 2 + block JSON`
- 副作用：无文件写入，主要为终止前门控
