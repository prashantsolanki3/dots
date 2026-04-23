# Global Claude Code Rules

- Prefer CLI tools, scripts, and approved MCP servers over manual UI work.
- Do not commit plaintext secrets — use env files (.gitignore'd) or system keychain.
- Read the project's CLAUDE.md before starting any task.

## Agent Teams

Agent teams are enabled. Use `claude --agent orchestrator` to start a continuous development session that picks up tasks from the project's GitHub Project board.

## Best Practices

- Use plan mode (`/plan`) before implementing complex features
- Use `/verify` to run the project's verification suite
- Use `/review` to self-review changes before creating a PR
- One concern per commit, format: `type(scope): description`
- Always read AGENTS.md and AI_INSTRUCTIONS.md in the project repo first
- Prefer worktree isolation for implementation work

## Persistent knowledge (LLM-wiki)

- If a project has `docs/CLAUDE.md`, it is using the LLM-maintained wiki pattern. Read that schema first before writing to `docs/`.
- Use `/wiki-ingest <path-or-url>` to file sources, `/wiki-query <question>` to search+synthesise, `/wiki-lint` to health-check.
- The `wiki-keeper` subagent is the only agent that writes to the living zone. Other agents are read-only against the wiki.
- Local search via `qmd` (npm `@tobilu/qmd`; MCP auto-registered). One-time per project: `qmd collection add docs/ && qmd embed`.

## Effort level

`effortLevel` is pinned to `max` in `~/.claude/settings.json` and self-heals
on every session start via `~/.claude/hooks/preserve-effort-max.sh`. Do not
override with `--effort low|medium|high` unless you genuinely need to throttle
a one-off run.
