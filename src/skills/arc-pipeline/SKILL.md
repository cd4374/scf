---
name: arc-pipeline
description: Manages the academic paper pipeline lifecycle. Use when starting, resuming, or checking the status of the paper writing process, or when orchestrating stage transitions. Activated automatically when pipeline coordination is needed.
---

# Arc Pipeline Orchestrator

## Quick reference
- Read `.arc/state/pipeline-status.json` FIRST after any interruption
- Pipeline state: `not-started` → `running` → `done` | `blocked` | `failed`
- Never skip environment probe (Stage 0) — it blocks if capabilities are missing

## Stage sequence

| Stage | Skill | Name |
|-------|-------|------|
| 0 | arc-00-04 | Environment probe (BLOCKING) |
| 0.7 | arc-00-07 | Idea exploration (optional) |
| 1 | arc-01-01 | Topic init |
| 2 | arc-01-02 | Problem decomposition |
| 3 | arc-02-01 | Search strategy |
| 4 | arc-02-02 | Literature collect (BLOCKING on hallucination) |
| 5 | arc-02-03 | Literature screen (GATE) |
| 6 | arc-02-04 | Knowledge extract |
| 7 | arc-03-01 | Synthesis |
| 7.5 | arc-03-03 | Novelty gap gate (BLOCKING) |
| 8 | arc-03-02 | Hypothesis generation |
| 8.5 | arc-03-04 | Risk assessment (optional) |
| 9 | arc-04-01 | Experiment design (GATE) |
| 9.5 | arc-04-04 | Reproducibility design gate (BLOCKING) |
| 10 | arc-04-02 | Code generation |
| 11 | arc-04-03 | Resource planning |
| 12 | arc-05-01 | Experiment run |
| 13 | arc-05-02 | Iterative refine |
| 14 | arc-06-01 | Result analysis |
| 15 | arc-06-02 | Research decision |
| 15.5 | arc-06-03 | Result claim gate (BLOCKING) |
| 15.7 | arc-07-00 | Template resolve |
| 16 | arc-07-01 | Paper outline |
| 17 | arc-07-02 | Paper draft |
| 17.5 | arc-07-05 | Writing compliance gate (BLOCKING) |
| 18 | arc-07-03 | Peer review |
| 18.5 | arc-08-05 | Bibliography quality gate (BLOCKING) |
| 19 | arc-07-04 | Paper revision |
| 20 | arc-08-01 | Quality gate |
| 20.5 | arc-00-06 | Meta optimizer (optional) |
| 21 | arc-08-02 | Knowledge archive (optional) |
| 21.5 | arc-08-06 | Reproducibility bundle gate (BLOCKING) |
| 22 | arc-08-03 | Export publish |
| 23 | arc-08-04 | Citation verify |
| 24 | arc-09-01 | Paper review loop (BLOCKING) |
| 24.5 | arc-09-03 | Academic integrity gate (BLOCKING) |
| 25 | arc-09-02 | Paper polish |
| 26 | arc-10-04 | Numeric truth gate |
| 26.5 | arc-10-01 | Claim evidence trace gate (BLOCKING) |
| 27 | arc-10-02 | Figure quality gate (BLOCKING) |
| 28 | arc-10-03 | Submission format gate (BLOCKING) |
| 28.5 | arc-10-05 | Final acceptance gate (BLOCKING) |

## Blocking stages (never skip)

- **Stage 0**: Missing execution/LaTeX/network capability
- **Stage 4**: Unverifiable citations (hallucination)
- **Stage 7.5**: No novelty gap confirmed
- **Stage 9.5**: Reproducibility contract incomplete
- **Stage 15.5**: Unsupported claims would enter writing
- **Stage 17.5**: Structure/marker issues remain
- **Stage 18.5**: Bibliography quality issues
- **Stage 21.5**: Reproducibility bundle incomplete
- **Stage 24**: Codex MCP external review (no fallback)
- **Stage 24.5**: Academic integrity issues
- **Stage 26.5**: Claim-evidence traceability failed
- **Stage 27**: Figure quality/authenticity failed
- **Stage 28**: Submission format noncompliance
- **Stage 28.5**: Final acceptance conditions not met

## Rollback targets

| Gate rejected | Rollback to |
|--------------|-------------|
| Stage 5 | Stage 4 |
| Stage 7.5 | Stage 7 |
| Stage 9 | Stage 8 |
| Stage 9.5 | Stage 9 |
| Stage 15.5 | Stage 15 |
| Stage 17.5 | Stage 17 |
| Stage 18.5 | Stage 17 |
| Stage 20 | Stage 16 |
| Stage 21.5 | Stage 20 |
| Stage 24.5 | Stage 24 |
| Stage 26 | Stage 19 |
| Stage 26.5 | Stage 19 |
| Stage 27/28 | Stage 22 (invalidate 23-25) |

## Quality gates never negotiate

- Minimum 6000 words in body text
- Required sections: Abstract, Introduction, Related Work, Method, Experiments, Conclusion
- Minimum 4 figures; each must be real files in `.arc/figures/rendered/`
- All citations must exist in `references.bib` with complete fields
- LaTeX must compile without errors before any stage advances

## Usage

After starting a pipeline with `/paper:run`, monitor with `/paper:status`.
If interrupted, resume with `/paper:resume`.
To reset: `/paper:reset [stage-name|all]`

## See also
- references/state-transitions.md — Detailed state machine
