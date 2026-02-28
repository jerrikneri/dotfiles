---
description: "Evaluate continual-learning cadence gates"
---

Evaluate cadence gates from `.ai-agents/skills/continual-improvement.md` before running `/learn`.

Inputs:
- `workspace/context/_meta/learning-cadence.json`
- `workspace/context/_meta/learning-index.json`

Checks:
1. Minimum turns since last run
2. Minimum minutes since last run
3. At least one tracked context file changed (mtime advanced)
4. Trial mode status and expiry

Output:
- `eligible` or `deferred`
- which gate(s) passed/failed
- recommended next run window

If eligible, recommend running `/learn` now.

Optional input:
- Completed turns since last run (if available) to enforce the turns gate explicitly.

$ARGUMENTS
