---
description: "Check amosblomqvist/learn for upstream changes to the really-teach-me skill; classify and propose porting anything new"
---

Keep the really-teach-me skill current with its upstream source: https://github.com/amosblomqvist/learn

State file: `workspace/context/_meta/upstream-really-teach-me.json` (or `$DOTFILES/...` when run outside the dotfiles repo) — repo, treeSha, per-file blob SHAs, lastCheckedAt.
Baseline snapshot: `workspace/context/_meta/upstream/learn/` — verbatim copies of upstream files at last check.

Steps:

1. Fetch the upstream tree: `https://api.github.com/repos/amosblomqvist/learn/git/trees/main?recursive=1` (webfetch or `curl -s`). It returns a JSON tree with a top-level `sha` (the tree SHA) and per-file blob SHAs.

2. **First run** (state file missing): record the baseline. Fetch all text files below into the snapshot dir, preserving paths (skip `package-lock.json`, `.gitignore`, `assets/`). Write the state file with the treeSha, blob SHAs, and `lastCheckedAt`/`lastPortedAt` timestamps. Report "baseline recorded" and stop.

3. Compare the fetched treeSha + blob SHAs against the state file. Identical → update `lastCheckedAt`, report "up to date", stop.

4. If anything changed: for each changed/new file, fetch `https://raw.githubusercontent.com/amosblomqvist/learn/main/<path>` and diff against the snapshot copy. Classify each change:
   - **Already ported** — our SKILL.md has the equivalent
   - **Portable** — propose the specific edit to our adapted skill (it intentionally diverges: opencode tool mapping, learner profile, codebase mode)
   - **Pi-specific / not applicable** — extensions, UI popups, Obsidian-only machinery

5. Present the porting proposal (per change: what it is, the classification, the proposed diff). Wait for my approval.

6. On approval: apply edits to `.ai-agents/skills/really-teach-me/SKILL.md` (and commands if affected), update the snapshot files + state file (`lastPortedAt`), update the pinned tree SHA + checked date in the skill's header block, and note the port in the session context file. Commit only if I ask.

Tracked files: `README.md`, `skills/teach/SKILL.md`, `skills/visualize/SKILL.md`, `agents/*.md`, `extensions/*.ts`, `extensions/visual-tools/**` (text files only).

Notes:
- Unauthenticated GitHub API rate limit is ~60 requests/hour — one tree request plus changed-file fetches is well within it.
- Blob SHA comparison is exact: any content change in any file is detected without cloning.
- If the fetch fails (network, rate limit), report the failure and leave state untouched — never record a check you didn't perform.
