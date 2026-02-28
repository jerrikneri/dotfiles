https://opencode.ai/docs/permissions/#_top

Available Permissions

OpenCode permissions are keyed by tool name, plus a couple of safety guards:

    read — reading a file (matches the file path)
    edit — all file modifications (covers edit, write, patch, multiedit)
    glob — file globbing (matches the glob pattern)
    grep — content search (matches the regex pattern)
    list — listing files in a directory (matches the directory path)
    bash — running shell commands (matches parsed commands like git status --porcelain)
    task — launching subagents (matches the subagent type)
    skill — loading a skill (matches the skill name)
    lsp — running LSP queries (currently non-granular)
    todoread, todowrite — reading/updating the todo list
    webfetch — fetching a URL (matches the URL)
    websearch, codesearch — web/code search (matches the query)
    external_directory — triggered when a tool touches paths outside the project working directory
    doom_loop — triggered when the same tool call repeats 3 times with identical input

Canonical policy source in this repo: `.ai-agents/rules/permissions.md`.
