# SSH GPU Guide

## `~/.ssh/config` 示例

```ssh-config
Host gpu-server-1
  HostName 192.168.x.x
  User your_username
  IdentityFile ~/.ssh/id_rsa
  ServerAliveInterval 60
  ServerAliveCountMax 3
  TCPKeepAlive yes
```

## 免密登录

1. `ssh-keygen -t ed25519`
2. `ssh-copy-id gpu-server-1`
3. `ssh gpu-server-1` 验证免密

## Screen 会话规范

- 命名：`scf-exp-{YYYYMMDD-HHMM}`
- 创建：`screen -dmS scf-exp-YYYYMMDD-HHMM bash -c '...train command...'`
- 查看：`screen -ls | grep scf-exp`
- 附着：`screen -r <session>`

## 代码同步策略

### rsync

```bash
rsync -avz --exclude='.git' --exclude='.arc/env.json' ./ gpu-server-1:/home/user/scf-experiments/
```

### git

```bash
git push origin HEAD
ssh gpu-server-1 "cd /home/user/scf-experiments && git pull"
```

## 结果回收

- 直接读取：
  - `ssh gpu-server-1 "cat /home/user/scf-experiments/results/latest.json"`
- 或下载：
  - `scp gpu-server-1:/home/user/scf-experiments/results/latest.json ./results/`

## W&B 集成

- 远端先执行 `wandb login`
- 在 `monitoring.wandb=true` 时通过 `wandb.Api()` 拉取训练曲线
