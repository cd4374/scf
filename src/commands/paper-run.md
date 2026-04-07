---
name: paper-run
description: Run the academic paper pipeline from the current stage
usage: /paper:run [--idea "research question"] [--journal neurips|icml|iclr|acl|ieee|elsevier|springer] [--resume]
---

Run the academic paper pipeline from the current stage.

Usage: /paper:run [--idea "research question"] [--journal neurips|icml|iclr|acl|ieee|elsevier|springer] [--resume]

Steps:
1. Read `.arc/state/pipeline-status.json` to determine current stage
2. If --idea provided, write it to `.arc/state/idea.json` and set stage to "idea-validation"
3. Execute the current stage using the appropriate arc-* skill
4. After each stage completes, update `.arc/state/pipeline-status.json`
5. If a reviewer subagent is needed, delegate via Task tool and wait for review-*.json output
6. Do not advance to next stage if any blocking issue exists in the review file
7. On completion of all stages, run /paper:export

Stage sequence:
idea-validation → literature-review → synthesis → experiment-design → experiment-run → result-analysis → writing → peer-review → final-review → export

Quality gates never negotiate:
- Minimum 6000 words in body text
- Required sections: Abstract, Introduction, Related Work, Method, Experiments, Conclusion
- Minimum 4 figures; each must be real files in .arc/figures/rendered/
- All citations must exist in references.bib with complete fields
- LaTeX must compile without errors before any stage advances
