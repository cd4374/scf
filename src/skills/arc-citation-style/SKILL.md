---
name: arc-citation-style
description: Citation management and bibliography quality skills. Use when verifying citations, checking bibliography quality, or ensuring reference compliance.
---

# Arc Citation Style Skills

## Quick reference
- All citations MUST have verifiable DOI or arXiv ID
- Hallucinated citations BLOCK pipeline (Stage 4 and Stage 23)
- Minimum 30 verified references required
- ≥20% references from last 5 years (AI/ML: ≥30%)

## Stages

### Stage 4: Literature Collect (arc-02-02) — BLOCKING
Collect ≥50 verified candidate papers:
- Every DOI resolves via doi.org
- Every arXiv ID exists via arxiv.org
- ≥2 data sources
- Hallucinated references → immediate block

**Output**: `candidates.jsonl`, `verification_report.json`

### Stage 23: Citation Verify (arc-08-04) — CRITICAL
Verify all citations in final paper:

**Two-tier verification:**
| Source | Verification |
|--------|-------------|
| Tier 1: From Stage 4 | Reuse cached verification |
| Tier 2: NEW citations | Fresh API verification |

**NEW citation verification:**
1. DOI → CrossRef
2. arXiv ID → arxiv.org
3. OpenAlex title search

**Blocking conditions:**
- `hallucinated > 0` → BLOCK
- `unverifiable > 0` → BLOCK
- Citation threshold not met → BLOCK

**Output**: `verification_report.json`, `references_verified.bib`

### Stage 18.5: Bibliography Quality Gate (arc-08-05) — BLOCKING
Bibliography quality checks:
- All in-text `\cite{}` keys have entries
- No unresolved verification markers
- Required metadata fields complete
- No duplicate key conflicts

**Output**: `bibliography_quality_report.json`

## Bibliography requirements

### Minimum counts
- Total references: ≥30
- Recent references: ≥20% from last 5 years (AI/ML: ≥30%)

### Entry requirements
```bibtex
@article{key,
  author = {LastName, First},
  title = {Paper Title},
  year = {2024},
  journal = {Journal Name},
  volume = {1},
  pages = {1--10},
  doi = {10.xxxx/xxxxx}
}
```

### Citation commands by venue
| Venue | Commands |
|-------|----------|
| NeurIPS/ICLR/ICML | `\citep{key}`, `\citet{key}` |
| IEEE | `\cite{key}` |
| ACL | `\citep{key}`, `\citet{key}` |

## Hallucination detection

Hallucinated citation patterns:
- DOI doesn't resolve (404)
- arXiv ID doesn't exist
- Title doesn't match metadata
- Metadata incomplete/implausible

**On detection:**
1. Log to `hallucination_rejects.jsonl`
2. Remove from candidate set
3. Report in verification report
4. If ANY hallucinations → BLOCK

## Verification report format

```json
{
  "total_citations": 47,
  "known_verified": 35,
  "new_verified": 8,
  "new_unverifiable": 2,
  "new_hallucinated": 2,
  "recent_reference_ratio": 0.26,
  "reference_count_min": 30,
  "reference_count_pass": true,
  "recent_reference_ratio_min": 0.20,
  "recent_reference_ratio_pass": true,
  "stage_blocked": true
}
```

## Key constraints

| Constraint | Requirement |
|------------|-------------|
| DOI verification | Must resolve (HTTP 200/303) |
| arXiv verification | Must exist (HTTP 200) |
| Citation count | ≥30 verified |
| Recent ratio | ≥20% last 5 years (AI/ML ≥30%) |
| Hallucination | ZERO tolerance — blocks pipeline |

## Anti-hallucination guarantees

1. **No fake papers**: Every paper from real API
2. **No fake DOIs**: Every DOI resolves
3. **No fake arXiv**: Every arXiv ID exists
4. **Audit trail**: All rejections logged

## Usage

1. Stage 4: Initial literature collection with verification
2. Writing: Add NEW citations as needed
3. Stage 23: Re-verify all citations (reuse Stage 4 cache)
4. Stage 18.5: Bibliography quality gate
5. Stage 28: Final submission format check

## See also
- arc-research for literature collection
- arc-writing for citation integration
- arc-latex-formatting for template-specific citation commands
