# Bug Triage & Fix Protocol

> Self-contained protocol for investigating and fixing production errors.
> Works with any AI coding agent (Claude Code, Codex CLI, Open Code, Cursor, etc.).
> Portable: copy to any project's `.ai-agents/skills/` or symlink from dotfiles.

---

## Phase 1: Investigation

Do not write code until all 4 steps are complete.

### Step 1 -- Capture the error exactly

- Copy the full error message and stack trace from your error monitoring tool (Sentry, Bugsnag, Horizon, logs, etc.)
- Note the exception class (e.g., `TypeError`, `ConnectionException`, `ErrorException`)
- Record frequency and impact (how many events, how many users, how long active)
- Identify the affected record(s) by ID

### Step 2 -- Trace to the crash site

- Identify the exact `file:line` where the exception originates
- Distinguish where the exception is *thrown* vs where it is *caught* (or uncaught)
- Map the call chain from the entry point (job dispatch, HTTP request, console command) to the crash site

### Step 3 -- Identify the trigger data

Find the specific data state that caused the error. Not "a null value" but "this specific record had null credentials because the integration was configured without them."

### Step 4 -- Root cause analysis

Use this template to force depth:

```
X crashed because Y was [null / wrong type / missing / timed out].
Y was [null / wrong type / missing] because Z [failed / was never called / returned unexpected value].
Z [failed / was never called] because [upstream condition: missing config, API failure, race condition, etc.].
```

**Do not stop at the first "because."** Chase the chain until you reach a condition that explains *why the data reached this state*, not just *what the data was*.

#### Example root cause chains

**Null chain (unhandled auth failure):**
> `$this->client->get()` crashed because `$this->client` was null.
> `$this->client` was null because `authenticate()` returned null when credentials were missing.
> `setClient()` was never called because the null return from `authenticate()` was not handled.

**Leaked internal state (client object pollution):**
> `GET subjects?instanceName=...` failed with "Could not resolve host: subjects".
> The relative path was treated as a hostname because `$this->client` had no `baseUrl`.
> `$this->client` lost its `baseUrl` because `authenticate()` replaced it with a temporary
> OAuth client (no baseUrl), and on auth failure, the temp client leaked to subsequent calls.

**Timeout race condition (same-layer timeouts):**
> 50 job failures, all at exactly 60.03-60.11s.
> Worker's `pcntl_alarm` (60s) raced the HTTP client's timeout (60s) and always won.
> `TimeoutExceededException` (uncatchable by application code) was thrown instead of
> `ConnectionException` (catchable). No retries because `$tries = 1`.

**N+1 query (duplicate service calls):**
> Monitoring flagged 9 repeating spans of the same subselect query.
> `getStats()` called `getPatientCounts()` 3 times: directly, inside `getCpp()`, inside `getPace()`.
> Each call fired 3 separate `loadCount()` queries. Total: 3 x 3 = 9 identical query groups.

**Type mismatch (data layer boundary):**
> `Cannot assign string to property $weight of type ?int`.
> JSON column stores numeric values as strings. Framework enforces strict type checking on assignment.
> Data flows: DB JSON column (string) -> typed property (int) -> TypeError.

---

## Phase 2: Fix

### Principle 1 -- Fix the root cause, not the symptom

Adding a null check at the crash site is *necessary* but *not sufficient*. Also fix (or at minimum understand and document) why the value is null upstream. A null guard without upstream understanding is a band-aid that hides the real problem.

### Principle 2 -- Audit all callers

If method X crashed when called from caller A, grep for ALL callers of X. Check each one.

Example: An API service method crashed when called from one job. Auditing revealed 6 total callers (5 jobs + 1 command). Only one needed the fix because only it hit the slow endpoint -- but you cannot know that without checking all 6.

### Principle 3 -- Layer timeouts correctly

When fixing timeout issues, ensure each layer has a *different* timeout so failures produce catchable exceptions:

