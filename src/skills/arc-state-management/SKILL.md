---
name: arc-state-management
description: Defines read/write protocols for .arc/state/ files, including schemas, stage transitions, and loop status tracking. Use when reading, updating, or validating pipeline state across sessions.
---

# Arc State Management

## Purpose

Define the canonical state file schemas and read/write protocols for `.arc/state/`.

## State directory structure

```
.arc/state/
├── pipeline-status.json   # Main pipeline state (single source of truth)
├── idea.json              # Research idea details
├── reproducibility.json   # Reproducibility artifacts
├── review-*.json          # Review outputs (13 files)
└── loop_logs/             # Loop iteration logs
```

## Pipeline stages (v5, authoritative)

**Must stay identical across 5 locations**:
- `docs/pipeline-states.md`
- `src/commands/paper-run.md`
- `src/skills/arc-pipeline/SKILL.md`
- `src/skills/arc-state-management/SKILL.md`
- `src/arc/state/pipeline-status.json`

```
not-started → paper-init → idea-exploration → idea-validation →
literature-review → synthesis → hypothesis-generation →
experiment-design → experiment-run → result-analysis →
writing → figure-generation → citation-verification →
integrity-check → stat-audit → peer-review → codex-review →
final-review → export → completed
```

**v5 new stages**: `paper-init`, `integrity-check`, `stat-audit`

## pipeline-status.json schema

```json
{
  "stage": "string (one of above values)",
  "journal": "string",
  "paper_type": {
    "format": "long | short | letter",
    "domain": "ai-experimental | ai-theoretical | physics | numerical",
    "target_venue": "string",
    "page_limit": "integer"
  },
  "figure_count": "integer",
  "table_count": "integer",
  "reference_count": "integer",
  "page_count": "integer",
  "active_agent": "string",
  "stages_completed": ["string"],
  "last_updated": "ISO-8601",
  "loop_status": {
    "idea_loop": {
      "current_round": "integer",
      "max_rounds": 3,
      "best_score": "integer",
      "status": "not-started | in-progress | completed | max-iter-reached | human-intervention-needed"
    },
    "review_loop": {
      "current_round": "integer",
      "max_rounds": 4,
      "best_score": "integer",
      "score_history": ["integer"],
      "status": "string"
    },
    "figure_loop": {
      "current_round": "integer",
      "max_rounds": 5,
      "figures": {"fig_id": "score"},
      "status": "string"
    },
    "citation_loop": {
      "current_round": "integer",
      "max_rounds": 3,
      "verified_count": "integer",
      "hallucinated_count": "integer",
      "status": "string"
    }
  },
  "ai_pattern_warnings": ["string"],
  "active_experiments": [
    {
      "session_name": "string",
      "host": "string",
      "status": "running | completed | collected",
      "started_at": "ISO-8601"
    }
  ],
  "blocking_issues": [
    {
      "type": "string",
      "details": "any",
      "severity": "blocking | major | minor"
    }
  ],
  "citation_status": {
    "verified_count": "integer",
    "hallucinated_count": "integer"
  }
}
```

**v5 deprecated fields**: `word_count`, `word_count_ok` (replaced by `page_count` + `paper-type.page_limit`)

## Read protocol

All skills/agents reading state:

1. Use `Read` tool on `.arc/state/pipeline-status.json`
2. Parse with JSON (no grep/sed)
3. Check `blocking_issues` before advancing
4. For reviewers: pass `paper_type` context to review output

## Write protocol

All skills/agents writing state:

1. Read existing state first (no blind overwrites)
2. Preserve all existing fields not being updated
3. Always update `last_updated` timestamp
4. Append to arrays (blocking_issues, stages_completed) rather than replace unless explicit reset
5. Use `json.dump(indent=2)` for readability

## Loop status updates

**idea_loop**: Update after each idea generation round
**review_loop**: Update score_history after each review, check for 2-consecutive-decline
**figure_loop**: Update per-figure scores
**citation_loop**: Update verified/hallucinated counts

## Blocking issues schema

```json
{
  "type": "missing_sections | missing_figures | missing_table | citation_threshold | page_limit | integrity_violation | stat_violation",
  "details": ["string"] | "string",
  "severity": "blocking | major | minor"
}
```

## Review output schema (v5 unified)

```json
{
  "agent": "string",
  "timestamp": "ISO-8601",
  "paper_type_context": {
    "format": "string",
    "domain": "string"
  },
  "pass": "boolean",
  "score": "integer 0-100",
  "decision": "accept | minor | major | reject | pass | fail",
  "issues": [
    {
      "location": "string",
      "type": "string (enum)",
      "description": "string",
      "severity": "blocking | major | minor",
      "standard_ref": "string (optional)"
    }
  ],
  "strengths": ["string"],
  "summary": "string"
}
```

## Issue type enum (v5)

```
unsupported_claim | circular | contradiction | gap | missing_ref | hallucinated_ref | wrong_format | stat_error | cherry_picking | missing_ablation | missing_limitations | missing_error_bars | missing_significance_test | figure_missing | figure_quality | figure_format | figure_colorblind | table_missing | novelty_insufficient | reproducibility_issue | integrity_violation | ai_writing_pattern | premise_attack
```

## Cross-session recovery

When context compacts:

1. Read `pipeline-status.json` first
2. Read `.arc/env.json` for compute context
3. Read `.arc/paper-type.json` for thresholds
4. Resume from `stage` value, check `blocking_issues`

## Synchronization points

State must stay consistent with:
- Hooks update state via Python embedded scripts
- Commands update state via skill orchestration
- Reviewers output to state via subagent writes

## Notes

- This skill defines protocol; actual writes happen via skills/commands/hooks
- Never modify state manually; use defined entry points
