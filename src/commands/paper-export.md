---
name: paper-export
description: Package the final paper for submission
usage: /paper:export
---

Package the final paper for submission.

Prerequisites: review-final.json must have pass: true

Steps:
1. Verify review-final.json exists and pass is true
2. Run LaTeX compilation: pdflatex → bibtex → pdflatex → pdflatex
3. Collect output: paper.pdf, paper.tex, references.bib, .arc/figures/rendered/
4. Create submission/ directory with all required files
5. Verify PDF compiles and figures are embedded
6. Report final word count, page count, and figure count

Final acceptance gates (all must pass):
- final-reviewer: pass: true
- word_count >= 6000
- figure_count >= 4
- LaTeX compiles without errors

Example output:
```
=== Export Complete ===

Paper: submission/paper.pdf
Word count: 6234
Page count: 9 (NeurIPS limit: 9)
Figures: 5

Ready for submission to NeurIPS 2026
```
