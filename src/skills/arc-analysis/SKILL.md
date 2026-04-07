---
name: arc-analysis
description: Analysis phase skills for result analysis, statistical validation, and research decisions. Use when interpreting experimental results or deciding between proceed/refine/pivot paths.
---

# Arc Analysis Skills

## Quick reference
- Validate data BEFORE analyzing — no NaN/Inf allowed
- All claims require quantitative evidence from experiments
- Research decision caps: MAX 2 pivot/refine cycles total

## Stages

### Stage 14: Result Analysis (arc-06-01)
Transform raw metrics into evidence-based conclusions:

**Data Validation (mandatory before analysis):**
- No NaN/Inf in metrics
- Sufficient variance across seeds
- No identical condition results
- Reasonable metric magnitudes
- Baseline sanity (above random chance)

**Analysis outputs:**
- Per-hypothesis: SUPPORTED / NOT_SUPPORTED / INCONCLUSIVE
- Ablation effects quantified
- `results_table.tex` with mean ± std

**Output**: `data_validation.json`, `analysis.md`, `results_table.tex`

### Stage 15: Research Decision (arc-06-02)
Make PROCEED / REFINE / PIVOT decision:

| Decision | Next stage | Counts against cap |
|----------|------------|-------------------|
| proceed | → arc-06-03 gate → arc-07-00 | no |
| refine | → arc-05-02 | yes |
| pivot | → arc-03-02 | yes |

**MAX 2 pivot/refine cycles total** — forced proceed after cap

**Output**: `decision.md`, `decision_routing.json`

### Stage 15.5: Result Claim Gate (arc-06-03) — BLOCKING
Freeze claim-scope before writing:
- All contribution claims classified: allowed / allowed_with_caveat / disallowed
- Unsupported core claims must be marked `disallowed`
- `allowed_with_caveat` claims need explicit wording constraints

**Output**: `claim_scope_report.json`

## Data validation checks

| Check | Severity if fail |
|-------|------------------|
| NaN/Inf in metrics | CRITICAL → block |
| Zero variance across seeds | WARNING |
| Identical condition results | WARNING |
| Metrics outside range | CRITICAL or WARNING |
| Baseline near random | WARNING |

## Hypothesis assessment

| Status | Condition |
|--------|-----------|
| SUPPORTED | metric_mean ≥ success_threshold |
| NOT_SUPPORTED | metric_mean < baseline - 0.01 |
| INCONCLUSIVE | Neither above applies |

## Decision evidence requirements

- **proceed**: ALL hypotheses SUPPORTED with strong evidence
- **refine**: Salvageable (adjustments can fix)
- **pivot**: Fundamentally flawed (core claim wrong)

## Key constraints

| Stage | Constraint |
|-------|------------|
| 14 | Data validation MUST pass before analysis |
| 15 | Loop cap = 2 total (forced proceed after) |
| 15.5 | No unsupported claims enter writing |

## Quality contract

`analysis.md` MUST have:
- Every hypothesis with SUPPORTED/NOT_SUPPORTED/INCONCLUSIVE + evidence
- `results_table.tex` valid LaTeX with mean ± std
- Statistical claims grounded in actual metric values
- Ablation effects quantified

## Loop cap enforcement

When `pivot_count ≥ 2`:
1. Decision MUST be `proceed`
2. Set `forced_proceed: true`
3. Write `quality_warning.txt`

## Usage

After experiment execution completes:
1. Result analysis validates data and interprets results
2. Research decision routes: more experiments or move to writing
3. Claim gate freezes what can be written about

## See also
- arc-experiment for execution context
- arc-writing for paper creation
