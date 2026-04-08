# Adding Agents

## 1) 新建 agent 文件

在 `src/agents/` 下创建 `<agent-name>.md`。

## 2) frontmatter 必填字段

```yaml
---
name: <agent-name>
description: <when-called + what-reviewed>
tools: Read, Glob, Grep
model: sonnet
memory: project
---
```

约束：
- `name` 必须与文件名一致（不含 `.md`）
- `tools` 仅允许 `Read/Glob/Grep` 的子集
- 不得出现 `Write/Edit/MultiEdit/Bash`

## 3) 正文必含内容

- 输入文件路径（必须明确）
- 输出文件路径（必须是 `.arc/state/review-*.json`）
- 输出 JSON 示例（字段与统一 schema 对齐）
- 明确声明 reviewer 不得写 `draft.tex`

## 4) 一致性联动更新

新增 reviewer 后必须同时更新：
- `src/commands/paper-review-loop.md` 参数/流程说明
- `src/arc/hooks/pre-write-gate.sh` 的 `REVIEWER_AGENTS`
- `src/skills/arc-pipeline/SKILL.md` reviewer 列表
- 如涉及新输出，补充 `src/arc/state/review-*.json` 模板

## 5) 输出 schema 对齐

输出至少包含：
- `agent`
- `timestamp`
- `pass`
- `score`
- `decision`
- `issues[]`
- `strengths[]`
- `summary`

并满足：
- `pass=false` 时必须有至少一个 `severity=blocking` issue

## 6) 验证

```bash
bash tests/test-hooks.sh
bash validate.sh --target <installed-project>
```
