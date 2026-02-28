---
description: "Audit AI instruction consistency and path validity"
---

Run a hontoni-style review of AI instruction docs in this repo.

Scope:
- `AGENTS.md`
- `.ai-agents/rules/*.md`
- `.ai-agents/skills/*.md`
- `.config/opencode/commands/*.md`
- `.config/opencode/OPENCODE-EXTENSIBILITY.md`

Checks:
1. Every referenced markdown path exists.
2. Command fallback paths match actual file locations.
3. Conflicting directives are flagged with file:line evidence.
4. Output includes 6-dimension scoring + composite `(avg + lowest) / 2`.
5. Output includes mandatory weaknesses and actionable recommendations.

If arguments are provided, narrow the audit to:
$ARGUMENTS
