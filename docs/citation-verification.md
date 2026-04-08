# Citation Verification

四层引用验证（Layer 1-4）：

1. **Layer 1 字段完整性**
   - 检查 bib 条目含 `author/title/year/venue`
2. **Layer 2 存在性验证**
   - DOI resolver 或 arXiv API 验证引用真实存在
3. **Layer 3 交叉验证**
   - Semantic Scholar 对 author/title/year 交叉一致性检查
4. **Layer 4 语义关联**
   - 引用与其支持 claim 的相关性验证

## 幻觉引用处理

- Layer 2 或 3 任一失败：标记 `HALLUCINATED`
- 强制删除该条目，并重新执行验证循环

## 数量门槛

- 引用总数：`>=20`
- 近五年占比：`>=60%`

## 正文一致性

- `references.bib` 中条目必须在 `draft.tex` 中有 `\cite{}` 使用
- 发现孤立 bib 条目必须清理或补正文引用依据

## 状态输出

验证结果写入 `.arc/state/review-citations.json`，并记录：
- 每条引用层级通过情况
- `verified_count`
- `hallucinated_count`
- 阻断 issue 列表
