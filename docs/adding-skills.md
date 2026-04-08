# Adding Skills

## 1) 创建目录与文件

在 `src/skills/<skill-name>/SKILL.md` 创建新 skill。

## 2) frontmatter 规范

必须包含：
- `name`（小写连字符）
- `description`（说明做什么 + 何时激活）

禁止包含：
- `allowed-tools`

## 3) 正文规范

- 至少一个 `##` 二级标题
- 明确输入、步骤、输出路径
- 明确与 `.arc/state/*.json`、`.arc/env.json` 的联动（如适用）

## 4) 一致性更新

- 如新增 loop/gate 或状态字段，更新：
  - `src/skills/arc-state-management/SKILL.md`
  - `docs/pipeline-states.md`
  - 相关 command 文档

## 5) 验证

```bash
bash validate.sh --target <installed-project>
bash tests/test-auto-loops.sh
```
