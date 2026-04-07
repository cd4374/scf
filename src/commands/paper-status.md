Display current pipeline status and any blocking issues.

Read `.arc/state/pipeline-status.json` and all `review-*.json` files.
Output a concise table showing:
- Current stage and completion percentage
- Pass/fail status of each completed review
- Any blocking issues that must be resolved
- Word count vs target (from pipeline-status.json)
- Figure count vs minimum required

Example output:
```
=== Pipeline Status ===

Stage: writing (75%)
Journal: neurips

Reviews:
  idea-validator:     PASS ✓
  literature-reviewer: PASS ✓
  logic-checker:       PASS ✓
  stat-auditor:        PASS ✓
  figure-auditor:      PASS ✓
  final-reviewer:      PENDING ○

Quality:
  Word count: 5234 / 6000 (need 766 more)
  Figure count: 5 / 4 ✓
  LaTeX compile: PASS ✓

Blocking issues: none
```
