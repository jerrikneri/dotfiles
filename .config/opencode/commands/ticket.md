---
description: "Capture deterministic ticket details into branch context"
---

Capture ticket details into a deterministic branch-scoped markdown file.

Steps:
1. Detect current branch: !`git branch --show-current`
2. Sanitize branch name for filesystem (replace `/` with `-`)
3. Parse input from `$ARGUMENTS`.
4. If the text contains `[ticket]`, strip only that marker from saved content.
5. Extract `ticket_name` and optional `branch_name` from input.
   - Accept explicit labels like `ticket name: ...` and `branch name: ...`.
   - If a Jira-style ID exists (regex `[A-Z][A-Z0-9]+-[0-9]+`) and no explicit `ticket_name`, use that ID as `ticket_name`.
6. If `ticket_name` is missing, ask exactly one follow-up question for `ticket_name`, then continue.
7. Resolve `branch_name` using this priority:
   - Explicit `branch_name` from input
   - Derived from `ticket_name` as slug: lowercase, spaces/underscores to `-`, remove non `[a-z0-9-]`, collapse repeated `-`, trim edge `-`
8. Ensure git branch exists and switch to it:
   - If local branch `{branch_name}` exists, check it out.
   - Otherwise create and check out with `git checkout -b "{branch_name}"`.
9. Ensure `workspace/context/{branch_name}/` exists.
10. If ticket details body is empty after cleanup, ask exactly one follow-up for ticket details, then continue.
11. Write `workspace/context/{branch_name}/ticket-details.md` (overwrite for deterministic output).

File format (exact sections):

# Ticket Details

- ticket_name: `<resolved ticket_name>`
- branch_name: `<resolved branch_name>`
- captured_at_local: `YYYY-MM-DD HH:MM`
- captured_at_iso: `YYYY-MM-DDTHH:MM:SSZ`
- source: `/ticket`

## Raw Input

`<original $ARGUMENTS>`

## Details

<cleaned details body>

Ticket content to capture:
$ARGUMENTS
