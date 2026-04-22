---
description: "Deterministic production readiness check for current branch"
---

Run the release-readiness protocol to determine if this branch is production ready.

Requirements:
1. Use `workspace/context/{branch}/ticket-details.md` as the ONLY acceptance-criteria source.
2. Sanitize branch name for filesystem paths (replace `/` with `-`) when resolving `workspace/context/{branch}/...`.
3. If criteria are missing or incomplete, ask exactly one targeted follow-up question, mark temporary blocked state, then continue after response.
4. If criteria are still incomplete after the one follow-up, fail the Requirements Gate.
5. Run all required gates: requirements traceability, tests/manual verification, hontoni review, and second-opinion subagent review.
6. Return `READY` only when all conditions pass:
   - requirements gate passes
   - tests gate passes
   - both review composites > 80 (`80` exactly fails this gate)
   - no unresolved major/critical flaws
7. Otherwise return `NOT READY` with explicit blockers.
8. For tests/manual verification, require evidence capture: command(s), exit code(s), and key output lines. Manual verification commands must be non-destructive validation only.
9. Use severity rubric for critical findings gate:
   - critical: security/data-integrity/correctness blocker that prevents safe release
   - major: significant missing behavior or unresolved reliability risk
10. Output these sections in the response:
   - Verdict (`READY` or `NOT READY`)
   - Gate Table (Requirements, Tests, Review Quality, Critical Findings)
   - Acceptance Criteria Traceability Table
   - Unimplemented or Partial Items
   - Open Questions
   - Concerns and Risks
   - Recommendations (must-have, nice-to-have)
   - Next Commands
   - Protocol Improvement Suggestions

Additional context:
$ARGUMENTS
