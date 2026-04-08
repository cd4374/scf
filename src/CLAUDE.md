# Arc Paper Framework

## Project
- Name: scf
- Journal target: __JOURNAL__
- Framework version: v2.0.0
- Compute environment: read `.arc/env.json` before any experiment task.

## Absolute quality gates — never negotiate
- Minimum 6000 words in body text (excluding references)
- Required sections: Abstract, Introduction, Related Work, Method, Experiments, Conclusion
- Minimum 4 figures (300 DPI+), each with a real file
- All citations must pass four-layer API verification
- Minimum 20 citations, with at least 60% from the last 5 years
- LaTeX must compile without errors
- Experimental numbers must come from real execution (no fabrication)

## Auto-loop defaults
- idea_loop MAX_ITER=10
- review_loop MAX_ITER=10
- figure_loop MAX_ITER=10
- citation_loop MAX_ITER=5

## Framework navigation
- Pipeline state file: `.arc/state/pipeline-status.json`
- Reviewer agents must not write `draft.tex`; they output to `.arc/state/review-*.json`
- Skills in `.claude/skills/` auto-load when relevant
- Use `/paper:status` before starting or resuming work

## Cross-model review
- If Codex MCP is not configured, use `multi-agent-debate` and mark `cross_model: degraded`

## Compaction survival rule
If context compacts:
1. Re-read `.arc/state/pipeline-status.json`
2. Re-read `.arc/env.json`
