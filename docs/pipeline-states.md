# Pipeline States (v5)

Valid stage values:

- not-started
- paper-init (v5 new)
- idea-exploration
- idea-validation
- literature-review
- synthesis
- hypothesis-generation
- experiment-design
- experiment-run
- result-analysis
- writing
- figure-generation
- citation-verification
- integrity-check (v5 new)
- stat-audit (v5 new)
- peer-review
- codex-review
- final-review
- export
- completed

## Stage descriptions

| Stage | Description | Key Outputs |
|-------|-------------|-------------|
| paper-init | Initialize paper-type.json | `.arc/paper-type.json` |
| integrity-check | Academic integrity verification | `review-integrity.json` |
| stat-audit | Statistical compliance audit | `review-stat.json` |

## Stage transitions

```
not-started → paper-init → idea-exploration → idea-validation →
literature-review → synthesis → hypothesis-generation →
experiment-design → experiment-run → result-analysis →
writing → figure-generation → citation-verification →
integrity-check → stat-audit → peer-review → codex-review →
final-review → export → completed
```

## Blocking conditions

- `paper-init` skipped → no `paper-type.json`
- `integrity-check` failed → data/figure truth violation
- `stat-audit` failed → statistical compliance issue