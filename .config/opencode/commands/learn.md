---
description: "Run continual improvement memory sync"
---

Execute the continual improvement protocol from `.ai-agents/skills/continual-improvement/SKILL.md`.

Quick trigger phrase for mistake-driven learning:
- `Reflect on this mistake. Abstract and generalize the learning. Propose updates to AGENTS.md managed sections.`

For fast single-incident capture, use `/learn-from-mistake <note>`.
For cadence-gated runs, evaluate `/learn-cadence` first.

Steps:
1. Load `AGENTS.md` and `AGENTS.local.md` (if present)
2. Load incremental state from `workspace/context/_meta/learning-index.json`
3. Process only new or changed context and prompt files
4. Propose and apply scoped updates to managed learned sections
5. Update incremental state and summarize what changed

Optional helper for step 5:
- `.scripts/update_learning_index.sh`

$ARGUMENTS
