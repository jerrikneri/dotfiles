---
description: "Harsher re-review of completed work"
---

Apply a SECOND OPINION hontoni self-critique for work completed in this session.

Steps:
1. Load session context if not already loaded:
   - Check current git branch: `git branch --show-current`
   - Load `workspace/context/{branch}/YYYY-MM-DD-CURRENT.md` (today's date)
   - If exists, also load last session's dated file for continuity
2. Read the full hontoni protocol from `.ai-agents/skills/hontoni/SKILL.md`
3. Identify what changed in this session (git diff, git status, session context, recent file modifications)
4. Re-score all 6 dimensions (0-100) independently with specific file:line evidence:
   - Correctness
   - Completeness
   - Test Evidence
   - Fragility
   - Regression Risk
   - Seed Data Realism
5. Calculate composite score: (average + lowest) / 2
6. Output the required hontoni review format and include a Delta Report

Second-opinion rules:
- Assume the first critique was too lenient
- Re-score from scratch with a harsher lens
- Default to skepticism; if something "looks fine," look harder
- Every score MUST cite specific file:line evidence
- "No weaknesses found" is NEVER acceptable
- Any dimension within 5 points of the first critique must include a brief justification

Sources to review:
- Session context files (`workspace/context/{branch}/*.md`)
- Git changes (staged and unstaged)
- Any files mentioned in session context as modified
- Task list if present (`workspace/context/{branch}/tasks.md`)

After scoring, add:

### Delta Report
| Dimension | First Score | Second Score | Delta | Notes |
|-----------|------------|-------------|-------|-------|

Highlight any dimension where scores diverge by more than 10 points and explain why.

If specific files are provided as arguments, focus critique on those files.
Otherwise, review all work documented in the session.

$ARGUMENTS
