# scf: Project Alignment

本文件用于说明 `scf/` 的项目目标与核查口径，不作为安装后运行时指令文件。

## 核心目标

`scf/` 必须支持从 idea 自动推进到论文交付，并满足以下硬标准：

1. 高质量：结构完整、逻辑自洽、可提交格式
2. 可验证：引用真实可查、LaTeX 可编译、结论可追溯
3. 可重复：环境、代码、种子、数据版本可复现实验
4. 真实性：实验数字来自真实运行，不得捏造

## 规范优先级

- 实现验收以 `PROJECT_SPEC.md` 为准。
- 安装后写入目标项目的运行时宪法以 `src/CLAUDE.md` 为准。
- 若 README/docs 与 `PROJECT_SPEC.md` 冲突，以 `PROJECT_SPEC.md` 为准。

## v4 环境架构约束

- `.arc/env.json` 是环境唯一真相（single source of truth）。
- 环境配置不在 CLAUDE.md 中展开，不注入 SSH/key/conda 等细节。
- hooks 与 scripts 读取 env 必须走结构化字段（jq/json），不得解析 markdown。

## 实施边界

- 编排逻辑在 slash commands 与 skills 中，不依赖 Python/JS 编排器。
- 质量门控由 hooks 强制执行，不依赖模型记忆。
- reviewer subagents 保持只读（Read/Glob/Grep）。
- 跨会话状态统一通过 `.arc/state/*.json` 传递。

## 建议核查入口

- 全量核查：对照 `PROJECT_SPEC.md` 逐章输出 PASS/FAIL/PARTIAL。
- 环境专项核查：重点检查第十一章（env schema / probe / validate / 联动）。
- 回归验证：`tests/*.sh` + `validate.sh`（含 `--full-env-check`）。
