---
name: paper-status
description: Display current pipeline status, quality gates, and blocking issues
usage: /paper:status
---

Read:
- `.arc/state/pipeline-status.json`
- `.arc/state/review-*.json`
- `.arc/env.json`
- `.arc/paper-type.json`

## Output format (v5)

```text
Pipeline Status
═════════════════════════════════════════════════════════
Stage:        writing (round 2/4)
Paper type:   long | ai-experimental | NeurIPS

Quality Gates  [long | ai-experimental | NeurIPS]
═════════════════════════════════════════════════════════
Pages:         7 / 9 ✓
Figures:       3 / 5 ⚠  (min: 5 for long ai-exp)
Tables:        1 / 1 ✓
References:   22 / 30 ⚠  (min: 30 for long paper)
  Recent (5yr): 35% / 30% ✓
  Hallucinated: 2 removed ✓
Ablation:      ✗ MISSING  (required for ai-experimental)
Limitations:   ✓ found
Integrity:     ✓ passed
Stat audit:    ⚠ 3 results missing error bars

Environment
═════════════════════════════════════════════════════════
Compute:      ssh -> gpu-server-1
Conda env:    scf-myproject ✓ (Python 3.10)
Validated:    2026-04-09 14:23 ✓
Active exp:   scf-exp-20260409-1423 (running 1h23m)
APIs:         semantic_scholar ✓  arxiv ✓  codex ⚠(degraded)  wandb —

Blocking Issues
═════════════════════════════════════════════════════════
1. Figure count 3 < min_figures 5
2. Citation count 22 < min_references 30
3. Ablation study required but missing
```

## Key fields

- All thresholds read from `paper-type.json`.
- If `paper-type.json` missing, display warning and suggest `/paper:init`.
- Integrity and Stat audit status from `review-integrity.json` and `review-stat.json`.
- If any blocking issue, list top blocking items first.