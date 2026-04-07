---
name: paper-review
description: Trigger a specific reviewer subagent
usage: /paper:review [idea|literature|logic|stat|figures|final]
---

Trigger a specific reviewer subagent.

Usage: /paper:review [idea|literature|logic|stat|figures|final]

If no argument, run all reviews that haven't passed yet.

Available reviewers:
- idea:         idea-validator — validates research idea feasibility and novelty
- literature:   literature-reviewer — reviews literature coverage
- logic:        logic-checker — checks claim-evidence traceability
- stat:         stat-auditor — audits statistical methods and numbers
- figures:      figure-auditor — audits figure quality and authenticity
- final:        final-reviewer — aggregates all reviews for acceptance

For each requested review:
1. Check prerequisite files exist (draft.tex for most, idea.json for idea-validator)
2. Delegate to the corresponding subagent via Task tool
3. Display the review result summary when complete
4. Update pipeline-status.json with the review outcome

Example: /paper:review logic
