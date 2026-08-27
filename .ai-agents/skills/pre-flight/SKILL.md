# Pre-Flight: Bug Fix Assessment

> Run BEFORE starting a bug fix. Assess clarity, risk, and scope.
> Catches misdiagnosis, multi-bug issues, and missing context early -- before you write code.
> Works with any AI coding agent. Portable across projects.

---

## When to Use

- Before starting any Sentry/Horizon/production error fix
- When inheriting a bug from someone else's triage
- When a bug report is vague or symptoms could have multiple causes
- When the fix might require migration, config changes, or cross-service coordination

---

## Assessment Dimensions

### 1. Clarity -- Is the bug report specific enough to act on?

| Rating | Criteria |
|--------|----------|
| Clear | Exact error message, stack trace, affected record IDs, reproduction steps |
| Partial | Error message exists but missing stack trace or record IDs. Symptoms described but not traced. |
| Vague | "It's broken" / "Users are seeing errors" / screenshot only / no stack trace |

**If Partial or Vague:** Stop. Gather the missing information before proceeding. Check error monitoring for the full stack trace, affected record IDs, frequency, and first occurrence date.

### 2. Scope -- Is this one bug or multiple?

Read the error report carefully. Look for:

- **Multiple exception classes** in the same report (e.g., `TypeError` AND `ConnectionException`) -- likely 2+ bugs
- **Multiple affected files** with unrelated code paths -- likely 2+ bugs
- **"Also" or "and" in the description** -- likely scope creep
- **Intermittent vs consistent** -- intermittent suggests race condition or data-dependent bug; consistent suggests logic error

**If multiple bugs:** Split into separate fix branches. Each bug gets its own investigation, fix, tests, and PR. Mixed fixes are harder to review, harder to revert, and harder to test.

### 3. Risk Level -- Where are errors most likely during the fix?

| Risk | Indicators | Mitigation |
|------|-----------|------------|
| **High** | Touches auth, payments, data integrity, multi-tenant boundaries, queue/job retry logic | Plan mode. Explicit test cases before coding. PR review required. |
| **Medium** | Touches shared services, API integrations, model relationships | Audit all callers. Write tests first (TDD). |
| **Low** | Isolated to one component, no shared state, clear reproduction | Direct fix with tests. |

### 4. Context Check -- Do you have what you need?

Before writing code, confirm you have:

- [ ] Access to the error monitoring tool (Sentry, Bugsnag, etc.) for the full stack trace
- [ ] The affected record IDs (can you query them locally or in staging?)
- [ ] Understanding of the call chain from entry point to crash site
- [ ] Knowledge of related recent changes (check git log for the affected files)
- [ ] Understanding of the data model relationships involved

**If any box is unchecked:** Get the missing context first. Reading code without context leads to fixing symptoms instead of causes.

### 5. Approach Check -- Are you about to reinvent something?

Before designing the fix, check:

- [ ] Has this class of error been fixed before in this codebase? (Search workspace context, PR history)
- [ ] Is there an existing pattern for this type of fix? (e.g., timeout layering, null guards with logging)
- [ ] Does a library or framework feature handle this? (e.g., Laravel's retry middleware, HTTP client timeout config)
- [ ] Is there a related open issue or PR that addresses the same area?

---

## Output Format

Before starting the fix, document your assessment:

```markdown
## Pre-Flight Assessment

**Bug:** [Error message or Sentry issue ID]
**Clarity:** [Clear / Partial / Vague] -- [what's missing if not Clear]
**Scope:** [Single bug / Multiple bugs] -- [split plan if multiple]
**Risk:** [High / Medium / Low] -- [key risk factors]
**Context gaps:** [None / list missing context]
**Approach:** [Brief plan -- root cause hypothesis, files likely involved, test strategy]
**Estimated complexity:** [Quick fix / Moderate / Significant refactor]
```

---

## Decision Gate

| Assessment | Action |
|------------|--------|
| Clear + Single + Low risk + No gaps | Proceed directly to bug triage Phase 1 |
| Any dimension is Partial/Vague | Gather missing info first |
| Multiple bugs identified | Split into separate branches |
| High risk | Use plan mode. Write test cases before coding. |
| Significant refactor needed | Write an implementation plan and get review before coding |

---

## Anti-Patterns

- **Jumping straight to code.** The fix that takes 2 hours started with 10 minutes of pre-flight. The fix that takes 2 days skipped pre-flight and fixed the wrong bug.
- **Assuming the reporter's diagnosis.** "The login is broken" might be a DNS issue, a certificate expiry, a database timeout, or an actual auth bug. Verify the error class before accepting the diagnosis.
- **Fixing in production context.** If you can't reproduce it locally or in staging, you don't understand it well enough to fix it. Get reproduction steps first.
- **Combining multiple fixes.** "While I'm in here, I'll also fix..." creates untestable PRs and makes rollback impossible.
