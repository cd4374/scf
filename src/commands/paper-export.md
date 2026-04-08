---
name: paper-export
description: Package final deliverables with reproducibility bundle
usage: /paper:export
---

## Prerequisites

- `.arc/state/review-final.json` has `pass: true`.
- All auto-loops are `completed` or `max-iter-reached`.
- `.arc/state/review-codex.json` exists (or explicitly records degraded cross-model mode).

## Compile order

1. `pdflatex`
2. `bibtex`
3. `pdflatex`
4. `pdflatex`

Compile must succeed locally with exit code 0 and produce non-empty PDF.

## Export outputs

- `paper.pdf`
- `paper.tex`
- `references.bib`
- `figures/`
- `reproducibility-bundle/` containing:
  - code
  - `.arc/environment.yml`
  - `requirements.txt`
  - fixed-seed records
  - dataset references
  - reproduction summary
