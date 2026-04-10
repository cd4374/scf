---
name: paper-export
description: Package final deliverables with reproducibility bundle
usage: /paper:export
---

## Prerequisites (v5)

- `.arc/state/review-final.json` has `pass: true`.
- `.arc/state/review-integrity.json` has `pass: true` (v5 new).
- `.arc/state/review-stat.json` has `pass: true` (v5 new).
- Figure count ≥ `paper-type.min_figures`.
- Citation count ≥ `paper-type.min_references`.
- All auto-loops are `completed` or `max-iter-reached`.
- `.arc/state/review-codex.json` exists (or explicitly records degraded cross-model mode).

## Compile order

1. `pdflatex`
2. `bibtex`
3. `pdflatex`
4. `pdflatex`

Compile must succeed locally with exit code 0 and produce non-empty PDF.

## Export outputs (v5)

- `paper.pdf` (compiled, with `paper.log`)
- `paper.tex` + all `\input` / `\include` sub-files
- `references.bib` (verified, no hallucinated entries)
- `figures/` (`.py` source scripts + rendered `.pdf`/`.png`)
- `reproducibility-bundle/`:
  - `environment.yml` + `requirements.txt`
  - Training/inference scripts (AI domain)
  - Model weights link `model-weights.md` (AI domain)
  - Data availability statement `data-availability.md`
  - All experiment result JSONs (all runs, not just best)
  - `hardware-info.md` (GPU/CPU, memory, runtime)
- `paper-type.json` (for reviewer reference)

## Final report

Output summary comparing against thresholds:

```text
Export Summary
═══════════════════════════════════════════════════
Pages:        8 / 9 ✓
Figures:      5 / 5 ✓
Tables:       2 / 1 ✓
References:   32 / 30 ✓
  Recent:     35% / 30% ✓
Ablation:     ✓ present
Limitations:  ✓ present
Integrity:    ✓ passed
Stat audit:   ✓ passed

All quality gates passed. Ready for submission.
```