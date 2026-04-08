---
name: arc-latex-formatting
description: Enforces venue-compatible LaTeX structure, figure/citation wiring, and compile correctness for final submission artifacts. Use when preparing templates, validating TeX integrity, and ensuring export-ready PDF generation.
---

# Arc LaTeX Formatting

## Purpose

确保论文源文件满足目标期刊/会议模板约束，并能稳定完成本地编译链。

## Inputs

- `draft.tex`
- `references.bib`
- 图表文件目录（如 `figures/` 或 `.arc/figures/rendered/`）
- 目标模板（`src/skills/arc-latex-formatting/templates/*`）

## Compile chain (authoritative)

`pdflatex -> bibtex -> pdflatex -> pdflatex`

要求：
- 编译命令 exit code 必须为 0
- 生成 PDF 必须非空

## Formatting checks

1. 章节结构完整性（6 个必要章节）
2. 图表引用完整性：`\includegraphics{}` 对应实体文件
3. 参考文献引用完整性：`\cite{}` 与 bib key 一致
4. 模板兼容性：文档类、宏包与目标 venue 匹配
5. 禁止明显占位文本残留（TODO/TBD）

## Integration with hooks

- `post-write-latex-check.sh` 提供写后快速反馈。
- `paper-export` 阶段执行完整编译链作为最终门控。

## Failure policy

- 编译失败 -> blocking issue
- 图表路径失效 -> blocking issue
- bib key 失配 -> major/blocking（视覆盖范围）

## Output expectations

- 修复建议（按优先级）
- 可复现编译步骤
- 对应 issue 定位（章节/行附近）

## Template handling

- 选择模板时保持最小改动原则，不破坏已有内容语义。
- 特定 venue 样式改动需可回滚且可追踪。

## Handoff criteria

进入 `paper-export` 前应满足：
- [ ] LaTeX 全链编译通过
- [ ] PDF 非空
- [ ] 图表/引用链接完整
- [ ] 结构与模板规范一致

## Notes

- 本 skill 关注“格式与可编译性”，不替代统计/引用真实性审查。
