# Arc Paper Framework

## Project
- Name: scf
- Journal target: __JOURNAL__
- Paper format: __FORMAT__ | __DOMAIN__
- Framework version: v2.0

## Configuration pointers
- Quality thresholds: read `.arc/paper-type.json` for all quantity gates (references, figures, tables, ablation, etc.).
- Compute environment: read `.arc/env.json` before any experiment task.

## Absolute quality principles
- All figures must come from real code rendering; every `\includegraphics` must have a matching file in `.arc/figures/rendered/`.
- All citations must pass four-layer API verification; hallucinated references are auto-deleted.
- Experimental numbers must come from actual runs; fabrication is a blocking violation.
- LaTeX must compile without errors; submit the `.log` file alongside the PDF.
- All quantitative results must report mean ± std; cherry-picking is prohibited.
- Limitations section is required for all paper types.
- Ablation study required when `require_ablation=true` in paper-type.json.

## Auto-loop defaults
- idea_loop MAX_ITER=3
- review_loop MAX_ITER=4
- figure_loop MAX_ITER=5
- citation_loop MAX_ITER=3

## Framework navigation
- Pipeline state: `.arc/state/pipeline-status.json`
- Reviewer agents must not write `draft.tex`; output goes to `.arc/state/review-*.json`.
- Use `/paper:init` first (sets paper type), then `/paper:status` before starting.
- Skills in `.claude/skills/` auto-load.

## Cross-model review
- If Codex MCP not configured, `/paper:codex-review` degrades to multi-agent-debate and marks `cross_model: degraded`.

## Compaction survival rule
When context compacts, re-read in this order:
1. `.arc/state/pipeline-status.json`
2. `.arc/env.json`
3. `.arc/paper-type.json`
