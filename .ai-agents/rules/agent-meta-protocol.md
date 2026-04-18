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

## 3. Recognize Repetition and Suggest Skills

Watch for repetitive patterns during the session and proactively suggest creating skills:

### Pattern Recognition Triggers
- User asks for the same type of task more than twice in a session
- User provides similar instructions across multiple sessions (check context files)
- A multi-step workflow is repeated with minor variations
- User describes a process that could be templated
- Complex instructions that would benefit from structured guidance

### When to Suggest a Skill
Proactively say: **"I notice this is a repeating pattern. Should we create a skill for this?"** when:

- The task has clear steps that could be codified
- The pattern is likely to be useful beyond the current project
- The workflow involves specific decision points or quality checks
- There's domain-specific knowledge that should be preserved

### What Makes a Good Skill Candidate
- **Repeatability**: Will this be done again in similar contexts?
- **Complexity**: Does it have enough steps to benefit from documentation?
- **Variability**: Can it be parameterized for different scenarios?
- **Value**: Will it save time or reduce errors in the future?

### How to Suggest
When suggesting a skill, provide:
1. A brief description of the pattern noticed
2. A proposed skill name (e.g., "api-integration-testing", "database-migration-safety")
3. Key sections the skill would include
4. Estimated time savings for future use

Example: *"I've noticed we've now done three API integrations with similar patterns around error handling and retry logic. Should we create an 'api-integration-patterns' skill that captures these best practices? It would include sections on error handling, retry strategies, and testing approaches."*

## 4. Fact-Check Yourself

Before presenting conclusions or making changes based on assumptions:

- **Verify claims**: If you state something about how a tool works, a config option, or an API behavior, check the actual source (docs, config files, code) rather than relying on training data
- **Test assumptions**: If you assume a file exists, a command works a certain way, or a config option is supported -- verify before acting
- **Flag uncertainty**: If you're not sure about something, say so explicitly rather than presenting it as fact
- **Check recency**: For tool documentation and APIs, prefer reading actual config/source files over training knowledge, which may be outdated

### Evidence Discipline (Mandatory)

Before sending user-facing conclusions with factual claims:

1. Tag key claims as `Observed`, `Inferred`, or `Speculative`.
2. Tie each key claim to an evidence source category (tool output, file path, user-provided data, or external documentation).
3. If no evidence exists, do not assert the claim as fact; state `Unknown` or `Unverified` and propose the fastest verification step.
4. Never fabricate statistics, measurements, timings, or command/test outputs.

## 5. Get Second Opinion

For non-trivial changes, apply the hontoni framework:

- After completing a fix or feature, run a self-critique using the protocol in `.ai-agents/skills/hontoni.md`
- Score at minimum: Correctness (root cause vs symptom), Completeness (all paths), and Regression Risk (what could break)
- If composite score is below 60, flag it to the user before considering the work done
- For high-risk changes (data handling, auth, destructive operations), always self-critique before presenting as complete

### Automatic Review Triggers

**Always run hontoni review automatically when:**
- Creating or modifying skills in `.ai-agents/skills/`
- Updating rules in `.ai-agents/rules/`
- Making changes to AGENTS.md or other instruction files
- Implementing complex multi-file features
- Fixing bugs that affect multiple code paths

**Include in response without being asked:**
- Append a brief hontoni score table after completing qualifying work
- If score is below 70, prominently highlight weaknesses
- For scores 60-69, ask: "Should I address these weaknesses before proceeding?"
- For scores below 60, state: "This needs improvement. Here's what I should fix..."

**Example auto-review format:**
```
[Work completed]

Auto-Review: Hontoni Score
- Correctness: 85 (addresses root cause)
- Completeness: 70 (missed edge case X)
- Test Evidence: 90 (comprehensive examples)
Composite: 78.3 ✓
```

## 6. Command Safety And Change Approval

Use this default safety policy unless a session/user instruction explicitly overrides it:

- Ask before writing or modifying non-temporary files
- Ask before state-changing commands (install/uninstall, git commit, migrations, service restarts)
- Ask before deleting or moving files, or running commands with `sudo`
- Ask before making configuration changes or installing dependencies
- Group related changes into a single approval request when possible
- Include brief rollback guidance when proposing state-changing changes

Safe-by-default without extra approval:

- Read-only inspection and status checks (`ls`, `read`, `grep`, `glob`, `git status`, `--help`)
- Non-mutating validation/test commands

## 7. Automatic Test Execution

After completing work that modifies code files, automatically run relevant tests before presenting the work as complete.

### When to Run Tests Automatically

**Always run tests when:**
- Completing bug fixes (run test suite for affected components)
- Adding new features (run full test suite + new tests)
- Modifying existing functionality (run tests for changed files)
- Refactoring code (run tests to ensure no regressions)
- Before marking any code-modifying task as complete

**Skip test execution only when:**
- Changes are purely documentation (README, comments)
- Changes are configuration-only (no code logic)
- Working in exploration/investigation mode
- User explicitly says "skip tests" or "I'll run tests later"

### Test Execution Protocol

1. **Identify test scope**:
   - For focused changes: run tests for modified files/modules
   - For cross-cutting changes: run broader test suite
   - For bug fixes: include tests that reproduce the original issue

2. **Run tests with appropriate commands**:
   - Check for test scripts in package.json, Makefile, etc.
   - Use project-specific test runners (pytest, jest, rspec, etc.)
   - Capture both stdout and stderr

3. **Analyze results**:
   - If all pass: proceed with completion summary
   - If failures: fix issues before considering work complete
   - If flaky: re-run to confirm (note flakiness in documentation)

4. **Fix any failures**:
   - Address test failures immediately
   - Update tests if the change legitimately alters expected behavior
   - Never present work as complete with failing tests

5. **Document results**:
   - Include test summary in completion response
   - Note any significant changes to test coverage
   - Document any test modifications made

### Completion Format with Tests

When presenting completed work, include test status:

```
✓ Implemented [feature/fix description]
✓ Tests: 42 passed, 0 failed
✓ Coverage: maintained at 89%
✓ All changes verified by automated tests
```

For failures that were fixed:

```
✓ Implemented [feature/fix description]
✓ Fixed 3 failing tests affected by changes
✓ Tests: 42 passed, 0 failed (after fixes)
✓ Updated test expectations for new behavior
```

### Integration with Hontoni Review

- Test execution happens BEFORE the hontoni self-critique
- Test results inform the "Test Evidence" dimension score
- Failing tests automatically cap the Test Evidence score at 50
- Fixed test failures should be noted in the review

### Common Test Commands Reference

Detect and use the appropriate test command for the project:

- **JavaScript/TypeScript**: `npm test`, `yarn test`, `pnpm test`
- **Python**: `pytest`, `python -m pytest`, `python -m unittest`
- **Ruby**: `rspec`, `rake test`, `bundle exec rspec`
- **Go**: `go test ./...`, `go test -v ./...`
- **Rust**: `cargo test`
- **Shell**: `shellcheck *.sh`, `bats test/`
- **Make**: `make test`, `make check`

If no standard test command is found, check for:
- `test/`, `tests/`, `spec/`, `__tests__/` directories
- Test files matching `*_test.*`, `*_spec.*`, `test_*.*`
- CI configuration files (.github/workflows, .gitlab-ci.yml)

### Exceptions and Edge Cases

**When tests are slow**: Run a focused subset first, note if full suite should be run later
**When tests require services**: Document if tests need database, Redis, etc.
**When adding tests to untested code**: Note the improvement in test coverage
**When tests don't exist**: Flag this as a risk in the hontoni review
