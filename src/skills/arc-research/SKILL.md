---
name: arc-research
description: Research phase skills for topic initialization, literature search, knowledge synthesis, and hypothesis generation. Use when defining research direction, collecting references, or generating hypotheses.
---

# Arc Research Skills

## Quick reference
- Topic must be a SMART goal with falsifiable claim
- Literature collection requires DOI/arXiv verification (no hallucinations)
- Minimum 50 verified candidates for literature collection
- Minimum 15 papers in final shortlist

## Stages

### Stage 1: Topic Init (arc-01-01)
Transform idea into SMART goal:
- Topic: single sentence (< 100 words)
- Scope: defined (inclusions/exclusions)
- Falsifiable claim with metric and direction
- Hardware profile detection

**Output**: `goal.md`, `hardware_profile.json`

### Stage 2: Problem Decompose (arc-01-02)
Break goal into ≥3 prioritized sub-questions:
- Each SQ has `Question:` and `Testability:`
- P0 = core claim, P1 = preconditions, P2 = ablations
- Dependencies between SQs

**Output**: `problem_tree.md`

### Stage 3: Search Strategy (arc-02-01)
Build search plan with verified sources:
- ≥2 verified accessible data sources
- ≥5 unique queries (≤60 chars each)
- Each sub-question covered by ≥1 query

**Output**: `search_plan.yaml`, `sources.json`, `queries.json`

### Stage 4: Literature Collect (arc-02-02) — BLOCKING
Retrieve ≥50 verified candidate papers:
- Every DOI must resolve via doi.org
- Every arXiv ID must exist via arxiv.org
- ≥2 data sources represented
- Hallucinated references BLOCK pipeline

**Output**: `candidates.jsonl`, `verification_report.json`

### Stage 5: Literature Screen (arc-02-03) — GATE
Filter to ≥15 high-quality papers:
- Each paper: relevance_score + quality_score
- Pass threshold: relevance ≥ 0.5 AND quality ≥ 0.4
- Documented in `screening_report.md`

**Output**: `shortlist.jsonl`, `screening_report.md`

### Stage 6: Knowledge Extract (arc-02-04)
Extract structured knowledge cards:
- One card per shortlisted paper
- Fields: core_contribution, method, key_results, limitations
- Cards index with paper IDs

**Output**: `cards/{paper_id}.json`, `cards_index.json`

### Stage 7: Synthesis (arc-03-01)
Cluster papers and identify gaps:
- ≥2 thematic clusters with shared-method rationale
- ≥2 research gaps with evidence from cards
- Gap: what is missing, why it matters, supporting papers

**Output**: `synthesis.md`, `gap_analysis.json`

### Stage 7.5: Novelty Gap Gate (arc-03-03) — BLOCKING
Validate novelty of identified gaps:
- Multi-dimensional novelty assessment
- Codex MCP REQUIRED for adversarial review
- Gap must be genuinely novel vs prior work

**Output**: `novelty_gap_report.json`

### Stage 8: Hypothesis Gen (arc-03-02)
Generate ≥2 falsifiable hypotheses:
- Each: grounded gap citation, quantitative prediction, falsification condition
- Named primary metric with success threshold
- Testable within resource budget

**Output**: `hypotheses.md`, `hypothesis_index.json`

### Stage 0.7: Idea Exploration (arc-00-07) — Optional
Generate and rank ≥5 candidate ideas:
- Exploration before specific topic commitment
- Select top-ranked for Stage 1

**Output**: `ideas.json`, `selected_idea.md`

### Stage 8.5: Risk Assessment (arc-03-04) — Optional
Evaluate execution/theoretical/competitive risks:
- Classify each hypothesis: low/medium/high risk
- All high risk → rollback to Stage 8

**Output**: `risk_assessment.json`

## Key constraints

| Stage | Constraint |
|-------|------------|
| 4 | DOI verification is BLOCKING — no hallucinations |
| 5 | ≥15 papers required |
| 7.5 | Codex MCP required — no fallback |
| 8 | ≥2 hypotheses with quantitative predictions |

## Usage

Use these skills in sequence for the research phase:
1. `/paper:run --idea "research question"` to start
2. Pipeline automatically advances through research stages
3. Manual approval required at Stage 5 (literature screen gate)

## See also
- arc-pipeline for orchestration context
- arc-state-management for state file formats
