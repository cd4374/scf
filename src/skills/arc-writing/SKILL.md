---
name: arc-writing
description: Produces and revises manuscript drafts under hard academic quality gates. Use when building section structure, integrating evidence-backed claims, and iterating through review feedback before final export.
---

# Arc Writing

## Purpose

`arc-writing` organizes research results into submission-ready manuscripts, iterating until all gates pass.

## Configuration (read from paper-type.json)

Before writing, read `.arc/paper-type.json` for:
- `paper_format`: long | short | letter
- `paper_domain`: ai-experimental | ai-theoretical | physics | numerical
- `require_ablation`: true | false
- `page_limit`: target pages
- `abstract_max_words`: 250 (long) or 150 (short/letter)

## Section Requirements (v5)

**How to determine Ablation Study requirement**: Read `paper-type.json` → check `derived_thresholds.require_ablation`. If `true`, ablation is mandatory (ai-experimental and numerical domains). If `false`, omit the section.

| Section | Required | Condition |
|---------|----------|-----------|
| Abstract | ✓ | Word limit from paper-type |
| Introduction | ✓ | Must include contribution list |
| Related Work | ✓ | Standalone or merged with Introduction |
| Method / Theory | ✓ | Self-contained, reproducible |
| Experiments / Results | ✓ | Experimental setup, results, analysis |
| **Ablation Study** | Conditional | Mandatory if `require_ablation == true`; omit if `false` |
| **Limitations** | ✓ | **Required for ALL paper types** — no exceptions |
| Conclusion | ✓ | Summary, limitations, future work |
| References | ✓ | Per citation-style requirements |

## Inputs

- `.arc/state/pipeline-status.json`
- `.arc/state/idea.json`
- `.arc/paper-type.json`
- Experimental results and analysis conclusions
- `.arc/state/review-*.json`
- `references.bib`

## Outputs

- `draft.tex`
- State updates: `page_count`, `blocking_issues`

## Draft protocol

1. Generate outline mapped to required sections.
2. Bind each core claim to evidence (experimental results or citations).
3. Merge figures and citations; ensure text-figure-citation alignment.
4. Maintain consistent terminology, symbols, and experimental setup throughout.

## Ablation Study (conditional)

If `require_ablation == true` (ai-experimental, numerical):
- Create dedicated Ablation Study section.
- For each core component, include independent ablation control.
- Report contribution of each component.

## Limitations section

**Required for all paper types.**
- Objectively describe method boundaries and applicability.
- No paper should lack this section.

## Abstract requirements

Must include all four elements:
1. Research question
2. Method overview
3. Main results
4. Key contributions

Word limit: `abstract_max_words` from paper-type.

## Anti-fabrication rules

- No specific numerical conclusions from un-run experiments.
- No key arguments from unverified citations.
- Use conservative language for uncertain results and note limitations.

## Reproducibility linkage

Experiments section must include Reproducibility Statement:
- Random seed strategy
- Environment snapshot location (`.arc/environment.yml`)
- Data version records (`.arc/state/reproducibility.json`)

## Failure conditions

Cannot advance to export if:
- Blocking issues unresolved
- Page/section/figure/citation thresholds not met
- LaTeX compilation fails

## Style constraints

- Clear, concise, verifiable expressions.
- Avoid exaggerated claims and generic "AI-flavor" templates.
- Use `post-write-ai-pattern-check.sh` to detect AI writing patterns.

## Expected handoff

After writing phase, proceed to:
- `paper-review-loop`
- `paper-citation-loop`
- `paper-figure-loop`
- `paper-export` (after all gates pass)

## Completion checklist

- [ ] Required sections complete (per paper-type)
- [ ] Ablation study (if required)
- [ ] Limitations section present
- [ ] Abstract within word limit
- [ ] Key claims mapped to evidence
- [ ] Figure/citation counts meet thresholds
- [ ] Reproducibility statement written
- [ ] LaTeX compiles