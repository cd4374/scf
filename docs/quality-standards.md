# High-Quality Academic Paper Quality Standards v2.0

> Complete mapping of quality requirements to scf implementation. All scf components must satisfy these standards.

## §一 文件完整性

| Requirement | Implementation | Verification |
|------------|----------------|--------------|
| LaTeX source + compiled PDF + BIB | `paper-export.md` bundle checklist | stop-gate |
| All figure source scripts (`.py`) + rendered outputs | `reproducibility-bundle/` in export | integrity-checker |
| Macro package declarations | `arc-latex-formatting/SKILL.md` | post-write-latex-check.sh |

## §二 引用规范

| Requirement | Implementation | Verification |
|------------|----------------|--------------|
| Citation count (long≥30, short≥15, letter≥10) | `paper-type.json` → `citation-verifier` | post-write-citation-check.sh, stop-gate |
| Recent refs (ai-exp≥30%, ai-theory≥15%, physics/numerical≥20%) | `paper-type.json` → `citation-verifier` | citation-loop |
| No hallucinated entries | 4-layer verification in `arc-citation-style` | citation-loop Layer 2-3 |
| URL/DOI no dead links | Layer 2 in `arc-citation-style` | citation-loop |
| Consistent BibTeX style | `arc-citation-style/SKILL.md` | post-write-citation-check.sh |

## §三 图表规范

| Requirement | Implementation | Verification |
|------------|----------------|--------------|
| Figure count (by type: long ai-exp≥5, others≥3) | `paper-type.json` → `figure-auditor` | post-write-figure-check.sh |
| Table count (≥1, includes comparison table) | `paper-type.json` → `figure-auditor` | post-write-table-check.sh |
| Vector format for charts (`.pdf`/`.eps`) | `arc-figure-codegen/SKILL.md` | post-write-figure-check.sh |
| Raster ≥300 DPI | `arc-figure-codegen/SKILL.md` | VLM review (figure-loop) |
| Font embedded ≥8pt | `arc-figure-codegen/SKILL.md` | VLM review 8-dim |
| Axis labels with units | `arc-figure-codegen/SKILL.md` | VLM review 8-dim |
| Color-blind friendly | `arc-figure-codegen/SKILL.md` | VLM review 8-dim |
| Error bar meaning in caption | `arc-figure-codegen/SKILL.md` | VLM review 8-dim |
| Consistent style (colors, line types) | `arc-figure-codegen/SKILL.md` | VLM review 8-dim |
| No fabricated data charts | `integrity-checker` | review-integrity.json |

## §四 可重复性

| Requirement | Implementation | Verification |
|------------|----------------|--------------|
| Random seeds fixed | `arc-reproducibility/SKILL.md` | pre-experiment-gate.sh |
| Hardware/software versions recorded | `arc-reproducibility/SKILL.md` | reproducibility.json |
| All hyperparameters listed | `arc-reproducibility/SKILL.md` | stat-auditor |
| Code repo + version locked (tag/commit/DOI) | `arc-reproducibility/SKILL.md` | export bundle |
| Dataset version/source cited | `arc-reproducibility/SKILL.md` | reproducibility.json |
| Data preprocessing described | `arc-reproducibility/SKILL.md` | stat-auditor |
| Reproducibility Statement paragraph | `arc-reproducibility/SKILL.md` | post-write-section-check.sh |
| Environment snapshot (`requirements.txt`, `environment.yml`) | `arc-reproducibility/SKILL.md` | export bundle |

## §五 统计与实验规范

| Requirement | Domain | Implementation | Verification |
|------------|--------|----------------|--------------|
| Report mean±std | all | `arc-statistics/SKILL.md` | post-write-stat-check.sh |
| Independent runs ≥ min_experiment_runs | all | `paper-type.json` → `arc-experiment` | stat-auditor |
| Error bar meaning in caption | all | `arc-figure-codegen/SKILL.md` | VLM review |
| Statistical significance test (p-value/effect size) | all | `arc-statistics/SKILL.md` | review-stat.json |
| No cherry-picking | all | `arc-statistics/SKILL.md` | post-write-stat-check.sh |
| Ablation Study section | ai-exp, numerical | `paper-type.json` → `arc-writing` | post-write-section-check.sh |
| Limitations section | all | `arc-writing/SKILL.md` | post-write-section-check.sh |
| Systematic vs random error distinction | physics | `arc-statistics/SKILL.md` | stat-auditor |
| Grid independence test (≥2 grids) | numerical | `arc-statistics/SKILL.md` | stat-auditor |
| Convergence order reported | numerical | `arc-statistics/SKILL.md` | stat-auditor |

## §六 学术诚信

| Requirement | Implementation | Verification |
|------------|----------------|--------------|
| Required sections (Abstract, Intro, Method, Experiments, Conclusion, References, Limitations) | `arc-writing/SKILL.md` + paper-type | post-write-section-check.sh |
| Abstract word count (long≤250, short/letter≤150) | `paper-type.json` | stat-auditor |
| Page count within limit | `paper-type.json` | post-write-page-count.sh |
| Plagiarism check reminder (≤15%) | `integrity-checker` | review-integrity.json |
| Conflict of Interest statement | `integrity-checker` | review-integrity.json |
| Image/code license attribution | `integrity-checker` | review-integrity.json |
| No image manipulation (crop/enhance without disclosure) | `integrity-checker` | review-integrity.json |
| Neural network visualization method disclosed | `integrity-checker` | review-integrity.json |

## §七 图表质量 8-Dimensional VLM Review

Each generated figure is reviewed against 8 dimensions:

1. **Content accuracy**: Numbers match draft.tex data
2. **Readability**: Fonts legible, legends clear
3. **No truncation**: All content visible, no overflow
4. **Color-blind friendly**: No pure red-green contrast; Okabe-Ito / Viridis / CUD palettes
5. **Title/caption completeness**: Figure X numbering + full caption with experimental conditions
6. **Axis completeness**: Variable names, units, tick marks present, no excessive whitespace
7. **Error bar meaning**: Caption explains std / std err / CI if applicable
8. **Style consistency**: Same colors and line types for similar curves across paper

MAX_ITER=5, SCORE_THRESHOLD=8.0/10, top-3 fixes per round.
