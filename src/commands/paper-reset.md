---
name: paper-reset
description: Reset specific stage or all pipeline state
usage: /paper:reset [stage-name|all]
---

Reset selected stage state or all pipeline state files.
Always ask user confirmation before reset.
When resetting a stage, also clear dependent review files and invalidate downstream stages according to rollback targets in `PROJECT_SPEC.md`.
