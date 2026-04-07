---
name: paper-resume
description: Resume the pipeline from where it was interrupted
usage: /paper:resume
---

Resume the pipeline from where it was interrupted.

1. Read `.arc/state/pipeline-status.json`
2. Identify the last completed stage and the current incomplete stage
3. Summarize what was done and what remains
4. Ask user to confirm before resuming
5. Continue with /paper:run logic from the current stage

If context was compacted, re-read `.arc/state/pipeline-status.json` first to re-orient.
