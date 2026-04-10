---
name: paper-init
description: Initialize paper type configuration for quality gates
usage: /paper:init --format long --domain ai-experimental --venue NeurIPS --pages 9
---

Initialize the paper type configuration for the current project.

## Parameters

- `--format`: Paper format — `long` | `short` | `letter`
- `--domain`: Paper domain — `ai-experimental` | `ai-theoretical` | `physics` | `numerical`
- `--venue`: Target venue — `NeurIPS` | `ICML` | `ICLR` | `ACL` | `AAAI` | `IEEE` | `Nature` | `PRL` | `custom`
- `--pages`: Page limit (integer)

## Auto-Derived Thresholds

Based on `--format` + `--domain`, derive the following thresholds:

| format + domain | min_refs | recent_pct | min_figures | require_ablation |
|-----------------|----------|------------|-------------|------------------|
| long + ai-exp  | 30       | 30%        | 5           | true             |
| long + ai-theory| 30      | 15%        | 3           | false            |
| long + physics  | 30       | 20%        | 4           | false            |
| long + numerical| 30       | 20%        | 3           | true             |
| short + ai-exp  | 15       | 30%        | 3           | true             |
| short + ai-theory| 15      | 15%        | 3           | false            |
| short + physics  | 15      | 20%        | 3           | false            |
| short + numerical| 15      | 20%        | 3           | false            |
| letter + any    | 10        | 15%        | 2           | false            |

`min_experiment_runs`: 3 for ai-experimental, 1 otherwise.
`abstract_max_words`: 250 for long, 150 for short/letter.

## Actions

### Step 1: Read existing config

Check if `.arc/paper-type.json` already exists.

### Step 2: Derive thresholds

Use the lookup table above to set all `derived_thresholds` fields.

### Step 3: Write `.arc/paper-type.json`

Write the complete paper-type configuration.

### Step 4: Update pipeline-status.json

Add `paper_type` field:
```json
{
  "paper_type": {
    "format": "long",
    "domain": "ai-experimental",
    "target_venue": "NeurIPS",
    "page_limit": 9
  }
}
```

### Step 5: Update CLAUDE.md

Update ONLY these two lines in `CLAUDE.md`:
- `Journal target: __JOURNAL__` → `Journal target: NeurIPS`
- Add or update `Paper format: __FORMAT__ | __DOMAIN__`

Do NOT modify any other lines.

### Step 6: Display thresholds

Print all derived thresholds for user confirmation:

```
Quality Thresholds [long | ai-experimental | NeurIPS]
═══════════════════════════════════════════════════
min_references:       30
min_recent_refs_pct:  30%
min_figures:          5
min_tables:           1
require_ablation:     true
min_experiment_runs:  3
abstract_max_words:   250
page_limit:           9
═══════════════════════════════════════════════════
Confirm? [Y/n]
```

## Must Run Before

`/paper:run` — must run `/paper:init` before starting the pipeline.

## Idempotency

Safe to re-run — overwrites `.arc/paper-type.json` with updated values.
