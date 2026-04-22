> Release readiness protocol for deterministic ship/no-ship decisions.
> Use this when evaluating whether branch work is production ready from requirements, tests, review quality, and critical findings.

# Release Readiness Protocol

## Trigger

Use this protocol for both `/ready` and `[ready]`.

## Required Inputs

1. Current branch from `git branch --show-current`
2. Branch path token for filesystem paths: replace `/` with `-` when resolving `workspace/context/{branch}/...`
3. Authoritative criteria file: `workspace/context/{branch}/ticket-details.md`

`ticket-details.md` is the only acceptance-criteria source. Do not treat any other file as authoritative requirements.

## Missing or Incomplete Criteria Behavior (One Follow-Up Only)

If `ticket-details.md` is missing or criteria are incomplete:

1. Ask exactly one targeted follow-up question to obtain the missing criteria.
2. Mark temporary blocked state: `BLOCKED: awaiting ticket criteria clarification`.
3. Continue the protocol after that response.
4. If criteria are still incomplete after the one follow-up, fail the Requirements Gate.

Criteria are considered incomplete if any of these are true:

- The ticket file has no explicit acceptance criteria list.
- Criteria are present but not testable/verifiable as written.
- Criteria rely on undefined placeholders (`TBD`, `TODO`, "as discussed", "etc.").
- Criteria omit success conditions for required behavior.

## Deterministic Gate Rules

Return `READY` only when all gates pass.
If any gate fails, return `NOT READY`.

### 1) Requirements Gate

Pass only if every acceptance criterion from `ticket-details.md` maps to concrete implementation evidence.
Fail if any criterion is missing, partial, unknown, or untraceable.

### 2) Tests Gate

Use this deterministic order:

1. Discover default test command(s) from project conventions.
2. If available, run focused tests for changed files plus affected integration tests.
3. If automated tests exist but focused scope cannot be determined, run the default full suite.
4. If no runnable automated tests are available, ask for exactly one manual verification command.
5. If the full suite cannot be run in this environment, ask for exactly one manual verification command.

Manual verification command constraints:

- Must be non-destructive validation only (for example: status checks, lint, test, dry-run/read-only verification).
- Must not modify files, environment configuration, services, or external state.
- Capture command, exit code, and key output evidence.

Pass only with successful automated and/or manual evidence captured.

Fail if tests fail, no runnable automated tests and no valid manual command is provided, focused scope cannot be resolved and no valid manual command is provided, manual verification fails, or evidence is missing.

### 3) Review Quality Gate

Run both stages:

1. In-process hontoni review
2. Second-opinion review via `general` subagent

Pass only if both composite scores are strictly greater than 80 and include required evidence:

- file:line references for key findings
- explicit composite score calculation

`>80` is intentional and stricter than hontoni's merge threshold. This protocol is a release-readiness gate, not a merge-readiness gate.

If the `general` subagent is unavailable, return `NOT READY` and explain that the review gate could not be completed.

### 4) Critical Findings Gate

Pass only if there are no unresolved major or critical flaws (security, data integrity, correctness, or known blockers).

## Protocol Sequence

1. Resolve branch, sanitize for filesystem paths (replace `/` with `-`), and load `workspace/context/{branch}/ticket-details.md`.
2. Apply one-follow-up behavior if criteria are missing/incomplete.
3. Build acceptance-criteria traceability (criterion -> evidence -> status).
4. Execute deterministic tests gate flow.
5. Run in-process hontoni review.
6. Run second-opinion `general` subagent review with required evidence format (file:line references + composite score).
7. Evaluate all four gates.
8. Emit deterministic verdict and closure actions.

## Output Contract (Always Include)

1. **Verdict**: `READY` or `NOT READY`
2. **Gate Table**:
   - Requirements Gate (pass/fail)
   - Tests Gate (pass/fail)
   - Review Quality Gate (pass/fail)
   - Critical Findings Gate (pass/fail)
3. **Acceptance Criteria Traceability Table**
4. **Unimplemented or Partial Items**
5. **Open Questions**
6. **Risks/Concerns**
7. **Recommendations**:
   - Must-have before release
   - Nice-to-have hardening
8. **Next Commands** (specific commands to close blockers)
9. **Protocol Improvement Suggestions** (brief bullets only, appended after all verdict sections)

## Determinism and Evidence Rules

- Never fabricate evidence.
- Mark unknowns explicitly.
- Use the same gate criteria every run.
- Do not emit ambiguous verdicts.
