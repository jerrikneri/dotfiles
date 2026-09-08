# Commit: Git History as the Record

> Always-on rule: apply to EVERY commit. No trigger needed.
> Commit messages carry the detail you'd normally put in a spec, notes, or summary markdown file.
> The commit body IS the record: what was done, why, the key decisions, and how it was verified.
> Works with any AI coding agent. Portable: git is the only dependency.
> Rationale: markdown artifacts rot, get lost, or live in gitignored workspace dirs. The commit log is durable, timestamped, ordered, and always one `git log` away.

---

## When to Use

- Every commit where the change matters beyond the raw diff
- Instead of creating a NEW markdown file just to record what a change did
- Alongside existing artifacts (specs, ADRs, session notes): the commit message summarizes and stands alone; the artifact carries the rest

## Core Principle

**The diff shows HOW. The commit message records WHAT and WHY.**

Anyone (human or agent) should be able to run `git show <sha>` six months later and understand the change without asking questions or hunting for a doc that may not exist.

## Message Structure

```
<subject: 50-72 chars, what changed -- match the repo's existing subject style>

What/Why:
<motivation, problem, or trigger for this change -- 1-3 sentences>

Implementation:
- <key decision + rationale>
- <key decision + rationale>
<Only non-obvious choices. Do not narrate the diff.>

Findings:
- <gotchas, workarounds, non-obvious behavior discovered>
<omit section if nothing notable>

Verification:
<tests run, commands executed, results -- or "not verified" if so>

Follow-ups:
- <known limitations, deferred work>
<omit section if none>
```

- Write the body while session context is fresh -- local context files are often gitignored, so the commit message is the only committed record
- If a spec/ADR/ticket file exists, summarize its key points in the body anyway; the message must stand alone
- Subject lines: follow the repo's convention (check `git log --oneline -10` first)

## Depth by Change Size

| Size | Example | Body |
|------|---------|------|
| Trivial | typo, formatting, rename | Subject only, or one-line body |
| Small | single fix, config tweak | What/Why + Verification |
| Medium | feature, refactor, new script | Full structure, all applicable sections |
| Large | multi-day work | Should be multiple commits; each carries its own record |

## Writing Multi-Line Messages

Always use the heredoc pattern -- it preserves blank lines and formatting portably:

```bash
git commit -m "$(cat <<'EOF'
subject line

What/Why:
...
EOF
)"
```

## The Log as Resume Context

The flip side of this rule: when starting a session or resuming work, read the log before asking for or writing context files.

```bash
git log --oneline -15          # what happened recently
git show <sha>                 # full record for a relevant commit
git log -- <path>              # history of a specific file/area
```

A well-kept log replaces most "what did we do last session" documentation.

## Rules

1. One logical change per commit -- mixed commits make the record unusable for both reading and reverting
2. Never commit secrets -- commit messages are permanent and travel with every clone
3. No ephemeral content (session TODOs, "ask user about X", agent-internal notes) -- the message must age well
4. Never fabricate verification results -- if untested, say "not verified"
5. Do not create a new markdown file whose only purpose is recording what a commit did -- put it in the commit

## Anti-Patterns

| Don't | Do Instead |
|-------|------------|
| `"fix stuff"` / `"update"` subjects | Subject says what changed |
| Body narrating the diff line-by-line | Record decisions and rationale; the diff already exists |
| Creating `NOTES.md` / `CHANGES-2026-09.md` to summarize work | Put the summary in the commit body |
| Dumping session transcript into the message | Distill to decisions, findings, verification |
| One giant "week of work" commit | Separate commits, each with its own record |

## Example

Bad:

```
add manifest script
```

Good:

```
add manifest scanner script

What/Why:
Agents were loading skills/rules from multiple dirs with no way to audit
what is actually in context. Need a single inventory command.

Implementation:
- Scans .ai-agents/skills and rules dirs, plus agent config files, so the
  snapshot reflects real loaded state rather than a hand-maintained list
- Writes snapshot to workspace/context/_meta/manifest-latest.md (gitignored)
  to keep committed tree clean

Findings:
- opencode loads rules via opencode.json instructions array, not skill dirs,
  so scanner has a separate code path for it

Verification:
- Ran scanner; snapshot listed 9 skills, 2 rules -- matches directory contents

Follow-ups:
- Consider flagging skills not referenced by any agent config
```
