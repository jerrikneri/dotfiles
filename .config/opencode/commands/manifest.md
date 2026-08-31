---
description: "Audit all loaded agent components (skills, rules, commands, plugins, MCP) for bloat, redundancy, staleness"
---

Run the manifest audit protocol on this machine's agent setup.

Steps:
1. Read the full protocol from `.ai-agents/skills/manifest/SKILL.md` (fallback: `~/code/dotfiles/.ai-agents/skills/manifest/SKILL.md`)
2. Run the scan script: `bash .scripts/agent_manifest.sh` (fallback: `bash ~/code/dotfiles/.scripts/agent_manifest.sh`); capture its TSV output and stderr notes
3. Follow the protocol phases: Inventory -> Dedupe & Cross-Reference -> Audit -> Report
4. Show the full report in chat (totals with the always-on token subtotal, findings with evidence, recommendations with exact paths/config keys)
5. Save the snapshot to `workspace/context/_meta/manifest-latest.md` and a dated copy `workspace/context/_meta/manifest-YYYY-MM-DD.md` (today's date; create `_meta/` if missing; skip saving if the project has no `workspace/context/` structure)
6. If a previous `manifest-latest.md` existed, include a "Since last audit" delta section
7. Do not apply any recommended changes -- list them and ask which to execute

Focus (optional): $ARGUMENTS (e.g., "skills only", "mcp", "redundancy", "always-on cost")
