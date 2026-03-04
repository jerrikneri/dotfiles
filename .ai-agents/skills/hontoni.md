# Hontoni: Self-Critique Protocol

> Run this review after completing a fix and before opening a PR.
> "No weaknesses found" is NEVER an acceptable answer. Every fix has trade-offs -- find them.
> Works with any AI coding agent. Portable: copy to any project or keep in dotfiles.
>
> Inspired by rigorous post-fix self-critique workflows.

---

## When to Use

- After completing any production bug fix (error monitoring alerts, failed jobs, user-reported)
- Before opening a PR for review
- When reviewing someone else's bug fix PR
- When a first review felt too lenient ("LGTM" without receipts)

---

## Scoring Dimensions

Rate each dimension 0-100. Every score MUST cite specific `file:line` evidence. No hand-waving, no vibes-based reviews.

**Core Dimensions (Always Scored):**
1. Correctness
2. Completeness  
3. Test Evidence
4. Fragility
5. Regression Risk
6. Seed Data Realism

**Additional Dimensions (When Applicable):**
7. Security (if handling user input, auth, or sensitive data)
8. Assumptions (if relying on external services or data shapes)
9. Architecture (if fix involves structural changes)
10. Standards Compliance (if project has documented standards)

### 1. Correctness -- Root cause vs symptom masking

Does the fix address WHY the error happens, or just WHERE it crashes?

| Score | Criteria |
|-------|----------|
| 90-100 | Root cause identified and fixed. Upstream failure path also addressed or intentionally documented as out of scope. |
| 70-89 | Root cause fixed at the crash site. Upstream path guarded but not fully resolved. |
| 50-69 | Symptom masked (null guard, try/catch) without investigating why the value is null/invalid. |
| 0-49 | Fix is incorrect, incomplete, or introduces new failure modes. |

**Challenge questions:**
- If I remove the defensive guard, would the upstream code still produce bad data?
- Is there an upstream fix that would make the defensive guard unnecessary?
- Does this fix solve the problem, or does it just make it silent?

### 2. Completeness -- All code paths checked?

Did the investigation cover all callers, all exit paths, and all branches?

| Score | Criteria |
|-------|----------|
| 90-100 | All callers audited. All exit paths verified. Sister methods checked for the same class of bug. |
| 70-89 | Direct callers checked. Some indirect or less-obvious paths not verified. |
| 50-69 | Only the crashing caller fixed. Other callers not examined. |
| 0-49 | Fix is partial. Other code paths will produce the same error with different data. |

**Challenge questions:**
- How many callers of the affected method exist? (Run a grep. Count them. List them.)
- Does the method have multiple exit paths? Are they ALL leaving valid state?
- Could a different caller trigger this same bug class with different data?

**Red flag:** If you fixed one caller without grepping for others, score no higher than 60.

### 3. Test Evidence -- Exact failure reproduced?

Do the tests prove the fix works by reproducing the exact failure condition from production?

| Score | Criteria |
|-------|----------|
| 90-100 | Test reproduces exact production failure. Edge cases covered. Query/timing assertions where applicable. Before/after comparison on broken vs fixed code. |
| 70-89 | Test covers the fix but does not exactly replicate the production failure condition. |
| 50-69 | Tests exist but only cover the happy path near the changed code. |
| 30-49 | Tests exist but are trivial (e.g., "returns true" without exercising the fix). |
| 0-29 | No tests, or tests that don't exercise the changed code at all. |

**Challenge questions:**
- If I revert the fix, does the test fail with the same error class reported in production?
- Did I test the exact data state that triggered the production error (not a simplified version)?
- For N+1 fixes: did I assert query counts?
- For timeout fixes: did I verify timeout layering in the test?

**Scoring note:** A perfect 100 requires extraordinary evidence like a main-vs-feature-branch comparison proving the fix is what resolved the issue (not coincidence).

### 4. Fragility -- What other data states could trigger similar?

Would the fix survive slightly different inputs, or is it held together with duct tape?

| Score | Criteria |
|-------|----------|
| 90-100 | Multiple data states tested. Defensive coding handles known variants and plausible future variants. |
| 70-89 | Known variants handled. Some plausible adjacent states untested but unlikely. |
| 50-69 | Only the exact production case handled. Adjacent data states not considered. |
| 0-49 | Fix is brittle. Minor data variations would cause the same class of error. |

