---
name: paper-resume
description: Resume pipeline from interruption point
usage: /paper:resume
---

1. Read `.arc/state/pipeline-status.json`.
2. Re-check `.arc/env.json` and assert `compute.validated == true` before experiment-capable stages.
3. Identify the current incomplete stage and unresolved blocking issues.
4. If `active_experiments` contains running or uncollected SSH sessions, surface them before resuming.
5. Continue with `/paper:run` logic from the current stage only when no blocking gate is open.
