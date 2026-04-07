---
name: arc-experiment
description: Experiment phase skills for design, code generation, resource planning, execution, and iterative refinement. Use when designing experiments, generating code, running experiments, or improving results.
---

# Arc Experiment Skills

## Quick reference
- All experiments require real execution backend (Stage 0 must pass)
- ≥3 seeds per condition, aggregated mean ± std
- NO FABRICATED DATA — all metrics from actual execution
- Experiment code must compile and run before proceeding

## Stages

### Stage 9: Experiment Design (arc-04-01) — GATE
Design complete experiment blueprint:
- Each hypothesis has ≥1 baseline and ≥1 ablation
- All experiments use ≥3 seeds
- Compute budget estimated and feasible
- Datasets assigned tier-1 (iteration) or tier-2 (final validation)

**Output**: `exp_plan.yaml`, `design_rationale.md`

### Stage 9.5: Reproducibility Design Gate (arc-04-04) — BLOCKING
Freeze reproducibility contract before coding:
- Seed policy: ≥3 seeds without justification
- Environment lock: dependency specification
- Statistical method: comparison approach documented

**Output**: `reproducibility_design_report.json`

### Stage 10: Code Generation (arc-04-02)
Generate runnable multi-file experiment project:
- All hypotheses, baselines, ablations implemented
- Output format: `condition=X seed=N metric: value`
- Finalize() writes `results.json`
- `requirements.txt` + `README.md`

**Output**: `experiment/` directory, `experiment_spec.md`

### Stage 11: Resource Planning (arc-04-03)
Build time-resolved execution schedule:
- `total_time_sec` ≤ available time budget
- All (condition, dataset, seed) combinations scheduled
- Parallel groups for GPU utilization
- ≥2 intermediate checkpoints

**Output**: `schedule.json`

### Stage 12: Experiment Run (arc-05-01)
Execute all scheduled runs with real code:
- **REQUIRES execution_capable: true from Stage 0**
- Auto-diagnosis of failures
- Auto-repair of common issues (OOM, NaN, missing deps)
- All runs complete → aggregated metrics

**Output**: `runs/` directory, `experiment_summary.json`, `execution_log.json`

### Stage 13: Iterative Refine (arc-05-02)
Improve via edit-run-eval cycles:
- Auto-diagnosis of experiment quality
- Auto-repair of deficiencies
- Exit: convergence (2 iterations no improvement) OR budget ≥95% exhausted
- Best configuration snapshot

**Output**: `refinement_log.json`, `experiment_final/`, updated `experiment_summary.json`

## Execution backends

| Backend | Use case |
|---------|----------|
| Local GPU | NVIDIA CUDA or Apple MPS |
| Local CPU | CPU-only when no GPU |
| SSH Remote | Powerful remote GPU server |

## Auto-repair protocol

| Error | Fix | Max attempts |
|-------|-----|---------------|
| GPU OOM | batch_size × 0.5 | 2 |
| NaN loss | learning_rate × 0.1, gradient clipping | 2 |
| Missing dependency | pip install | 1 |
| Code crash | No auto-fix | 0 |

## Key constraints

| Stage | Constraint |
|-------|------------|
| 12 | Execution backend required — no fabricated data |
| 13 | Budget tracking — convergence OR budget exhaustion |
| All | ≥3 seeds per condition |

## Quality contract

`experiment_summary.json` MUST have:
- `completed_runs` = `total_runs`
- Every condition: `metric_mean` + `metric_std` across ≥3 seeds
- No NaN or Inf values
- All from ACTUAL execution (no fabrication)

## Anti-fabrication rules

1. Never generate metrics without actual code execution
2. Fail fast if no execution backend
3. All run logs preserved for verification
4. Metrics must vary between seeds (real randomness)

## Usage

After research phase completes, pipeline automatically enters experiment phase:
1. Design approved → code generation
2. Code generated → resource planning
3. Resources planned → execution
4. Execution complete → iterative refinement if needed

## See also
- arc-analysis for result interpretation
- arc-research for hypothesis definitions
