---
name: "bug-triage"
description: "Fix, test, document, and verify production bug fixes after investigation is complete"
---

> Use AFTER investigation is done (Phase 1 is covered by the `systematic-debugging` skill).
> Covers: root cause fix principles, testing requirements, documentation template, and post-deploy verification.

---

## Phase 2: Fix

### Principle 1 -- Fix the root cause, not the symptom

Adding a null check at the crash site is *necessary* but *not sufficient*. Also fix (or at minimum understand and document) why the value is null upstream. A null guard without upstream understanding is a band-aid that hides the real problem.

### Principle 2 -- Audit all callers

If method X crashed when called from caller A, grep for ALL callers of X. Check each one.

### Principle 3 -- Layer timeouts correctly

When fixing timeout issues, ensure each layer has a *different* timeout so failures produce catchable exceptions:

| Layer | Timeout | Why |
|-------|---------|-----|
| HTTP client (auth) | Shortest (e.g., 30s) | Auth should be fast |
| HTTP client (data) | Medium (e.g., 60s) | Allows for slow APIs |
| Job timeout | Longer than HTTP (e.g., 120s) | HTTP client fails first with catchable exception |
| Worker timeout | Overridden by job timeout | Job's timeout takes precedence |

### Principle 4 -- Ensure all exit paths leave valid state

Every method that configures shared state must leave that state valid on ALL exit paths -- not just the happy path. If `authenticate()` has 3 exit paths (cached token, missing credentials, post-auth), all 3 must configure the client.

### Principle 5 -- Defensive coding with context

When adding guards or early returns, always log with enough context to debug the next occurrence.

### Anti-patterns

| Anti-pattern | Why it fails |
|-------------|-------------|
| **Masking nulls blindly** (`?.`, `??`, `&.` without investigation) | Hides upstream bugs, data keeps arriving in broken state |
| **Same-layer timeouts** (HTTP = worker = same seconds) | Race condition; worker kills process before client can throw catchable exception |
| **Single-caller fix** (only fix where it crashed) | Other callers hit the same bug with different data next week |
| **Silent swallowing** (`catch (Exception $e) { return null; }`) | Failures become invisible; no logs, no alerts, no debugging |
| **Untested fix** ("It looks right") | "Looks right" is not evidence; the original code also "looked right" |

---

## Phase 3: Testing

### Required tests for every bug fix

1. **Exact reproduction test** -- recreate the precise failure condition. If you revert the fix, this test should fail with the same exception class.

2. **Related edge case tests** -- discover adjacent failure modes. If auth failure caused the crash, test expired credentials, empty credentials, and missing credentials separately.

3. **Performance assertions (for N+1 / query fixes)** -- assert the exact number of queries or operations.

4. **Timeout/retry assertions (for timeout fixes)** -- verify the timeout hierarchy is correct in the test, not just by reading code.

5. **Full suite pass** -- run the entire test suite before opening a PR.

### Gold standard: Before/after comparison

Test on both the broken code and the fixed code with the same inputs. This proves the fix is what resolved the issue, the failure is reproducible, and the fix handles it gracefully.

---

## Phase 4: Documentation

Minimum fields for session context or PR description:

```markdown
### Problem
{Exact error message. Affected record IDs. Frequency/impact.}

### Root Cause
{Chain: X crashed because Y because Z. Be specific.}

### Fix
{Files changed with before/after code snippets for non-trivial changes.}

### Tests Added
{List each test with a one-line description of what it proves.}

### Performance Impact
{If applicable: before/after metrics, query counts, timing.}

### Next Steps
{Follow-up items. Known issues not addressed in this fix.}
```

---

## Post-Deploy Verification

After the fix is merged and deployed, verify:

- [ ] Error rate in monitoring tool drops to zero or expected baseline within 24 hours
- [ ] No new errors introduced in the same code path
- [ ] Failed job queue shows no new failures for the affected job class
- [ ] If the fix involved retry logic: confirm retries are succeeding
- [ ] If the fix involved timeout changes: confirm job completion times are within expected range

**Rollback criteria:** If the error rate does not decrease within 24 hours, or new errors appear in the same code path, revert the fix and return to investigation.