| Layer | Timeout | Why |
|-------|---------|-----|
| HTTP client (auth) | Shortest (e.g., 30s) | Auth should be fast |
| HTTP client (data) | Medium (e.g., 60s) | Allows for slow APIs |
| Job timeout | Longer than HTTP (e.g., 120s) | HTTP client fails first with catchable exception |
| Worker timeout | Overridden by job timeout | Job's timeout takes precedence |

If HTTP timeout = worker timeout, they race each other and the worker kills the process with an uncatchable signal before the HTTP client can throw a catchable exception.

### Principle 4 -- Ensure all exit paths leave valid state

Every method that configures shared state (like setting an HTTP client) must leave that state valid on ALL exit paths -- not just the happy path. If `authenticate()` has 3 exit paths (cached token, missing credentials, post-auth), all 3 must configure the client.

### Principle 5 -- Defensive coding with context

When adding guards or early returns, always log with enough context to debug the next occurrence:

```php
if (!$this->client) {
    Log::warning('API client not initialized - authentication may have failed', [
        'integrationId' => $this->integration?->id,
        'method' => __METHOD__,
    ]);
    return null;
}
```

```python
if not self.client:
    logger.warning("API client not initialized", extra={
        "integration_id": getattr(self.integration, "id", None),
        "method": "get_patient_details",
    })
    return None
```

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

#### 1. Exact reproduction test

Recreate the precise failure condition from your error monitoring tool. If you revert the fix, this test should fail with the same exception class as the production error.

#### 2. Related edge case tests

Discover adjacent failure modes during investigation. If auth failure caused the crash, test expired credentials, empty credentials, and missing credentials separately.

#### 3. Performance assertions (for N+1 / query fixes)

Assert the exact number of queries or operations. Do not just check "it returns the right data" -- prove the fix reduced the count.

#### 4. Timeout/retry assertions (for timeout fixes)

Verify the timeout hierarchy is correct in the test itself, not just by reading code. Assert that job timeout > HTTP timeout > auth timeout.

#### 5. Full suite pass

Run the entire test suite before opening a PR. A fix that breaks unrelated tests is not a fix.

### Gold standard: Before/after comparison

The highest-confidence verification is testing on both the broken code (main/staging) and the fixed code (feature branch) with the same inputs. This proves:
- The fix is what resolved the issue (not a coincidence)
- The failure is reproducible (not transient)
- The fix handles the failure gracefully (not just avoiding it)

Example comparison table:

| Behavior | Without fix | With fix |
|----------|------------|----------|
| What kills at 60s | Worker signal (uncatchable) | HTTP client timeout (catchable) |
| Exception type | TimeoutExceededException | ConnectionException |
| Error logged | Nothing (process killed) | Timeout error with context |
| Retry | No ($tries = 1) | Yes ($tries = 3 with backoff) |

---

## Phase 4: Documentation

Document in your project's session/context tracking system. Minimum fields:

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

## Pre-Flight (before starting)

Before writing any code, run the pre-flight assessment.
See `pre-flight.md` for the full checklist.

You MUST confirm: clarity of the bug report, scope (single vs multiple bugs), risk level, and context gaps. If any dimension is unclear, gather missing information first. Do not proceed to Phase 1 until pre-flight is complete.

---

## Self-Critique (after completing fix)

After completing all phases, you MUST run the hontoni review protocol.
See `hontoni.md` for the full scoring framework.

A fix that scores below 70 composite MUST NOT be merged without addressing the flagged weaknesses. Include the score table in the PR description or workspace context file.

---

## Post-Deploy Verification (after merge)

After the fix is merged and deployed, verify it worked:

- [ ] Error rate in monitoring tool (Sentry/Bugsnag) drops to zero or expected baseline within 24 hours
- [ ] No new errors introduced in the same code path (check for regressions)
- [ ] Failed job queue (Horizon) shows no new failures for the affected job class
- [ ] If the fix involved retry logic: confirm retries are succeeding (not just silently retrying forever)
- [ ] If the fix involved timeout changes: confirm job completion times are within expected range

**Rollback criteria:** If the error rate does not decrease within 24 hours, or new errors appear in the same code path, revert the fix and return to Phase 1 with the new information.
