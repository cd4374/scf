---
name: arc-latex-formatting
description: LaTeX formatting skills including template resolution, compilation, and submission format compliance. Use when resolving venue templates, compiling papers, or verifying LaTeX correctness.
---

# Arc LaTeX Formatting Skills

## Quick reference
- LaTeX MUST compile locally — no cloud/Overleaf fallbacks
- Compile sequence: pdflatex → bibtex → pdflatex → pdflatex
- Exit code 0 required before any stage advances
- Templates available: neurips, iclr, icml, aaai, ieee, elsevier, springer, acl

## Templates

Templates are located in `templates/` directory:

```
templates/
├── neurips/       # neurips_2026.sty, template.tex
├── iclr/         # template.tex
├── icml/         # icml2026.sty, template.tex
├── aaai/         # template.tex
├── ieee/         # template_journal.tex, template_conference.tex
├── elsevier/     # template.tex
├── springer/     # template.tex
├── acl/          # template.tex
└── cvpr/         # template.tex
```

## Template resolution

Resolved by `arc-07-00-template-resolve` into `template_manifest.json`:

| Template family | Template ID | Type |
|----------------|-------------|------|
| neurips | neurips_2026 | conference |
| iclr | iclr_2026 | conference |
| icml | icml_2026 | conference |
| aaai | aaai_2026 | conference |
| acl_family | acl_2025, emnlp_2025 | conference |
| cv_family | cvpr_2026, iccv_2025 | conference |
| ieee_conf | ieee_conference | conference |
| ieee_journal | ieeetran_journal | journal |
| elsevier_journal | elsevier_cas_sc, pattern_recognition | journal |
| springer_journal | springer_lncs_journal | journal |

## Compilation

### Standard sequence
```bash
pdflatex -interaction=nonstopmode draft.tex
bibtex draft
pdflatex -interaction=nonstopmode draft.tex
pdflatex -interaction=nonstopmode draft.tex
```

### Verify success
- Exit code 0 on all commands
- PDF file exists and non-empty
- No `! ` errors in log

### Error handling
- Parse log for `! ` errors
- Common issues: missing `\bibliography{references}`, undefined citations, missing packages
- Fix and recompile before proceeding

## Required LaTeX elements

### Document structure
```latex
\documentclass[options]{documentclass}
\usepackage[...]{packages}
\bibliography{references}  % BibTeX file
\begin{document}
\title{...}
\begin{abstract}...\end{abstract}
\maketitle
\section{Introduction}
...
\bibliography{references}
\end{document}
```

### Bibliography style commands
| Venue | Commands |
|-------|----------|
| neurips/iclr/icml | `\citep{}`, `\citet{}` |
| IEEE | `\cite{}` |
| General | `\bibliographystyle{plainnat}` |

## Figure handling

- Figures in `.arc/figures/rendered/`
- Include with `\includegraphics[width=...]{figures/rendered/fig}`
- Captions with `\caption{...}`
- References with `\label{fig:name}` → `\ref{fig:name}`

## Section requirements by venue

### Conference (NeurIPS/ICLR/ICML)
- Abstract (180-220 words)
- Introduction (with contributions list)
- Related Work
- Method
- Experiments
- Conclusion
- Broader Impact / Ethics Statement

### Journal (IEEE/Elsevier/Springer)
- Abstract
- Introduction
- Related Work
- Method
- Experiments
- Results
- Discussion
- Conclusion
- (Appendix optional)

## Key constraints

| Constraint | Requirement |
|------------|-------------|
| Compilation | Exit code 0 required |
| Citations | All must exist in references.bib |
| Figures | All must exist as files |
| References | Complete fields (author, title, year) |

## Submission format gates

- Stage 28: Submission format gate checks
- Stage 28.5: Final acceptance gate
- Both require LaTeX compilation success

## Usage

1. Template resolve sets venue contract
2. Paper draft uses template structure
3. Export (Stage 22) compiles to PDF
4. Submission gates verify format compliance

## See also
- arc-writing for paper creation context
- arc-experiment for figure generation
- templates/ directory for actual template files
