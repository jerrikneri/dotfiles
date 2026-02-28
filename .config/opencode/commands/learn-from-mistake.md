---
description: "Run fast mistake-to-memory loop"
---

Execute the mistake-to-memory loop from `.ai-agents/skills/continual-improvement.md`.

Input context:
- Mistake note: `$ARGUMENTS`

Steps:
1. Reflect on the mistake and identify root pattern
2. Abstract and generalize into reusable guidance
3. Score with memory quality gate (clarity, reusability, overfit risk)
4. Resolve contradictions with existing learned bullets
5. Propose destination (`context`, `AGENTS.local.md`, or `AGENTS.md`)
6. Update memory/index only if inclusion bar and quality gate pass
7. Report what changed and why
