---
name: arc-state-management
description: State management protocol for reading and writing pipeline state files. Use when checking pipeline status, updating state, or understanding state file formats.
---

# Arc State Management

## Quick reference
- Pipeline state: `.arc/state/pipeline-status.json` — read FIRST after interruption
- Review outputs: `.arc/state/review-*.json` — never edit draft.tex directly
- All state files are JSON format

## State files

### pipeline-status.json
Main pipeline state file:
```json
{
  "stage": "not-started | idea-validation | literature-review | synthesis | experiment-design | experiment-run | result-analysis | writing | peer-review | final-review | export",
  "journal": "neurips | icml | iclr | aaai | ieee | elsevier | springer | acl",
  "word_count": 0,
  "word_count_ok": false,
  "figure_count": 0,
  "active_agent": "",
  "stages_completed": [],
  "last_updated": "ISO-8601"
}
```

### idea.json
Research idea input:
```json
{
  "research_question": "",
  "keywords": [],
  "target_journal": "",
  "created_at": "ISO-8601"
}
```

### review-*.json
Reviewer agent outputs (6 types):
```json
{
  "agent": "agent-name",
  "timestamp": "ISO-8601",
  "pass": true | false,
  "score": 0-100,
  "issues": [
    {
      "location": "Section X, paragraph Y",
      "type": "unsupported_claim | circular | contradiction | gap | missing_ref | wrong_format | stat_error",
      "description": "具体描述",
      "severity": "blocking | warning"
    }
  ],
  "summary": "一段话总结"
}
```

Reviewer output files:
- `review-idea.json` — idea validation
- `review-literature.json` — literature coverage
- `review-logic.json` — logical consistency
- `review-stat.json` — statistical audit
- `review-figures.json` — figure quality
- `review-final.json` — final acceptance

## State reading protocol

### After interruption
1. Read `.arc/state/pipeline-status.json`
2. Identify current stage
3. Read corresponding `review-*.json` if exists
4. Resume from appropriate point

### After context compaction
1. Read `.arc/state/pipeline-status.json`
2. Re-orient to current stage
3. Continue with `/paper:resume`

## State writing protocol

### Pipeline state updates
Write to `.arc/state/pipeline-status.json`:
- Stage advancement
- Word count updates
- Figure count updates
- Active agent tracking

### Review agent outputs
Reviewers write to `.arc/state/review-*.json`:
- NEVER edit `draft.tex` directly
- Output structured JSON with issues
- Main agent reads review and applies fixes

## Reviewer isolation rules

**CRITICAL**: Reviewer subagents are READ-ONLY:
- Tools: `Read`, `Glob`, `Grep` ONLY
- NO Write/Edit tools
- Output goes to `review-*.json`
- Main agent applies fixes

This isolation ensures reviewers cannot modify the paper directly.

## Stage transitions

When a stage completes:
1. Update `pipeline-status.json` with new stage
2. Add completed stage to `stages_completed`
3. Update `last_updated` timestamp

## State file locations

```
.arc/
├── state/
│   ├── pipeline-status.json
│   ├── idea.json
│   ├── review-idea.json
│   ├── review-literature.json
│   ├── review-logic.json
│   ├── review-stat.json
│   ├── review-figures.json
│   └── review-final.json
├── hooks/
│   └── *.sh (7 gate/quality scripts)
├── figures/
│   └── rendered/
└── memory/
    ├── domain-knowledge/
    └── failure-log/
```

## Key constraints

| Constraint | Requirement |
|------------|-------------|
| State file format | Valid JSON |
| Reviewer isolation | Read-only (no Write/Edit) |
| Review output location | `.arc/state/review-*.json` |
| Stage update | Always update last_updated |

## Usage

### Check status
```
/paper:status
```
Reads `pipeline-status.json` and all `review-*.json` files.

### Resume after interruption
```
/paper:resume
```
Reads state, identifies resume point, continues.

### Reset state
```
/paper:reset [stage-name|all]
```
Clears state files and resets to start.

## See also
- arc-pipeline for stage definitions
- `.claude/agents/` for reviewer subagent specifications
