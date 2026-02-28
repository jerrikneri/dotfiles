---
description: "Hontoni critique of completed work"
---

Apply the hontoni self-critique protocol to review work completed in this session.

Steps:
1. Load session context if not already loaded:
   - Check current git branch: `git branch --show-current`
   - Load `workspace/context/{branch}/YYYY-MM-DD-CURRENT.md` (today's date)
   - If exists, also load last session's dated file for continuity
   - This ensures full visibility into session work (same as `/resume` would provide)
2. Read the full hontoni protocol from `.ai-agents/skills/hontoni.md`
3. Identify what was changed in this session (check git diff, git status, session context, recent file modifications)
4. Score all 6 dimensions (0-100) with specific file:line evidence:
   - Correctness: Root cause vs symptom masking
   - Completeness: All code paths checked
   - Test Evidence: Exact failure reproduced
   - Fragility: Other data states that could trigger issues
   - Regression Risk: What could break
   - Seed Data Realism: Test data reflects production
5. Calculate composite score: (average + lowest) / 2
6. Output in the required format with weakness table and recommendations

Rules:
- Every score MUST cite specific file:line evidence
- "No weaknesses found" is NEVER acceptable
- Focus on the most recent substantive changes from both git and session context
- Be harsh but fair - look for real issues, not nitpicks
- If session context reveals decisions/rationale, factor that into the critique

Sources to review:
- Session context files (workspace/context/{branch}/*.md)
- Git changes (staged and unstaged)
- Any files mentioned in session context as modified
- Task lists if present (workspace/context/{branch}/tasks.md)

If specific files provided as arguments, focus the critique on those files.
Otherwise, review all work documented in the session.

$ARGUMENTS
