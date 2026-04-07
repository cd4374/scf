# Arc Paper Framework

## Project
- Journal target: __JOURNAL__
- Framework: arc-harness v2.0

## Absolute quality gates — never negotiate
- Minimum 6000 words in body text (excluding references)
- Required sections: Abstract, Introduction, Related Work, Method, Experiments, Conclusion
- Minimum 4 figures; each must be referenced in text and exist as a real file in .arc/figures/rendered/
- All citations must exist in references.bib with complete fields
- LaTeX must compile without errors before any stage advances

## How to navigate this framework
- Pipeline state: `.arc/state/pipeline-status.json` — read this first after any interruption
- Inter-agent results go to `.arc/state/review-*.json` — reviewers never edit draft.tex directly
- Skills in `.claude/skills/` load automatically when relevant
- Reviewer subagents in `.claude/agents/` are isolated — delegate, never inline-review
- Use `/paper:status` to check current stage before starting work

## Compaction survival rule
If context compacts, re-read `.arc/state/pipeline-status.json` before any action.
