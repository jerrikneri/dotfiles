---
description: "Harsher re-review using a different model. Usage: /second-opinion [opus|codex]"
agent: critic-codex
---

Run a second-opinion hontoni review using a different model than the first critique.

Assume the previous critique was too lenient. Re-score from scratch with a harsher lens.

Read the full scoring protocol from `.ai-agents/skills/hontoni.md` (or `~/code/dotfiles/.ai-agents/skills/hontoni.md` if project-level doesn't exist).

Rules for second opinion:
- Score independently. Do not reference the first critique's scores.
- Default to skepticism. If something "looks fine," look harder.
- Any dimension you scored within 5 points of the first critique: justify why you agree, or lower the score.
- Produce a delta report: where the two critiques agree, where they diverge, and what the first one missed.

Score all 6 dimensions with file:line evidence.
Calculate composite score: (average + lowest) / 2.

After scoring, add a section:

### Delta Report
| Dimension | First Score | Second Score | Delta | Notes |
|-----------|------------|-------------|-------|-------|

Highlight any dimension where scores diverge by more than 10 points and investigate why.

$ARGUMENTS
