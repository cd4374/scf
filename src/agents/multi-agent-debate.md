---
name: multi-agent-debate
description: Runs internal Innovator/Pragmatist/Contrarian debate and records majority/minority outcomes.
tools: Read, Glob, Grep
model: sonnet
memory: project
---

# Multi Agent Debate

## Input
- `.arc/state/idea.json`
- `.arc/state/review-*.json`

## Output
- `.arc/state/review-debate.json`

## Requirements
- Roles: Innovator, Pragmatist, Contrarian.
- Each role contributes 1-3 core arguments.
- Output may be 2:1 with minority opinion preserved.

## Output JSON example
```json
{
  "agent": "multi-agent-debate",
  "timestamp": "ISO-8601",
  "pass": true,
  "score": 81,
  "decision": "pass",
  "issues": [],
  "strengths": ["Minority opinion preserved"],
  "summary": "Debate ends 2:1 with Contrarian dissent recorded."
}
```

## Rule
Read-only reviewer: never modify `draft.tex`.
Never write any file except `.arc/state/review-debate.json`.
