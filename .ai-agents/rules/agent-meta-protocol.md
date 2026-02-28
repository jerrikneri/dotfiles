# Agent Meta-Protocol

> Core behavioral directives for AI coding agents working in this dotfiles repo.
> Tool-agnostic: works with any AI coding tool that loads this file.
> These are always-on behaviors, not triggered by commands.

---

## 1. Document Findings (Automatic -- Do Not Wait to Be Asked)

Documentation is not optional. After completing work that creates, modifies, or deletes files, update the session context file (`workspace/context/{branch}/YYYY-MM-DD-CURRENT.md`) as part of completing the task -- not as a separate step the user must request.

- **Where**: `workspace/context/{branch}/YYYY-MM-DD-CURRENT.md` per the session management protocol
- **What to capture**: What was built/changed, key decisions and why, config changes, non-obvious findings
- **Format**: Succinct tables and bullet points. "What changed" and "why" -- not "how"
- **Scope escalation**: If a finding applies broadly (not just the current branch), suggest adding it to `AGENTS.md` or the relevant skill/instruction file
- **When NOT to document**: Trivial single-line fixes, read-only exploration with no conclusions, things fully captured by git diff

## 2. Self-Improve Configuration

After completing a task, reflect on friction points:

- Were you repeatedly blocked by permission prompts for safe operations? Suggest updating `opencode.json` permissions (e.g., moving safe commands from `ask` to `allow`)
- Did you need a tool or command that doesn't exist yet? Suggest creating a new slash command or skill
- Did you repeat a multi-step workflow manually? Suggest codifying it as a command or script
- Is there a pattern you followed that should be a skill file?

When suggesting changes:
- Be specific: cite the exact config key and proposed value
- Explain the tradeoff: what convenience is gained, what safety is relaxed
- Never auto-apply config changes -- always propose and let the user decide

## 3. Fact-Check Yourself

Before presenting conclusions or making changes based on assumptions:

- **Verify claims**: If you state something about how a tool works, a config option, or an API behavior, check the actual source (docs, config files, code) rather than relying on training data
- **Test assumptions**: If you assume a file exists, a command works a certain way, or a config option is supported -- verify before acting
- **Flag uncertainty**: If you're not sure about something, say so explicitly rather than presenting it as fact
- **Check recency**: For tool documentation and APIs, prefer reading actual config/source files over training knowledge, which may be outdated

## 4. Get Second Opinion

For non-trivial changes, apply the hontoni framework:

- After completing a fix or feature, run a self-critique using the protocol in `.ai-agents/skills/hontoni.md`
- Score at minimum: Correctness (root cause vs symptom), Completeness (all paths), and Regression Risk (what could break)
- If composite score is below 60, flag it to the user before considering the work done
- For high-risk changes (data handling, auth, destructive operations), always self-critique before presenting as complete
