# SCF Architecture (v5)

## Design goals
- Treat `.arc/env.json` as the single source of truth for runtime environment.
- Keep `src/CLAUDE.md` minimal (instruction-only, no expanded environment details).
- Make quality gates explicit and consistent across commands, hooks, agents, and docs.
- Ensure loops are bounded and auditable through state/log files.

## Core architecture

### 1) Environment single-source-of-truth
Environment data lives in one place only:
- Runtime file: `.arc/env.json` (gitignored)
- Template: `src/arc/env.template.json`
- Producer: `src/arc/env-probe.sh`
- Validator: `src/arc/env-validate.sh`

Consumers:
- Hooks (`stop-gate.sh`) read env fields for final safety checks.
- Skills/commands (especially experiment path) read env fields before execution.

`src/CLAUDE.md` only keeps one pointer line:
- `Compute environment: read .arc/env.json before any experiment task.`

### 2) State bus
Cross-agent communication uses `.arc/state/*.json`.
- Pipeline summary: `pipeline-status.json`
- Review outputs: `review-*.json`
- Reproducibility record: `reproducibility.json`

Loop and progress telemetry:
- `.arc/loop-logs/review-rounds/`
- `.arc/loop-logs/figure-rounds/`
- `.arc/loop-logs/citation-rounds/`

### 3) Command/agent/skill separation
- Commands orchestrate workflow (`/paper:*`).
- Skills define reusable protocols and contracts.
- Agents perform specialist review tasks (read-only reviewers).
- Hooks enforce hard constraints after/before writes and at stop.

## Auto-loop contracts
Default caps (must stay consistent):
- `idea_loop MAX_ITER=3`
- `review_loop MAX_ITER=4`
- `figure_loop MAX_ITER=5`
- `citation_loop MAX_ITER=3`

Stop conditions:
- reach threshold,
- hit max iterations,
- review score declines for two consecutive rounds (pause for human intervention).

## Quality gates (thresholds from paper-type.json)

All numeric quality gates are read from `.arc/paper-type.json` (driven by `derived_thresholds`).
No quality thresholds are hardcoded in this document or in CLAUDE.md.

Example thresholds (long + ai-experimental):
- `derived_thresholds.min_references`: **30**
- `derived_thresholds.min_recent_refs_pct`: **30%**
- `derived_thresholds.min_figures`: **5**
- `derived_thresholds.min_tables`: **1**
- `derived_thresholds.require_ablation`: **true**
- `derived_thresholds.min_experiment_runs`: **3**
- `abstract_max_words`: **250**
- `page_limit`: venue-dependent

Thresholds vary by `paper_format` (long/short/letter) and `paper_domain` (ai-experimental/ai-theoretical/physics/numerical).
Run `/paper:init` to configure thresholds for your paper type.

Citation integrity: four-layer verification; hallucinated entries must be removed.
LaTeX: must compile without errors.
Experimental numbers: must come from real runs (no fabrication).
Limitations section: required for all paper types.

## Hook responsibilities
- `pre-write-gate.sh`: block reviewer agents from writing `draft.tex`.
- `post-write-*`: update/check page count, sections, figures/tables, citations, statistics, latex, AI writing patterns, loop logs.
- `stop-gate.sh`: final guard that checks final/integrity/stat reviews, paper-type-driven quality gates, and env validation status.

## Why v4 changed from old design
Older design embedded environment details in CLAUDE markdown fragments. That caused drift and parsing fragility. v4 fixes this by:
- centralizing environment config in `.arc/env.json`,
- using structured readers (hooks/scripts/skills) instead of markdown parsing,
- avoiding sensitive environment expansion in versioned instruction files.
