---
name: arc-experiment
description: Executes experiments using environment-driven routing across local, ssh, modal, or cpu modes. Use when launching, monitoring, and collecting runs while enforcing validated compute prerequisites and reproducibility constraints.
---

# Arc Experiment

## Entry contract (env.json driven)

Step 1: Read `.arc/env.json`.
Step 2: Assert `compute.validated == true` (abort and tell user to run `validate.sh` if false).
Step 3: Branch by `compute.mode`.

## Inputs

- `.arc/env.json`
- `.arc/state/pipeline-status.json`
- 实验配置与代码
- 数据引用与种子配置

## Common outputs

- 实验结果 JSON（含指标、配置、时间戳）
- `pipeline-status.json.active_experiments` 更新
- 失败时 `manual-follow-up` 标记

## Local mode (`compute.mode: local`)

必读字段：
- `compute.backend` (`cuda` / `mps`)
- `software.activate_cmd`
- `compute.experiment_time_limit`

执行要求：
- 使用 `nohup` 或 `screen` 后台运行
- 记录 PID 或会话名到 `active_experiments`
- 超时（默认 4h）停止自动运行并标记 `manual-follow-up`

## SSH mode (`compute.mode: ssh`)

必读字段：
- `compute.ssh.host`
- `compute.ssh.remote_dir`
- `compute.ssh.code_sync` (`rsync` / `git`)
- `software.activate_cmd`

代码同步：
- rsync:
  `rsync -avz --exclude='.git' --exclude='.arc/env.json' ./ ${host}:${remote_dir}/`
- git:
  `git push origin HEAD && ssh ${host} "cd ${remote_dir} && git pull"`

远端运行：
- 使用命名 screen 会话：`scf-exp-{YYYYMMDD-HHMM}`
- 记录会话名到 `active_experiments`
- 监控：`ssh ${host} "screen -ls | grep scf-exp"`
- 收集：`ssh cat` 或 `scp`

W&B：
- 若 `monitoring.wandb=true`，通过 `wandb.Api()` 获取曲线

时间限制：
- 超过 `compute.experiment_time_limit`，跳过自动执行并标记 `manual-follow-up`

## Modal mode (`compute.mode: modal`)

- 读取 `compute.modal.app_name`
- 执行：`modal run launcher.py`
- 通过 Modal API 轮询状态

## CPU mode (`compute.mode: cpu`)

- 执行本地 CPU 验证实验
- 明确提示不适合大规模训练

## Reproducibility constraints

- 固定种子（如 `np.random.seed(42)`）
- 保存结构化结果
- 记录运行环境与依赖

## Blocking conditions

- `compute.validated=false`
- 缺少关键字段（host/remote_dir/activate_cmd 等）
- 实验结果无结构化输出

## Integration points

- 与 `arc-reproducibility`：写入数据版本、环境快照、复现实验记录
- 与 `arc-analysis`：产出用于 claim-evidence 映射的结果文件
- 与 `stop-gate.sh`：ssh 模式需管理 `active_experiments`

## Failure handling

- 外部命令失败时记录原因，不静默跳过
- 网络波动场景优先保留已生成结果并标注状态
- 需要人工介入时明确给出后续动作

## Notes

- 本 skill 只定义实验执行契约，不绑定具体模型训练脚本实现。
