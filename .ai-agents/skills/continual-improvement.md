# Continual Improvement Protocol

> Incrementally learn stable user preferences and workspace facts from session context, then update memory docs in a scoped and safe way. Use when running `/learn`, before `/compact`, or after completing meaningful multi-step work.

## Purpose

Improve future agent behavior without overfitting to one-off prompts and without storing sensitive data.

## Fast Trigger

Use this sentence when a mistake is corrected and should become durable guidance:

`Reflect on this mistake. Abstract and generalize the learning. Propose updates to AGENTS.md managed sections.`

This trigger runs a short learning loop from fresh context instead of waiting for a full memory sync.

## Inputs

- `AGENTS.md`
- `AGENTS.local.md` (if present)
- `workspace/context/{branch}/YYYY-MM-DD-CURRENT.md`
- `workspace/context/{branch}/prompts/YYYY-MM-DD.md`
- `workspace/context/_meta/learning-index.json` (incremental state)

## Learning Targets

- Repeated user preferences (workflow, communication, tool usage)
- Durable workspace facts (repo conventions, recurring constraints)
- Reusable process improvements that should become stable protocol
- Repetitive patterns that could become skills (multi-step workflows, complex instructions)

## Inclusion Bar

Keep an item only if all are true:

- Actionable in future sessions
- Stable across tasks or explicitly stated as a general rule
- Repeated in more than one context entry, or clearly declared as policy
- Non-sensitive and safe to persist
- Specific enough to change future behavior

## Exclusions

Never persist:

- Secrets, credentials, tokens, private personal data
- One-off task instructions
- Temporary details (branch names, commit hashes, transient errors)
- Unverified assumptions or speculative claims

## Managed Sections Contract

When writing learned memory in `AGENTS.md`, only modify these sections:

- `## Learned User Preferences`
- `## Learned Workspace Facts`
- `## Learned Agent Workflow Improvements`

Use plain bullet points in these sections only. Keep bullets concise and deduplicated.

Personal-only preferences belong in `AGENTS.local.md` (if used).

Memory budget:

- Keep each managed learned section to at most 10 bullets.
- If a section would exceed 10 bullets, merge or remove lower-value bullets first.

## Meta-Rules For Writing New Memory

When adding or revising bullets in managed sections:

- Start with an action verb (`Prefer`, `Use`, `Avoid`, `Keep`, `Run`).
- Keep each bullet single-purpose and concise.
- Explain the "why" only when non-obvious.
- Prefer concrete terms over abstract phrasing.
- Merge semantically similar bullets instead of adding near-duplicates.
- If a new detailed rule is added elsewhere, ensure the learned section has a short summary bullet.

Anti-bloat rules:

- Do not add examples unless ambiguity is likely.
- Do not add warnings for obvious guidance.
- Do not preserve contradictory bullets; replace or merge them.

## Mistake-To-Memory Loop

Use this loop after correcting a non-trivial mistake:

1. Reflect: what failed and why.
2. Abstract: identify the general pattern, not task-specific details.
3. Generalize: form reusable guidance for future sessions.
4. Validate: check inclusion bar and exclusions.
5. Persist: update managed sections and incremental index.

If confidence is low, log candidate guidance in branch context instead of AGENTS memory.

## Promotion Pipeline

Use this promotion path to prevent premature global rules:

1. Candidate (branch context): log a proposed rule with evidence.
2. Local (`AGENTS.local.md`): keep personal or unproven guidance here first.
3. Shared (`AGENTS.md`): promote only after repeated evidence and stable outcomes.

Promotion gates:

- Candidate -> Local: at least one clear mistake pattern with reusable wording.
- Local -> Shared: reinforced across at least two independent sessions or explicitly requested as policy.

## Workflow

1. Read `AGENTS.md` first, then `AGENTS.local.md` if present.
2. Load incremental state from `workspace/context/_meta/learning-index.json` if present.
3. Process only new or modified context/prompt files since last run.
4. **Scan for repetitive patterns** that could become skills (see Pattern Recognition section).
5. Extract candidate learnings with source references (file and date).
6. Score each candidate for confidence and durability (`low`, `medium`, `high`).
7. Keep only `medium` or `high` in both dimensions.
8. Run contradiction check against existing memory bullets before persisting.
9. Update matching bullets in place when semantically equivalent.
10. Add only net-new bullets that survive inclusion bar and quality gate.
11. **Propose skill creation** for identified patterns (3+ occurrences).
12. Deduplicate aggressively to avoid instruction bloat.
13. Enforce memory budget for each managed section before writing.
14. Write updated incremental state with latest file mtimes.
15. Append a short changelog note in today's branch context file.

## Contradiction Resolution

Before writing new memory bullets:

- Search for semantically conflicting bullets in learned sections.
- If conflict exists, prefer replacing outdated guidance over adding another bullet.
- Record replacement rationale in branch context changelog.
- Never keep both sides of a contradiction in managed sections.

## Pattern Recognition for Skills

When scanning context files during learning runs, actively look for:

1. **Repetitive Task Patterns**
   - Same type of task appearing 3+ times across sessions
   - Multi-step workflows with consistent structure
   - Complex instructions that users provide repeatedly
   - Error patterns that require similar fixes

2. **Skill Creation Triggers**
   - User says "like we did before" or "same as last time"
   - Copy-pasting previous instructions with minor edits
   - Explaining a process in detail multiple times
   - Workflows that involve specific domain knowledge

