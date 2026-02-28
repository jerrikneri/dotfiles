---
description: "Hontoni critique of completed work. Usage: /critique [opus|codex]"
agent: critic-opus
---

Run a hontoni self-critique of the work just completed.

Read the full scoring protocol from `.ai-agents/skills/hontoni.md` (or `~/code/dotfiles/.ai-agents/skills/hontoni.md` if project-level doesn't exist).

Score all 6 dimensions (0-100 each):
1. Correctness -- root cause vs symptom masking
2. Completeness -- all code paths checked
3. Test Evidence -- exact failure reproduced
4. Fragility -- what other data states could trigger similar
5. Regression Risk -- what could this break
6. Seed Data Realism -- does test data reflect production

Every score MUST cite specific file:line evidence. "No weaknesses found" is NEVER acceptable.
Calculate composite score: (average + lowest) / 2.
Output in the format specified in the protocol.

If no arguments provided, critique the most recent changes in the current session.
$ARGUMENTS