**Challenge questions:**
- What if credentials are present but *expired* instead of missing?
- What if the API returns 200 with an empty body instead of a 401?
- What if the record exists but a required relationship is null?
- What other enum values or model states could reach this code path?

**Red flag:** Methods with 3+ exit paths where only 1 was tested.

### 5. Regression Risk -- What could this break?

Could this fix change behavior for records that were NOT failing?

| Score | Criteria |
|-------|----------|
| 90-100 | All existing tests pass. Change is backward-compatible (optional params, additive behavior only). |
| 70-89 | Tests pass but method signature changed. All callers verified manually or by tests. |
| 50-69 | Behavior change could affect callers not covered by tests. |
| 0-49 | Breaking change with no test coverage on affected callers. |

**Challenge questions:**
- Did the method signature change? Are all callers passing the correct args?
- Did a return type change? Do callers handle the new type (e.g., `?string` where it was `string`)?
- Could this fix change behavior for records that are currently working fine?
- Did I run the full test suite, not just the tests I wrote?

### 6. Seed Data Realism -- Does test data reflect production?

Do the tests use realistic data structures, or minimal stubs that would never exist in production?

| Score | Criteria |
|-------|----------|
| 90-100 | Test data mirrors production conditions: full relationship chains, factory states, realistic field values. |
| 70-89 | Test data is valid but simplified. Missing some production relationships that are not directly relevant. |
| 50-69 | Minimal stubs. Key relationships missing. Would not catch bugs caused by data shape differences. |
| 0-49 | Hardcoded values that bypass factories, validation, and relationship creation. |

**Challenge questions:**
- Does the test create the full relationship chain needed by the code under test?
- Would this test catch a bug caused by a missing or null relationship in production data?
- Am I using factories/fixtures with proper states, or just hardcoded constructor calls?

### 7. Security (When Applicable)

**Only score if:** Fix handles user input, authentication, authorization, or sensitive data.

| Score | Criteria |
|-------|----------|
| 90-100 | All inputs validated. No injection vectors. Secrets handled properly. Auth verified. |
| 70-89 | Basic security measures. Some validation gaps but low exploitability. |
| 50-69 | Minimal security consideration. Trusts some inputs. Potential for misuse. |
| 0-49 | Security vulnerabilities present. Injection possible. Secrets exposed. |

**Red flags:** SQL concatenation, shell commands with user input, eval/exec, logging passwords/tokens.

### 8. Assumptions (When Applicable)

**Only score if:** Fix depends on external services, APIs, or specific data shapes.

| Score | Criteria |
|-------|----------|
| 90-100 | All assumptions documented and validated. Handles unexpected responses. |
| 70-89 | Key assumptions identified. Most validation in place. |
| 50-69 | Implicit assumptions about availability/shape. Limited validation. |
| 0-49 | Many hidden assumptions. Will break with different responses. |

**Challenge:** What if the API changes tomorrow? What if this field is null?

### 9. Architecture (When Applicable)

**Only score if:** Fix involves structural changes, new abstractions, or cross-component changes.

| Score | Criteria |
|-------|----------|
| 90-100 | Clear separation. Low coupling. Easy to test/deploy/monitor. |
| 70-89 | Generally well-structured. Some coupling but manageable. |
| 50-69 | Mixed concerns. Moderate coupling. Hard to test in isolation. |
| 0-49 | High coupling. Untestable. Will cause deployment issues. |

### 10. Standards Compliance (When Applicable)

**Only score if:** Project has documented standards (AGENTS.md, CLAUDE.md, ADRs).

| Score | Criteria |
|-------|----------|
| 90-100 | Follows all standards or documents deviations with rationale. |
| 70-89 | Mostly compliant. Minor undocumented deviations. |
| 50-69 | Significant drift from standards. No acknowledgment. |
| 0-49 | Ignores patterns. Reinvents existing utilities. |

---

## Composite Score

```
composite = (average_of_all_dimensions + lowest_dimension) / 2
```

One weak dimension drags down the entire score. You cannot hide behind a high average when your test evidence score is a 30.

**Example:**
- Correctness: 90, Completeness: 85, Test Evidence: 40, Fragility: 75, Regression: 90, Seed Data: 70
- Average: 75.0
- Lowest: 40 (Test Evidence)
- **Composite: (75 + 40) / 2 = 57.5** -- below threshold, do not merge

---

## Thresholds

