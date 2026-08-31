# Manifest: Agent Context Audit

> Enumerates every component loaded into the current AI coding harness -- skills, rules,
> commands, agents, plugins, MCP servers, and instruction files -- then audits the
> inventory for bloat, verbosity, redundancy, staleness, and usefulness.
> Use when the user says "audit my agent setup", "manifest", "what's loaded",
> "check for redundant skills", or when sessions feel bloated or instructions conflict.
> Strictly read-only: it proposes changes, never applies them.

---

## When to Use

- Periodically (e.g., monthly or quarterly), or after adding several skills, rules, or MCP servers
- Before adding a new skill -- check for overlap first
- When a harness feels verbose, slow, or the model follows conflicting instructions
- When preparing to prune the agent stack

---

## Cost Model -- audit in this order

How each component type is loaded determines its cost:

| Load mode | Cost | Typical components |
|-----------|------|--------------------|
| Always-on | Full text in EVERY session's context | AGENTS.md, CLAUDE.md, `instructions[]` files, rules |
| Metadata-on | Name + description always visible; body loads only on trigger | Skills |
| On-invoke | Listed in the UI; body loads when invoked | Commands |
| Per-request | Tool schemas sent with every LLM request | MCP servers |
| Runtime | Code runs on events; negligible token cost | Plugins |

- Rough token estimate: `bytes / 4`. A 250-line markdown file is roughly 2-3k tokens.
- Ten always-on files at ~3k tokens each tax every session with ~30k tokens before it starts.
- MCP servers cost even when unused: each enabled server's tool schemas ride along on every request.
- Audit priority follows cost: always-on items first, MCP servers second, skills third, commands last.

---

## Phase 1: Inventory (mechanical)

Preferred: run the companion scan script (read-only, TSV output):

```bash
bash "${DOTFILES:-$HOME/code/dotfiles}/.scripts/agent_manifest.sh"
# options: --home DIR, --project DIR
```

Columns: `category, name, harness, path, resolved, lines, est_tokens, last_commit, flags`.
Lines starting with `#` are metadata, notes (stderr), or the summary block (stdout).
Flags include: `orphan-symlink`, `missing-skmd`, `no-frontmatter`, `no-description`,
`name-mismatch`, `stale>6mo`, `untracked`, `unresolved`, `disabled`, `declared`, `jsonc-comments`.

If no script is available, enumerate manually from the discovery map:

| Component | Locations (check all that exist) |
|-----------|----------------------------------|
| Instruction files | project `AGENTS.md`, `AGENTS.local.md`, `CLAUDE.md`; `~/.claude/CLAUDE.md`; `~/.config/opencode/AGENTS.md`; `instructions[]` in `opencode.json` (global + project) |
| Skills | `~/.config/opencode/skills/*/SKILL.md`, `.opencode/skills/*/`, `~/.claude/skills/*/`, `.claude/skills/*/`, `~/.agents/skills/*/`, `.agents/skills/*/`, extra dirs from `skills.paths` |
| Rules | `.ai-agents/rules/*/SKILL.md`, `.opencode/rules/*.md`, `~/.config/opencode/rules/*.md`, `.claude/rules/*.md` |
| Commands | `~/.config/opencode/commands/*.md`, `.opencode/commands/*.md`, `~/.claude/commands/*.md`, `.claude/commands/*.md`, `command:{}` keys in opencode.json |
| Agents | `~/.config/opencode/agent(s)/*.md`, `.opencode/agent(s)/*.md`, `~/.claude/agents/*.md`, `agent:{}` keys in opencode.json |
| Plugins | `~/.config/opencode/plugin(s)/*.[tj]s`, `.opencode/plugin(s)/*.[tj]s`, `~/.claude/plugins/`, `plugin:[]` in opencode.json |
| MCP servers | `mcp:{}` in opencode.json (global + project); `~/.claude.json` (`mcpServers` + per-project); project `.mcp.json`; Claude Desktop `claude_desktop_config.json`; `~/.cursor/mcp.json`; `~/.gemini/settings.json` |

Built-ins (baseline, not findings): opencode agents `build/plan/general/explore` plus hidden
`compaction/title/summary`; Claude Code Task subagents.

Honesty rules:
- This reconstructs state from config files -- runtime introspection is not available.
- Mark `Unknown` for `OPENCODE_CONFIG` env overrides, remote `.well-known` config, `skills.urls`, and anything the scan could not resolve.
- If `jq` is missing, config-derived categories (instructions, mcp, declared plugins/agents/commands) are skipped -- parse those configs manually.
- Never guess counts or sizes; every report row comes from the scan output or a direct file read.

