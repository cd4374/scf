# scf Paper Framework

scf（Scientific Paper Framework）用于把研究 idea 推进为高质量、可验证、可复现的论文工程。

## 验收口径

项目实现以 `PROJECT_SPEC.md` 为唯一核查标准。建议每轮迭代后执行逐章 PASS/FAIL/PARTIAL 核查。

## 快速安装

```bash
/path/to/scf/install.sh \
  --target /path/to/your-paper-project \
  --journal neurips \
  --project-name myproject
```

支持参数：
- `--target`
- `--journal`
- `--max-review-rounds`
- `--skip-env-probe`
- `--ssh-host`
- `--project-name`

## 完整运行示例

```bash
cd /path/to/your-paper-project
claude
/paper:status
/paper:run --idea "A robust low-resource reasoning method" --journal neurips --max-review-rounds 4
```

`/paper:run` 在开始前会读取 `.arc/env.json` 并断言 `compute.validated == true`。

## Auto-loop 命令

- `/paper:idea-loop`（MAX_ITER=3）
- `/paper:review-loop`（MAX_ITER=4）
- `/paper:figure-loop`（MAX_ITER=5）
- `/paper:citation-loop`（MAX_ITER=3）

终止与保护：
- 达到阈值提前终止；
- 达到 MAX_ITER 强制停止；
- review-loop 连续两轮分数下降时进入 `human-intervention-needed`。

## 环境配置（v4）

- 环境唯一真相：`.arc/env.json`
- 安装默认执行环境探测并生成 `.arc/env.json`
- `--skip-env-probe` 会复制模板，需手动填写后再验证

全量环境校验：

```bash
/path/to/scf/validate.sh --target /path/to/your-paper-project --full-env-check
```

## 验证

```bash
/path/to/scf/validate.sh --target /path/to/your-paper-project
```

## 卸载

```bash
/path/to/scf/uninstall.sh --target /path/to/your-paper-project
```
