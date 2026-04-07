---
name: arc-writing
description: Writing phase skills for template resolution, outline creation, drafting, peer review, and revision. Use when creating the paper structure, writing content, or revising based on feedback.
---

# Arc Writing Skills

## Quick reference
- Abstract: 180-220 words (strict), starts with context not "We"
- Title: ≤14 words, method name 2-5 characters
- All figures must be evidence-bearing (from real experiments)
- De-AI writing patterns required (no "delve", "pivotal", etc.)

## Stages

### Stage 15.7: Template Resolve (arc-07-00)
Resolve target venue into machine-checkable contract:
- Supported: neurips, iclr, icml, aaai, acl, cvpr, ieee, elsevier, springer
- Compile engine: pdflatex + bibtex
- Required/forbidden sections per venue
- Figure count minimums and style rules

**Output**: `template/template_manifest.json`, `template_notes.md`

### Stage 16: Paper Outline (arc-07-01)
Build structured outline with evidence mapping:
- Abstract: 180-220 words PMR+ (Problem, Method, Results, significance)
- Title: ≤14 words, method name 2-5 chars
- All sections present (Intro, Related Work, Method, Experiments, etc.)
- Each hypothesis maps to Experiments section
- Limitations subsection required

**Output**: `outline.md`

### Stage 17: Paper Draft (arc-07-02)
Write complete paper following outline:

**Abstract (strict 180-220 words):**
- Problem → Method → Results → Significance
- Starts with context (NOT "We" or "This paper")
- ≤3 numeric values
- No citations or undefined acronyms

**All sections:**
- `\ref{}`/`\cref{}` must be valid
- All evidence from `experiment_summary.json`
- No unsubstantiated claims
- Method name consistent throughout

**Figure provenance declaration:**
```html
<!-- fig-src: stage-14/experiment_summary.json > metric_name -->
```

**De-AI polish pass:**
- delve → examine/investigate
- pivotal → central/key
- groundbreaking → substantial
- Remove: "It is worth noting", "Importantly", "Notably"

**Output**: `paper_draft.md`

### Stage 17.5: Writing Compliance Gate (arc-07-05) — BLOCKING
Structure/marker/anti-slop gate before peer review:
- Required sections present
- No TODO/FIXME/XXX/[VERIFY] markers
- No forbidden AI writing patterns
- Limitations section exists and honest

**Output**: `writing_compliance_report.json`

### Stage 18: Peer Review (arc-07-03)
Generate ≥2 simulated reviews with distinct personas:
- Theory-focused reviewer
- Reproducibility-focused reviewer
- Each: ≥1 major concern with specific section reference
- Clear Accept/Borderline/Reject recommendation

**Output**: `reviews.md`

### Stage 18.5: Bibliography Quality Gate (arc-08-05) — BLOCKING
Bibliography quality check:
- All in-text citation keys have bibliography entries
- No unresolved verification markers
- Required metadata fields present
- No duplicate key conflicts

**Output**: `bibliography_quality_report.json`

### Stage 19: Paper Revision (arc-07-04)
Address major peer review concerns:
- All major concerns tracked in `revision_log.md`
- Action per concern: Addressed / Partially addressed / Not addressed
- Location in revised paper documented
- No new unsubstantiated claims

**Output**: `paper_revised.md`, `revision_log.md`

## Required sections

| Venue type | Required |
|------------|----------|
| Conference | Abstract, Intro, Related Work, Method, Experiments, Conclusion, Broader Impact |
| Journal | Abstract, Intro, Related Work, Method, Experiments, Results, Discussion, Conclusion |

## Figure requirements

- Minimum 4 figures (AI/ML typically ≥5)
- Each must be real file in `.arc/figures/rendered/`
- Each must be referenced in text
- Each must have provenance declaration

## Word count targets

| Section | Target words |
|---------|-------------|
| Abstract | 180-220 |
| Introduction | 500-900 |
| Related Work | ≥600 |
| Method | 800-1500 |
| Experiments | 1200-2000 |
| Conclusion | 200-400 |

## Key constraints

| Stage | Constraint |
|-------|------------|
| 16 | Abstract word count strict |
| 17 | Figure provenance required |
| 17.5 | Markers block pipeline |
| 18 | ≥2 distinct reviewer personas |
| 19 | All major concerns tracked |

## Anti-hallucination in writing

1. Never claim results not in `experiment_summary.json`
2. Every figure tied to real upstream artifact
3. Citation claims must have verifiable references
4. No decorative figures — all evidence-bearing

## Usage

After research decision proceeds:
1. Template resolve → venue contract
2. Outline → structure with word targets
3. Draft → full content with provenance
4. Compliance gate → structure check
5. Peer review → stress test
6. Revision → address concerns

## See also
- arc-latex-formatting for template details
- arc-citation-style for bibliography rules
- arc-figure-codegen for figure generation