---

## Phase 2: Dedupe & Cross-Reference

Before calling anything redundant, separate intentional structure from true duplication:

- **Same resolved path in multiple harness dirs** = intentional sync (e.g., `sync-skills`
  symlinks `.ai-agents/` content into `~/.claude/skills/`). Not a finding. Instead verify
  sync health: orphan symlinks, source missing, or installed entries with no source.
- **Thin command wrappers** (body says "read SKILL.md X and follow it") = intentional
  bridges, near-zero cost. A command that duplicates skill content instead of referencing
  it IS a finding.
- **Skills with `no-frontmatter`/`no-description`** whose only load path is skill-dir
  discovery are invisible in opencode (it filters skills without a description). If the
  same skill also sits in `instructions[]`, the skill-dir copy is dead weight; if neither,
  the skill is unreachable.
- Cross-reference every skill against: commands, AGENTS.md mentions, `instructions[]`,
  and session context files (`workspace/context/`). Referenced nowhere = orphan candidate.

---

## Phase 3: Audit (judgment)

Rate each item `Keep` / `Watch` / `Act` against these dimensions (thresholds are rough
heuristics, not laws -- adjust to the user's tolerance):

1. **Bloat & verbosity** -- always-on item over ~2k tokens: justify or trim. Skill over
   ~400 lines: split or compress. Total always-on over ~20k tokens: prune before adding anything new.
2. **Redundancy** -- two skills covering the same topic (merge candidates); guidance
   duplicated between AGENTS.md and a skill; near-identical command wrappers.
3. **Staleness** -- last commit over 6 months (`stale>6mo`); "Researched YYYY-MM-DD" or
   doc-validity dates past due; TODO/FIXME markers; spot-check 2-3 referenced paths still exist.
4. **Usefulness** -- referenced anywhere? trigger description states WHEN to use? empty
   dirs (e.g., both `agent/` and `agents/` existing but empty), commented-out config
   entries, disabled MCP servers, unreferenced files sitting in config directories.
5. **Correctness** -- folder name matches skill name; frontmatter present with a
   one-sentence description containing trigger keywords; broken symlinks;
   `instructions[]` entries that resolve to nothing.

---

## Phase 4: Report

Show the report in chat AND save a snapshot so audits can be diffed over time:
`workspace/context/_meta/manifest-latest.md` plus a dated copy `manifest-YYYY-MM-DD.md`
(create `_meta/` if missing; if the project has no `workspace/context/` structure, chat-only).

Template:

```markdown
# Agent Manifest Audit -- YYYY-MM-DD
Harness: <which> | Project: <path> | Scan: <script|manual>

## Totals
| Category | Count | Est. tokens | Load mode |
(call out the always-on subtotal explicitly -- it is the headline number)

## Inventory
(one compact table per category: name, source, lines/tokens, last commit, flags)

## Findings
(numbered; each with severity high/med/low, evidence (path + metric), and why it matters)

## Recommendations
(concrete actions with exact paths/keys -- e.g., "remove X from instructions[] in
opencode.json", "merge skill A into skill B", "delete orphan ~/.claude/skills/foo" --
each with an impact estimate)

## Since last audit
(only if a previous snapshot exists: added/removed/changed rows, token delta)
```

Rules:
- Every finding cites evidence (path, number, or config key). No vibes.
- Recommendations are proposals -- never apply changes during an audit run. Ask which to execute.
- If the user passes a focus (e.g., "skills only", "mcp", "redundancy"), narrow the audit but keep the totals table complete.

---

## Anti-Patterns

| Don't | Do Instead |
|-------|------------|
| Delete or edit anything during the audit | Propose exact changes; wait for approval |
| Count sync symlinks as duplication | Verify sync health, then move on |
| Count thin command wrappers as duplication | Flag only content-duplicating commands |
| Report file counts without token estimates | bytes/4 per item, subtotals per load mode |
| Ignore MCP tool-schema cost | Each enabled server taxes every request |
| Audit only the source repo (`.ai-agents/`) | Scan installed locations too -- drift is a finding |
| Add this skill to `instructions[]` | It is on-demand by design; keep it metadata-on |

---

## Integration Guide (Per-Tool)

**opencode**: invoke via the `/manifest` command (`.config/opencode/commands/manifest.md`).
Restart opencode after applying any config changes the audit recommends.
**Claude Code**: skill is symlinked into `~/.claude/skills/manifest` via `sync-skills`;
MCP servers live in `~/.claude.json` and project `.mcp.json`.
**Any agent**: run the scan script, paste the TSV output, and follow Phases 2-4.
