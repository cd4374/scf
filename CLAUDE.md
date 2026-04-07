# scf: Project Alignment Document

## Project Objective (Core Alignment Point)

When the full chain succeeds, it MUST yield a **high-quality, verifiable, reproducible, authentic academic paper** with at minimum:

1. **Real LaTeX sources** — locally compiled, not generated/placeholder
2. **Locally compiled PDF** — via `pdflatex` + `bibtex`, exit code 0
3. **Verified references** — every citation has resolvable DOI or arXiv ID
4. **Real experiment-backed claims** — all quantitative claims traceable to actual execution
5. **Submission-format compliance** — meets target venue specifications

**This is the non-negotiable target. All skills, gates, and workflows must align to this.**

---

## Hard Constraints (Red Lines)

### 1. Environment Blocking (Stage 0)

Missing critical capabilities **BLOCK** the pipeline:
- **Execution backend** → Required for Stages 10-13
- **Local LaTeX** → Required for Stages 22, 28 (NO cloud/Overleaf fallback)
- **Network** → Required for Stages 3-4 (DOI/arXiv verification)

### 2. Anti-Hallucination Guarantees

| Guarantee | Implementation |
|-----------|---------------|
| No fake citations | Stage 4 verifies every DOI/arXiv before accepting |
| No fake experiments | Stage 12 executes real code with anti-fabrication checks |
| No fake PDF | Stage 22 local compilation only, exit code 0 required |
| No self-review | Stage 7.5 and 24 require external Codex MCP review |

### 3. External Review Requirement (CRITICAL)

**Stage 7.5 (NOVELTY_GAP_GATE)** and **Stage 24 (PAPER_REVIEW_LOOP)** require **Codex MCP**.

- If unavailable: Fail with `E07B_CODEX_MCP_REQUIRED` or `E24_CODEX_MCP_REQUIRED`
- **NO FALLBACK**: Degraded local review is NOT permitted
- See `arc-03-03-novelty-gap-gate/SKILL.md` and `arc-09-01-paper-review-loop/SKILL.md` for setup

### 4. Global Iteration Cap

**MAX_GLOBAL_ITERATIONS = 50**

Calculated as: `pivot_count + review_rounds`

On cap reached: Pipeline fails with `E_GLOBAL_ITERATION_CAP`

---

## Stage Chain (Authoritative)

| Stage | Skill ID | Name | sub_step | Type |
|-------|----------|------|----------|------|
| 0 | arc-00-04 | ENVIRONMENT_PROBE | — | BLOCKING |
| 0 | arc-00-07 | IDEA_EXPLORATION | idea_exploration | optional |
| 1 | arc-01-01 | TOPIC_INIT | — | normal |
| 2 | arc-01-02 | PROBLEM_DECOMPOSE | — | normal |
| 3 | arc-02-01 | SEARCH_STRATEGY | — | normal |
| 4 | arc-02-02 | LITERATURE_COLLECT | — | BLOCKING |
| 5 | arc-02-03 | LITERATURE_SCREEN | — | GATE |
| 6 | arc-02-04 | KNOWLEDGE_EXTRACT | — | normal |
| 7 | arc-03-01 | SYNTHESIS | — | normal |
| 7 | arc-03-03 | NOVELTY_GAP_GATE | novelty_gap_gate | GATE (blocking) |
| 8 | arc-03-02 | HYPOTHESIS_GEN | — | normal |
| 8 | arc-03-04 | RISK_ASSESSMENT | risk_assessment | optional |
| 9 | arc-04-01 | EXPERIMENT_DESIGN | — | GATE |
| 9 | arc-04-04 | REPRODUCIBILITY_DESIGN_GATE | reproducibility_gate | GATE (blocking) |
| 10 | arc-04-02 | CODE_GENERATION | — | normal |
| 11 | arc-04-03 | RESOURCE_PLANNING | — | normal |
| 12 | arc-05-01 | EXPERIMENT_RUN | — | normal |
| 13 | arc-05-02 | ITERATIVE_REFINE | — | normal |
| 14 | arc-06-01 | RESULT_ANALYSIS | — | normal |
| 15 | arc-06-02 | RESEARCH_DECISION | — | normal |
| 15 | arc-06-03 | RESULT_CLAIM_GATE | claim_gate | GATE (blocking) |
| 15 | arc-07-00 | TEMPLATE_RESOLVE | template_resolve | normal |
| 16 | arc-07-01 | PAPER_OUTLINE | — | normal |
| 17 | arc-07-02 | PAPER_DRAFT | — | normal |
| 17 | arc-07-05 | WRITING_COMPLIANCE_GATE | writing_compliance_gate | GATE (blocking) |
| 18 | arc-07-03 | PEER_REVIEW | — | normal |
| 18 | arc-08-05 | BIBLIOGRAPHY_QUALITY_GATE | bibliography_gate | GATE (blocking) |
| 19 | arc-07-04 | PAPER_REVISION | — | normal |
| 20 | arc-08-01 | QUALITY_GATE | — | GATE |
| 20 | arc-00-06 | META_OPTIMIZER | meta_optimizer | blocking |
| 21 | arc-08-02 | KNOWLEDGE_ARCHIVE | — | optional |
| 21 | arc-08-06 | REPRODUCIBILITY_BUNDLE_GATE | reproducibility_bundle_gate | GATE (blocking) |
| 22 | arc-08-03 | EXPORT_PUBLISH | — | normal |
| 23 | arc-08-04 | CITATION_VERIFY | — | normal |
| 24 | arc-09-01 | PAPER_REVIEW_LOOP | — | BLOCKING |
| 24 | arc-09-03 | ACADEMIC_INTEGRITY_GATE | academic_integrity_gate | GATE (blocking) |
| 25 | arc-09-02 | PAPER_POLISH | — | normal |
| 26 | arc-10-04 | NUMERIC_TRUTH_GATE | numeric_truth_gate | GATE (blocking) |
| 26 | arc-10-01 | CLAIM_EVIDENCE_TRACE_GATE | claim_evidence_gate | GATE (blocking) |
| 27 | arc-10-02 | FIGURE_QUALITY_GATE | — | GATE (blocking) |
| 28 | arc-10-03 | SUBMISSION_FORMAT_GATE | — | GATE (blocking) |
| 28 | arc-10-05 | FINAL_ACCEPTANCE_GATE | final_acceptance_gate | GATE (blocking) |

