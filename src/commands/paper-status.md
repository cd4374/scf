---
name: paper-status
description: Display current pipeline status and blocking issues
usage: /paper:status
---

Read:
- `.arc/state/pipeline-status.json`
- `.arc/state/review-*.json`
- `.arc/env.json`

Output must include:
- Stage / word count / figure count / citation status
- Blocking issues summary
- Environment block

Required format example:

```text
Pipeline Status
═══════════════════════════════════════
Stage:        writing (round 2/4)
Word count:   4,823 / 6,000 ⚠
Figures:      3 / 4 ⚠
Citations:    18 / 20 ⚠ (2 hallucinated, removed)

Environment
═══════════════════════════════════════
Compute:      ssh -> gpu-server-1
Conda env:    scf-myproject ✓ (Python 3.10)
Validated:    2025-04-08 14:23 ✓
Active exp:   scf-exp-20250408-1423 (running 1h23m)
APIs:         semantic_scholar ✓  arxiv ✓  codex ⚠(degraded)  wandb —
```

If any blocking issue exists, list top blocking items first.
