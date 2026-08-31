# Tasks -- branch: {branch}

> Generic task checklist template. Instantiate as `workspace/context/{branch}/tasks.md`
> (per the session-management rule) -- copy, then replace `{placeholders}` and delete
> unused sections. Keep this file untouched; it is the committed source of truth.
> Task-line pattern: exact target (file:line or config key) + a `Done when` completion
> criterion, so any session can verify progress without re-deriving context.

## Active Tasks ({YYYY-MM-DD})

Source: {one line -- where this list came from: audit, ticket, incident, planning session}.
Full context/evidence: {relative link from the instantiated file, e.g. `../_meta/<report>.md` or `ticket-details.md` -- future sessions should read this first}.

### {Group 1 -- short purpose, e.g. "Quick wins"}

- [ ] {optional ID:} {action} at `{exact file:line or config key}`. Done when {verifiable completion criterion}.
- [ ] {optional ID:} {action}. Done when {verifiable completion criterion}.

### {Group 2 -- e.g. "Needs decision first"}

- [ ] {optional ID:} (needs decision first): {question + options + where the decision gets recorded}.

## Command Sync

[ ] `/resume`: confirm current file + last session file were loaded and summarized.
[ ] `/log`: confirm prompt notes path for this branch/date (`workspace/context/{branch}/prompts/YYYY-MM-DD.md`).
[ ] `/compact`: confirm end-of-session dump and archive plan.
[ ] `/learn`: confirm cadence and learning index expectations before running full sync.
[ ] `/learn-cadence`: confirm gate evaluation inputs and outcome are captured.
[ ] `/learn-from-mistake`: confirm incident note and generalized rule destination are captured.

## Done

[x] {YYYY-MM-DD}: {completed item} -- move finished items here with date suffixes for quick scan.