---

## Rollback Targets

| Failed Stage | Rollback To |
|--------------|-------------|
| 5 | 4 |
| 7 (novelty_gap_gate) | 7 |
| 9 | 8 |
| 9 (reproducibility_gate) | 9 |
| 15 (claim_gate) | 15 |
| 17 (writing_compliance_gate) | 17 |
| 18 (bibliography_gate) | 17 |
| 20 | 16 |
| 21 (reproducibility_bundle_gate) | 20 |
| 24 (academic_integrity_gate) | 24 |
| 26 (numeric_truth_gate) | 19 |
| 26 (claim_evidence_gate) | 19 |
| 27 | 22 (invalidate 23-25) |
| 28 | 22 (invalidate 23-25) |
| 28 (final_acceptance_gate) | 28 |

---

## Hard Paper Standards (from paper_standards.md)

### Blocking Requirements

| Standard | Minimum | Enforced At |
|----------|---------|-------------|
| LaTeX Compilation | exit code 0 | Stage 22 |
| PDF Generation | Non-empty PDF | Stage 22 |
| Citation Count | ≥30 verified | Stage 23 |
| Reference Recency | AI/ML ≥30%, Physics ≥20% (last 5 years) | Stage 23 |
| Figure Count | AI/ML ≥5, Physics ≥4, Simulation ≥3 | Stage 27 |
| Numeric Truth | Claims match experiment data | Stage 26 |

---

## Success Criteria

A run is **SUCCESSFUL** if and only if:

1. ✅ Stage 0 passes (environment capable)
2. ✅ Stage 4 passes (≥50 verified candidates, no hallucinations)
3. ✅ Stage 7 (novelty_gap_gate) passes (Codex MCP confirms novelty)
4. ✅ Stage 12 completes (real experiments executed)
5. ✅ Stage 22 produces valid PDF (exit code 0)
6. ✅ Stage 23 verifies ≥30 citations
7. ✅ Stage 24 completes (Codex MCP external review)
8. ✅ Stage 26 (numeric_truth_gate) validates numeric claims
9. ✅ Stage 26 (claim_evidence_gate) approves claim-evidence traceability
10. ✅ Stage 27 approves figure quality
11. ✅ Stage 28 approves submission format
12. ✅ Stage 28 (final_acceptance_gate) grants final acceptance

**Missing any = FAILURE**

---

## Documentation Authority

This file is the **single normative protocol source** for ARC stage/gate standards.

- `README.md` is for operator onboarding and run instructions only.
- If `README.md` conflicts with this file, this file wins.
- Do not duplicate full gate/error/stage tables in README.

---

## Version

- v5.1: Simplified — removed redundant state/retry details (see harness.py), added Codex MCP section