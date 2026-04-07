---
name: arc-figure-codegen
description: Figure generation and quality validation for academic papers. Use when generating charts, plots, or diagrams from experimental data, or when validating figure quality and authenticity.
---

# Arc Figure Code Generation Skills

## Quick reference
- Figures MUST derive from real experiment artifacts
- Each figure needs provenance declaration
- Minimum 4 figures (AI/ML typically ≥5)
- All figures must exist as real files in `.arc/figures/rendered/`

## Figure requirements

### Count by domain
| Domain | Minimum | Typical |
|--------|---------|---------|
| AI/ML | 4 | 5-8 |
| Physics | 4 | 4-6 |
| Simulation | 3 | 3-5 |

### File requirements
- Formats: PDF (preferred), PNG (≥300 DPI)
- Location: `.arc/figures/rendered/`
- Naming: `fig1.pdf`, `fig2.pdf`, etc.
- Each requires caption and label

### Provenance declaration
Every figure must have a machine-checkable provenance marker:
```html
<!-- fig-src: stage-14/experiment_summary.json > metric_name -->
```

### Sidecar file
Each figure needs `<figure>.provenance.json`:
```json
{
  "figure_file": "fig1.pdf",
  "source_artifact": "stage-14/experiment_summary.json",
  "metric_key": "h1_baseline_accuracy",
  "generated_at": "2026-04-07T12:00:00Z"
}
```

## Stage 27: Figure Quality Gate (arc-10-02) — BLOCKING

Validates:
- **Quantity**: meets venue minimum
- **Readability**: labels, units, legends, captions, font size
- **Style**: subfigure labels, colors, vector/raster quality
- **Statistics**: values match experiment_summary.json
- **Traceability**: source artifact declared
- **Authenticity**: evidence-bearing, not decorative

### Authenticity sub-checks
1. **Sidecar exists**: `<figure>.provenance.json` present
2. **Metric cross-check**: declared metric exists in experiment_summary.json
3. **Visual consistency**: plotted values match declared metrics

### Blocking failures
- Required figure count not met → BLOCK
- Failed critical readability checks → BLOCK
- Missing traceability → BLOCK
- Failed authenticity → BLOCK

## Figure generation workflow

### 1. Design figure
- Identify metric from `experiment_summary.json`
- Determine best visualization (bar chart, line plot, etc.)
- Map data ranges to visual encoding

### 2. Generate figure code
```python
import matplotlib.pyplot as plt
import pandas as pd

# Load data from experiment_summary.json
data = pd.DataFrame(...)

# Create visualization
fig, ax = plt.subplots()
ax.bar(...)

# Add provenance
fig.savefig('.arc/figures/rendered/fig1.pdf')
```

### 3. Write sidecar
```json
{
  "figure_file": "fig1.pdf",
  "source_artifact": "stage-14/experiment_summary.json",
  "metric_key": "h1_baseline_accuracy",
  "generated_at": "ISO-8601"
}
```

### 4. Reference in draft
```latex
Figure~\ref{fig:fig1} shows...
\begin{figure}
  \centering
  \includegraphics[width=0.8\textwidth]{figures/rendered/fig1.pdf}
  \caption{...}
  \label{fig:fig1}
\end{figure}
```

## Style rules

### Captions
- Required for every figure
- Should describe: what is shown, key takeaway
- Statistical info: mean ± std when applicable

### Labels
- Axes must have labels
- Units required where applicable
- Legends clear for multi-series plots

### Subfigure labels
- Style per venue (e.g., NeurIPS: uppercase letters A, B, C)
- Consistent across all subfigures

### Colors
- Consistent across figures (use same palette)
- Accessible (distinguishable for colorblind)
- Avoid rainbow colormaps

### Typography
- Font readable: minimum 8pt
- Title case for axis labels
- Consistent font family

## Figure types

| Type | Use case |
|------|----------|
| Bar chart | Comparing discrete values |
| Line plot | Trends over epochs/parameters |
| Scatter plot | Correlation, distribution |
| Heatmap | Matrix data, attention |
| Table | Precise numeric comparison |

## Key constraints

| Constraint | Requirement |
|------------|-------------|
| Figure count | ≥ venue minimum |
| File existence | Real files in `.arc/figures/rendered/` |
| Provenance | Sidecar JSON for each figure |
| Metric match | Plotted values must match experiment_summary |
| Text reference | All figures referenced in draft.tex |

## Anti-fabrication rules

1. Never generate figure without real data
2. Never modify plotted values
3. Never create decorative (non-evidence-bearing) figures
4. All figures traceable to experiment artifacts

## Usage

1. During paper draft (Stage 17): Plan figures with provenance
2. During paper polish (Stage 25): Generate actual figures
3. Stage 27: Gate validates quality and authenticity
4. Stage 28: Final format check includes figures

## See also
- arc-writing for figure integration
- arc-latex-formatting for figure placement
- arc-experiment for result artifacts
