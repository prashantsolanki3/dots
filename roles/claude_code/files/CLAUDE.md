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

## Codebase knowledge graph (graphify)

- The `graphify` skill (`~/.claude/skills/graphify/SKILL.md`) builds and queries a knowledge graph of a codebase. `/graphify` triggers it.
- If a repo has a graph (`graphify-out/graph.json` or `GRAPH_REPORT.md`, in-repo or under `~/.graphify/projects/<repo>/`), query it before grepping or reading files broadly: `graphify query "<question>" --graph <path>`.
- Also useful: `graphify explain "<node>"`, `graphify path "A" "B"`, `graphify affected "X"`, `graphify god-nodes`.
- Regenerate after structural changes: `graphify update <path>` (AST only, no LLM) or `graphify extract <path> --out <dir>` for a full rebuild.
- Never write `graphify-out/` into a repo with a clean-tree contract — use `--out` to park it outside, or gitignore it.
- Subagents inherit this rule: prefer a graph query over a broad file sweep.

## Delegation-first (agent roster)

- Classify every request against the roster before working on it inline; delegate to the owning subagent.
- `gitops-operator` — repo edits, manifests, terraform, ansible, PRs. Worktree-isolated and PR-only.
- `cluster-medic` — k3s diagnosis, read-only first; bounded fixes only with per-item authorization.
- `secret-wrangler` — anything touching a credential: SSM, External Secrets, API keys, rotations.
- `access-navigator` — browser work on homelab apps. `media-librarian` — arr/deluge/plex/tdarr.
- `homelab-architect` — design, trade-offs, cost tables; read-only, never implements.
- Skills: `/revenant-wave` orchestrates a batch, `/pr-land` merges and verifies, `/live-truth` checks a doc claim before you build on it, `/pending-on-human` regenerates the user's own task list, `/lesson-harvest` runs after any surprising run.
- Ideate only when no agent matches. A roster miss triggers `/lesson-harvest` to evaluate creating a new asset.
- Every agent file ends with an append-only `## Lessons` section. Before finishing any run where reality contradicted the instructions, append a dated entry there — never rewrite or delete existing ones.
