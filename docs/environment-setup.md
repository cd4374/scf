# Environment Setup

环境唯一真相：`.arc/env.json`

## 架构

- 模板：`src/arc/env.template.json`
- 探测生成：`src/arc/env-probe.sh`
- 验证：`src/arc/env-validate.sh`
- 运行读取：commands / skills / hooks 统一从 `.arc/env.json` 读取

## Schema 核心字段

- `compute.mode`: `local | ssh | modal | cpu`
- `compute.backend`: `cuda | mps | cpu`
- `compute.validated`: 环境是否通过验证
- `compute.experiment_time_limit`: 默认 `4h`
- `compute.max_parallel_runs`: 默认 `3`
- `compute.ssh.host/user/key_path/remote_dir/code_sync/screen_prefix`
- `compute.modal.enabled/app_name`
- `software.conda_env/python_version/activate_cmd/environment_yml_path`
- `monitoring.wandb/wandb_entity/wandb_project`
- `apis.semantic_scholar/arxiv/codex/wandb`
- `active_experiments`: 运行中的实验会话列表

## 计算模式

### local
- 自动探测 CUDA 或 MPS
- 读取 `software.activate_cmd` 执行实验
- 适合本地 GPU

### ssh
- 使用 `compute.ssh.*` 字段连接远端 GPU
- 推荐 screen 会话名：`scf-exp-{YYYYMMDD-HHMM}`
- 支持 `rsync` / `git` 两种代码同步策略

### modal
- 使用 `compute.modal.app_name`
- 执行 `modal run launcher.py`
- 适合无本地 GPU 的 serverless 场景

### cpu
- 仅做小规模验证
- 大规模实验应切换至 GPU 模式

## conda 管理

- 使用 `src/arc/conda-setup.sh` 创建 `scf-{project}`
- 禁止使用 `base` 环境
- 环境快照输出到 `.arc/environment.yml`

## API 状态

- Semantic Scholar：`configured | missing`
- arXiv：`configured`
- Codex：`configured | missing | degraded`
- W&B：`configured | missing | disabled`

## 验证流程

```bash
# 结构验证
bash .arc/env-validate.sh --target /path/to/project

# 含连通性验证
bash .arc/env-validate.sh --target /path/to/project --connectivity
```

error 项失败会退出非 0；warning 仅提示降级风险。
