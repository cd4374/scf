---
name: arc-figure-codegen
description: Generates reproducible paper figures from code and runs iterative visual audits to reach publication-quality outputs. Use when rendering charts, diagnosing visual defects, and improving figures under bounded loop controls.
---

# Arc Figure Codegen

## Purpose

`arc-figure-codegen` transforms experimental results into reproducible, auditable figures with iterative visual quality loops.

## Inputs

- Experimental result files (structured JSON/CSV)
- Figure generation code (`.py`)
- Target figure requirements (count, types, section mapping)
- `.arc/paper-type.json` (read `min_figures`)

## Outputs

- Versioned figure files: `fig_N_v{iter}.pdf/png`
- Figure audit results: `review-figures.json`
- Figure-loop logs: `.arc/loop-logs/figure-rounds/figure-round-{N}.json`

## Generation contract

- Must render from code; no manual screenshots.
- Vector format (`.pdf`/`.eps`) for charts, flowcharts, structure diagrams.
- Raster format (`.png`/`.jpg`) ≥300 DPI for screenshots, heatmaps.
- Embed fonts (matplotlib: `pdf.use14corefonts: False`).
- Minimum font size 8pt (at print size).
- Axis labels with variable names and units.
- Versioned, not overwritten.

## Visual audit dimensions (8, v5)

1. **Content accuracy**: Numbers match draft.tex data
2. **Readability**: Fonts legible, legends clear
3. **No truncation**: All content visible, no overflow
4. **Color-blind friendly**: No pure red-green contrast; Okabe-Ito/Viridis/CUD palettes
5. **Title/caption completeness**: Figure X numbering + full caption with conditions
6. **Axis completeness**: Variable names, units, tick marks, no excessive whitespace
7. **Error bar meaning**: Caption explains std/std err/CI if present
8. **Style consistency**: Same colors and line types for similar curves across paper

## Loop controls

- `MAX_ITER=5`
- `SCORE_THRESHOLD=8.0`
- Fix only top-3 issues per round (avoid full rewrites)

## Recommended round process

1. Render current figure version.
2. Call audit (VLM or figure-auditor).
3. Aggregate top-3 issues.
4. Targeted code fixes.
5. Re-render and record score change.
6. Update `loop_status.figure_loop`.

## Quantity check (read from paper-type.json)

- Total figures ≥ `min_figures` (ai-exp long: 5, others: 3+)
- Total tables ≥ `min_tables` (default: 1)
- Appendix figures numbered separately (Figure A1, A2...) and do NOT count toward main body minimum.

## Blocking conditions

- Figure count < `min_figures`
- Missing figure files or broken `\includegraphics` paths
- Core figure score below threshold after MAX_ITER

## Integration points

- `post-write-figure-check.sh`: validates `\includegraphics` paths and counts
- `paper-figure-loop`: shares round/termination logic
- `paper-export`: bundles final figure assets
- `post-write-table-check.sh`: validates table counts

## Figure metadata

- `figure_id`
- `version`
- `source_data`
- `render_script`
- `score_breakdown`
- `issues_fixed`
- `timestamp`

## Notes

- Figures are primary evidence; must trace to experimental output.
- If figure-data mismatch, fix data mapping before aesthetics.
- All thresholds from `paper-type.json`, not hardcoded.