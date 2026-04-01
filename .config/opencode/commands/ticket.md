---
description: "Capture ticket note with inferred ticket ID"
---

Capture the provided ticket note into a branch-scoped markdown log so it can be reused later for Jira context.

Steps:
1. Detect current branch: !`git branch --show-current`
2. Sanitize branch name for filesystem (replace `/` with `-`)
3. Ensure `workspace/context/{branch}/` exists
4. Resolve a ticket ID using this priority:
   - First, parse `$ARGUMENTS` for a Jira-style ID (example regex: `[A-Z][A-Z0-9]+-[0-9]+`)
   - If not found, parse the current branch name for a Jira-style ID
   - If still not found, ask a follow-up question asking only for the ticket ID, then continue
5. If the incoming text contains `[ticket]`, strip only that marker from the saved body
6. Append an entry to `workspace/context/{branch}/tickets.md`
7. Save timestamp + ticket ID + cleaned content as a new markdown entry

Entry format:

## YYYY-MM-DD HH:MM

- ticket: `<resolved ticket id>`
- raw: `$ARGUMENTS`
- body: `<cleaned message body>`

Ticket content to capture:
$ARGUMENTS
