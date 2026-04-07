---
name: paper-reset
description: Reset a specific stage or all state
usage: /paper:reset [stage-name|all]
---

Reset a specific stage or all state.

Usage: /paper:reset [stage-name|all]

If stage-name: clear the corresponding review-*.json and set pipeline stage back
If all: clear all .arc/state/*.json files (except idea.json), reset to start

Always confirm with user before executing.

WARNING: Resetting will lose all progress! Make sure to backup important files first.

Example: /paper:reset writing
Example: /paper:reset all
