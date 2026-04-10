# scf - Scientific Paper Framework

## 1. 项目愿景

**让高质量学术论文的产出自动化。**

scf 是一个基于 Claude Code 的自动化论文工程框架，目标是将一个研究想法（idea）推进为一篇**高质量、可验证、可重复、真实**的学术论文。

核心设计原则：
- **质量阻断式门控**：不符合标准即阻断，不妥协
- **只读审查**：Reviewer agents 只审查不修改，防止"幻觉污染"
- **状态驱动**：跨会话状态通过结构化 JSON 传递，不依赖模型记忆
- **单一真相源**：`.arc/env.json` 存储环境配置，`.arc/state/*.json` 存储流水线状态

质量标准详见 `paper_standards.md`。

---

## 2. 项目使用手册

### 2.1 安装

```bash
/path/to/scf/install.sh \
  --target /path/to/your-paper-project \
  --journal neurips \
  --project-name myproject
```

支持的参数：
- `--target`: 目标项目路径
- `--journal`: 期刊/会议模板 (neurips, icml, iclr, acl, aaai, ieee, nature, prl, custom)
- `--project-name`: 项目名称
- `--max-review-rounds`: 最大审查轮数（默认4）
- `--skip-env-probe`: 跳过环境探测
- `--ssh-host`: SSH 主机配置

### 2.2 初始化论文配置

```bash
cd /path/to/your-paper-project
claude
/paper:init --format long --domain ai-experimental --venue NeurIPS --pages 9
```

支持的参数：
- `--format`: `long` | `short` | `letter`
- `--domain`: `ai-experimental` | `ai-theoretical` | `physics` | `numerical`
- `--venue`: 目标期刊/会议
- `--pages`: 页数限制

### 2.3 运行完整流水线

```bash
/paper:run --idea "A robust low-resource reasoning method" --max-review-rounds 4
```

`paper:run` 会自动：
1. 检查环境配置 (`.arc/env.json`)
2. 读取质量门控阈值 (`.arc/paper-type.json`)
3. 启动多轮审查迭代，直到达标或达到最大轮数

### 2.4 状态查看

```bash
/paper:status
```

### 2.5 专项循环

```bash
/paper:idea-loop     # 迭代优化想法（MAX_ITER=3）
/paper:review-loop   # 迭代审查改进（MAX_ITER=4）
/paper:figure-loop   # 迭代图表优化（MAX_ITER=5）
/paper:citation-loop # 迭代引用完善（MAX_ITER=3）
```

### 2.6 验证与导出

```bash
# 验证项目完整性
/path/to/scf/validate.sh --target /path/to/your-paper-project

# 验证环境配置
/path/to/scf/validate.sh --target /path/to/your-paper-project --full-env-check

# 导出最终论文
/paper:export
```

### 2.7 卸载

```bash
/path/to/scf/uninstall.sh --target /path/to/your-paper-project
```

---

**项目验收口径**：以 `PROJECT_SPEC.md` 为唯一标准。
