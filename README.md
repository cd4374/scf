# scf Paper Framework

自动化生成高质量、可验证、可重复的学术论文框架。

## 快速开始

```bash
# 1. 安装到你的论文项目目录
cd /path/to/your-paper-project
/path/to/arc-harness/install.sh --journal neurips

# 2. 在 Claude Code 中运行
/paper:run --idea "你的研究问题" --journal neurips
```

## 命令

| 命令 | 说明 |
|------|------|
| `/paper:run` | 启动/继续论文生成流程 |
| `/paper:status` | 查看当前状态和阻塞问题 |
| `/paper:resume` | 从中断处继续 |
| `/paper:review [类型]` | 触发审查 (idea/literature/logic/stat/figures/final) |
| `/paper:reset [阶段]` | 重置指定阶段或全部状态 |
| `/paper:export` | 打包最终论文 |

## 工作流程

```
idea-validation → literature-review → synthesis → experiment-design
    → experiment-run → result-analysis → writing → peer-review
    → final-review → export
```

## 质量门槛

- 正文 ≥ 6000 词
- 必须章节: Abstract, Introduction, Related Work, Method, Experiments, Conclusion
- 图表 ≥ 4 张，每张必须有对应文件
- 所有引用必须在 references.bib 中完整
- LaTeX 必须编译成功

## 审查机制

6 个独立的审查 subagent（只读，不修改论文）：

- `idea-validator` — 研究想法可行性
- `literature-reviewer` — 文献覆盖度
- `logic-checker` — 逻辑一致性
- `stat-auditor` — 统计方法审计
- `figure-auditor` — 图表质量
- `final-reviewer` — 综合验收

## 卸载

```bash
/path/to/arc-harness/uninstall.sh
```

## 验证

```bash
./validate.sh
```