3. **Skill Proposal Format**
   When a pattern is detected, create a learning event:
   ```markdown
   ### Skill Candidate: [Proposed Name]
   - Pattern: [What was repeated]
   - Frequency: [How often seen]
   - Value: [Time saved, errors prevented]
   - Proposed sections: [Key parts of the skill]
   ```

   **Concrete Example:**
   ```markdown
   ### Skill Candidate: api-error-handling
   - Pattern: Implementing error handling for external API calls with retry logic
   - Frequency: 4 times in last 3 sessions (Stripe, Twilio, Weather API, OAuth)
   - Value: ~2 hours per implementation, prevents common timeout/retry mistakes
   - Proposed sections:
     - Purpose: Standardize external API error handling
     - When to Use: Any external HTTP API integration
     - Error Taxonomy: Network vs API vs Auth errors
     - Retry Strategy: Exponential backoff with jitter
     - Circuit Breaker: When to stop retrying
     - Logging Standards: What to log, PII considerations
   - Evidence: 
     - workspace/context/feature/2024-01-15-CURRENT.md (Stripe integration)
     - workspace/context/api/2024-01-18-CURRENT.md (Twilio webhooks)
   ```

4. **Auto-Creation Threshold**
   - If pattern appears 5+ times: Strong recommendation
   - If pattern appears 3-4 times: Moderate recommendation
   - If pattern appears 2 times: Note for future consideration

## Promotion Rules

- Promote to `AGENTS.md` only if broadly reusable for this repository.
- Write to `AGENTS.local.md` if preference is personal and not for commit.
- If pattern is repeatable and multi-step, promote to `.ai-agents/skills/*.md`.
- If behavior must always apply, promote to `.ai-agents/rules/*.md`.
- If pattern involves domain-specific workflow, create new skill in `.ai-agents/skills/`.

## Decay And Review

Run periodic memory pruning to prevent stale guidance:

- Review cadence: at least monthly, or during `/compact` on long sessions.
- Demote to `AGENTS.local.md` if a shared bullet has not been reinforced recently.
- Remove bullets that are obsolete, contradictory, or tied to retired tooling.
- Keep changelog entries for major removals to preserve decision traceability.

## Learning Event Template

Use this template in branch context when logging candidate learnings:

```markdown
### Learning Event

- Mistake: {what went wrong}
- Root pattern: {abstracted failure mode}
- Generalized rule: {reusable guidance}
- Confidence: {low|medium|high}
- Durability: {low|medium|high}
- Destination: {context|AGENTS.local.md|AGENTS.md|skill|rule}
```

For skill candidates, use this additional template:

```markdown
### Skill Candidate: {proposed-skill-name}

- Pattern: {description of repeated workflow}
- Frequency: {times observed across sessions}
- Value: {estimated time savings or error prevention}
- Proposed sections:
  - Purpose
  - When to Use
  - {Domain-specific sections}
  - Common Pitfalls
- Evidence: {file references where pattern appeared}
```

## Memory Quality Gate

Score each candidate 0-2 on each dimension (max 6):

- Clarity: concrete and unambiguous wording
- Reusability: applies beyond the triggering task
- Overfit risk: low risk of encoding one-off behavior

Persist to shared memory only when score >= 4 and no contradiction is unresolved.

## Cadence Policy

For automatic or semi-automatic learning runs, use cadence gates to reduce noisy rewrites:

- Minimum completed turns since last run: default 10
- Minimum elapsed minutes since last run: default 120
- At least one tracked context file mtime advanced since last run

Trial mode defaults:

- Minimum completed turns: 3
- Minimum elapsed minutes: 15
- Trial duration: 24 hours, then fall back to default cadence

Cadence state file:

- `workspace/context/_meta/learning-cadence.json`

Suggested cadence state format:

```json
{
  "version": 1,
  "lastRunAt": "2026-02-28T00:00:00Z",
  "lastRunTurn": 42,
  "lastObservedContextMtimeMs": 1772242329000,
  "trial": {
    "enabled": false,
    "startedAt": "2026-02-27T00:00:00Z",
    "durationMinutes": 1440
  }
}
```

Environment overrides (optional):

- `CONTINUAL_LEARNING_MIN_TURNS`
- `CONTINUAL_LEARNING_MIN_MINUTES`
- `CONTINUAL_LEARNING_TRIAL_MODE`
- `CONTINUAL_LEARNING_TRIAL_MIN_TURNS`
- `CONTINUAL_LEARNING_TRIAL_MIN_MINUTES`
- `CONTINUAL_LEARNING_TRIAL_DURATION_MINUTES`

If cadence gate is not met, skip AGENTS updates and log a short "deferred by cadence" note in branch context.

## Evaluation Loop

Before broad promotion to shared memory, validate with at least 3 real scenarios:

1. Baseline: observe behavior before memory update
2. Apply: run with updated memory
3. Compare: check if target mistake frequency decreases without regressions

Keep evaluation notes concise in branch context and promote only if outcomes improve.

## Incremental State Format

```json
{
  "version": 1,
  "files": {
    "workspace/context/ai/2026-02-27-CURRENT.md": {
      "mtimeMs": 1770000000000,
      "lastProcessedAt": "2026-02-27T12:00:00.000Z"
    }
  }
}
```

## Output Contract

When reporting results, include:

- bullets added
- bullets updated
- bullets removed
- files touched
- any caveats or low-confidence exclusions
