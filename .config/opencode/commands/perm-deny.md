---
description: "Persistently deny a granular permission rule"
---

Add a permanent OpenCode permission rule with action `deny`.

Usage:
- `/perm-deny <tool> <pattern>`
- `/perm-deny bash "rm *"`

Input:
$ARGUMENTS

Requirements:
1. Parse input as `<tool> <pattern>`. If tool is missing, assume `bash`.
2. Update `.config/opencode/opencode.json` (fallback: `~/.config/opencode/opencode.json` when the repo file is absent).
3. In JSON:
   - Ensure `permission` exists.
   - Upsert rule so `<tool>` includes `<pattern>: "deny"`.
   - If `permission.<tool>` is a string, convert it to an object using that string as `"*"`, then add the new pattern.
   - Keep existing rules intact.
4. Update `.ai-agents/rules/permissions.md` by upserting a row in `Persistent Permission Overrides (Managed by /perm-*)`:
   - `| <tool> | <pattern> | deny |`
5. Avoid duplicate entries in both files.
6. Return what changed and the exact rule added.
