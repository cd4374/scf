---
name: arc-statistics
description: Statistical compliance — error bars, significance testing, ablation design, cherry-picking detection
---

# Arc Statistics Skill

## Purpose

Ensure all quantitative results follow statistical best practices:
- Report mean ± std (or std error)
- Run sufficient independent experiments
- Perform significance testing
- Avoid cherry-picking
- Include ablation study when required

## Inputs

- `.arc/paper-type.json` — read `paper_domain`, `min_experiment_runs`, `require_ablation`
- `.arc/state/` — experiment result JSON files
- `draft.tex` — check reported numbers
- `results/` — raw experimental results

## Statistical Requirements (§5.1–5.4)

### Error Bar Reporting (§5.1)

**All paper types**:
- [ ] All quantitative results report **mean ± std** (or mean ± std error)
- [ ] Number of independent runs ≥ `paper-type.min_experiment_runs`
  - **Assert**: `actual_runs ≥ min_experiment_runs` from paper-type.json
  - If ai-experimental: default `min_experiment_runs = 3`; if violated → blocking issue
  - If other domains: as declared; if violated → major issue
- [ ] Figure captions explain error bar meaning (std / std err / CI)

**Detection**:
```bash
# Lines with numbers but no ± symbol
grep -n "[0-9]\+\.[0-9]\+" draft.tex | grep -v "\\pm\|±\|std\|s\.e\." | wc -l
```

If ≥5 such lines found → warning.

### Significance Testing (§5.2)

**All paper types**:
- [ ] Comparison with baselines includes statistical significance test (p-value or effect size like Cohen's d)
- [ ] **No cherry-picking**: report results for all hyperparameter configurations, or explicitly state selection criteria and search space

**Detection**:
- Search for "best result", "best performance", "state-of-the-art" without accompanying "all configurations" or "search space" description.

### Ablation Study (§5.3)

**Conditional** (only if `paper-type.require_ablation == true`):
- [ ] Paper includes Ablation Study section
- [ ] Each core innovation component has independent ablation对照
- [ ] Results show contribution of each component

**Detection**:
```bash
grep -i "ablation\|ablate" draft.tex | wc -l
```
If 0 and `require_ablation == true` → blocking issue.

### Physics / Numerical Special Requirements (§5.4)

**Physics domain**:
- [ ] Distinguish systematic error vs random error
- [ ] Quantify both separately

**Numerical domain**:
- [ ] Report truncation error, discretization error, numerical dissipation
- [ ] Convergence order reported when comparing to analytical solution
- [ ] Grid independence test with ≥2 grids

## Output

Write audit results to `.arc/state/review-stat.json`:

```json
{
  "agent": "stat-auditor",
  "timestamp": "2026-04-09T12:00:00Z",
  "paper_type_context": {
    "format": "long",
    "domain": "ai-experimental"
  },
  "pass": false,
  "score": 65,
  "decision": "major",
  "error_bars_missing_count": 3,
  "cherry_picking_signals": 2,
  "ablation_present": false,
  "significance_tests_present": true,
  "issues": [
    {
      "location": "Section 4.2, Table 2",
      "type": "missing_error_bars",
      "description": "3 results reported without error bars",
      "severity": "major",
      "standard_ref": "质量标准 §5.1"
    },
    {
      "location": "Section 4.3",
      "type": "cherry_picking",
      "description": "Only best result reported without mentioning all configurations",
      "severity": "major",
      "standard_ref": "质量标准 §5.2"
    },
    {
      "location": "N/A",
      "type": "missing_ablation",
      "description": "Ablation study required for ai-experimental but missing",
      "severity": "blocking",
      "standard_ref": "质量标准 §5.3"
    }
  ],
  "strengths": ["Significance tests properly reported"],
  "summary": "Statistical compliance issues: missing error bars, potential cherry-picking, ablation study required but absent."
}
```

## Integration

- Called by `/paper:review-loop` as `stat-auditor` subagent
- `/paper:status` displays statistical compliance summary
- `/paper:export` requires `review-stat.json` pass = true

## References

- 高质量学术论文质量标准 v2.0 §五（统计与实验规范）
- PROJECT_SPEC.md §3.4, §4.3, §5.3