| Composite | Action |
|-----------|--------|
| 80+ | Ready for PR review. |
| 70-79 | Address noted weaknesses before opening PR. |
| 60-69 | Significant gaps. Revisit investigation or testing phase. |
| Below 60 | Fix is incomplete. Return to Phase 1 of the bug triage protocol. |

---

## Output Format

After scoring, produce this summary. Include it in your session documentation or PR description.

```markdown
## Hontoni Review

| Dimension | Score | Key Finding |
|-----------|-------|-------------|
| Correctness | -- | [One-line summary with file:line reference] |
| Completeness | -- | [One-line summary with file:line reference] |
| Test Evidence | -- | [One-line summary with file:line reference] |
| Fragility | -- | [One-line summary with file:line reference] |
| Regression Risk | -- | [One-line summary with file:line reference] |
| Seed Data | -- | [One-line summary with file:line reference] |
| Security* | -- | [One-line summary with file:line reference] |
| Assumptions* | -- | [One-line summary with file:line reference] |
| Architecture* | -- | [One-line summary with file:line reference] |
| Standards* | -- | [One-line summary with file:line reference] |

*Only included when applicable (see dimension descriptions)

**Composite: (avg + lowest) / 2 = X.X**

### Weaknesses (mandatory)
1. [file:line] -- [specific weakness with evidence]
2. [file:line] -- [specific weakness with evidence]

### Recommendations
1. [Actionable improvement with specific guidance]
2. [Actionable improvement with specific guidance]
```

---

## Rules

1. **Every score must cite `file:line` evidence.** "Tests look good" is not a score justification.
2. **"No weaknesses found" is never acceptable.** Every fix has trade-offs. Find them and document them. If the trade-offs are intentional, say so explicitly.
3. **A perfect 100 on any dimension requires extraordinary evidence.** Before/after branch comparison, comprehensive edge case coverage, or similar. 95 is already exceptional work.
4. **Any dimension below 80 MUST generate a specific, actionable recommendation.** Not "improve tests" but "add a test that verifies getDetails returns null when credentials are expired, not just when they are missing."
5. **Scoring your own work is harder than scoring others.** Default to skepticism. The most dangerous review is the one that lets something slide.
6. **Second opinion:** If the first critique scored above 80 composite, consider re-running with the explicit instruction "assume the first review was too lenient." Compare the two scores and investigate divergences.

---

## Automatic Review Triggers

The following should always trigger an automatic hontoni review without being asked:
- Completing a bug fix (any error from monitoring/logs)
- Creating or modifying `.ai-agents/skills/` or `.ai-agents/rules/`
- Implementing features that touch 3+ files
- Any changes involving auth, payments, or data integrity
- Before opening any PR

Include the review table in your response with a note like "Auto-review complete (composite: X.X)" so it's clear this was proactive, not requested.

---

## Example Review

Here's a complete review of a hypothetical API integration bug fix:

```markdown
## Hontoni Review

| Dimension | Score | Key Finding |
|-----------|-------|-------------|
| Correctness | 85 | api_service.rb:142 - Fixed root cause (missing retry), not just symptom |
| Completeness | 70 | api_service.rb:89 - Checked 3/4 callers, missed background job caller |
| Test Evidence | 90 | api_service_spec.rb:234 - Reproduces exact timeout scenario with VCR |
| Fragility | 75 | api_service.rb:145 - Handles timeout/network errors, not rate limits |
| Regression Risk | 95 | No signature changes, backward compatible retry behavior |
| Seed Data | 80 | api_service_spec.rb:45 - Uses factory but simplified API response |
| Security* | 85 | api_service.rb:148 - Validates webhook signatures properly |
| Assumptions* | 65 | api_service.rb:152 - Assumes API always returns JSON, no XML handling |
| Architecture* | N/A | Simple fix, no structural changes |
| Standards* | 90 | Follows project's established retry pattern from ADR-003 |

*Security included due to webhook handling, Assumptions due to external API dependency, Standards due to existing ADRs

**Composite: (avg + lowest) / 2 = (81.1 + 65) / 2 = 73.05**

### Weaknesses (mandatory)
1. api_service.rb:89 - BackgroundJobCaller#sync_data also calls this method but wasn't checked for impact
2. api_service.rb:152 - No handling for API returning XML/HTML error pages instead of JSON

### Recommendations
1. Add test for BackgroundJobCaller integration and verify retry behavior works in job context
2. Add response type validation before JSON parsing, handle non-JSON responses gracefully
```

This example shows how conditional dimensions are included when relevant and omitted when not applicable.
